#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <sys/types.h>
#include <sys/time.h>
#include <sys/ioctl.h>
#include <net/bpf.h>
#include <sys/socket.h>
#include <net/if.h>
#include <fcntl.h>
#include <errno.h>
#include <err.h>
#include <unistd.h>
#include <signal.h>

extern char *optarg;
extern int optind;

void cancel_handler(int arg);
char *if_type();
void usage();

int bpf_fd;
char filter_device[13];
struct timeval timeout_val;
struct bpf_stat stat;
char *spy_dev;

int main(int argc, char **argv)
{
    struct ifreq req;
    u_int type;
    u_int packet_len;
    unsigned char *buffer;
    struct bpf_hdr *hdr;

    int i;
    char ch;
    int timeout;
    int buffered;

    spy_dev = NULL;
    bpf_fd = -1;
    timeout = 0;
    buffered = 0;
    
    signal(SIGINT, cancel_handler);
    
    while ((ch = getopt(argc, argv, "i:tbh")) != -1) {
	switch (ch) {
	case 'i':
	    if (asprintf(&spy_dev, "/dev/%s", optarg) == -1) {
		errx(1, "Cannot allocate memory\n");
	    }
	    if ((i = open(spy_dev, O_RDONLY)) == -1) {
		errx(1, "Cannot locate device %s\nerror: %s\n", 
		     spy_dev, strerror(errno));
	    }
	    close(i);
	    break;
	case 't':
	    timeout++;
	    break;
	case 'b':
	    buffered++;
	    break;
	case 'h':
	    usage();
	    break;
	}
    }
    argc -= optind;
    argv += optind;

    for (i = 0; i < 255; i++) {
	snprintf(filter_device, sizeof(filter_device), "/dev/bpf%d", i);
	printf("%d\n", i);
	if ((bpf_fd = open(filter_device, O_RDWR)) == -1) {
	    if (errno == EBUSY) {
		continue;
	    } else {
		errx(1, "Error opening BPF device /dev/bpf%d\n%s\n", 
		     i, strerror(errno));
	    }
	} else {
	    break;
	}
    }

    printf("ioctl(GBLEN)\n");
    if (ioctl(bpf_fd, BIOCGBLEN, &packet_len) == -1) {
	errx(1, "Error getting buffer size\nerror: %s\n", strerror(errno));
    }

    if ((buffer = (unsigned char *) malloc(packet_len)) == NULL) {
	errx(1, "Error getting memory for buffer\n");
    }

    hdr = (struct bpf_hdr *) buffer;

    printf("ioctl(SBLEN)\n");
    if (ioctl(bpf_fd, BIOCSBLEN, &packet_len) == -1) {
	errx(1, "Error setting buffer size\nerror %s\n", strerror(errno));
    }

    if (spy_dev != NULL) {
	strncpy(req.ifr_name, spy_dev, sizeof(req.ifr_name));
    } else {
	strcpy(req.ifr_name, "lo0");
    }
    printf("req.ifr_name=%s\n", req.ifr_name);

    printf("ioctl(SETIF)\n");
    if (ioctl(bpf_fd, BIOCSETIF, &req) == -1) {
	errx(1, "Error attaching to device %s, error: %s\n", 
	     spy_dev, strerror(errno));
    }
    if (ioctl(bpf_fd, BIOCGDLT, &type) == -1) {
	errx(1, "Error getting interface type\nerror: %s\n", strerror(errno));
    }

    printf("Interface type: %s\n", if_type(type));

    i = 1;
    printf("ioctl(IMMEDIATE)\n");
    if (!buffered && ioctl(bpf_fd, BIOCIMMEDIATE, &i) == -1) {
	errx(1, "Error setting immediate mode\nerror: %s\n", strerror(errno));
    }

    timeout_val.tv_sec = 10;
    timeout_val.tv_usec = 0;
    printf("ioctl(SRTIMEOUT)\n");
    if (timeout && ioctl(bpf_fd, BIOCSRTIMEOUT, &timeout_val) == -1) {
	errx(1, "Error setting timeout %s\n", strerror(errno));
    }

    while (1) {
	if (read(bpf_fd, buffer, packet_len) == 0) {
	    printf("Timeouted\n");
	    if (timeout) {
		break;
	    }
	};
	
	printf("Packet received ---------\n");
	printf("Captured size: %d\nReal size: %d\n", hdr->bh_caplen, hdr->bh_datalen);
	for (i = 0; i < hdr->bh_caplen; i++) {
	    if ((i % 16) == 0) {
		printf("\n0x%04x ", i);
	    }
	    printf("%02x ", buffer[i + hdr->bh_hdrlen]);
	}
	for (i = 0; i < hdr->bh_caplen; i++) {
	    if (buffer[i + hdr->bh_hdrlen] <= 0x37 ||
		(buffer[i + hdr->bh_hdrlen] >= 0x177 &&
		 buffer[i + hdr->bh_hdrlen] <= 0x377)) {
		printf(".");
	    } else {
		printf("%c", buffer[i + hdr->bh_hdrlen]);
	    }
	}
	printf("\n");
    }

    if (ioctl(bpf_fd, BIOCGSTATS, &stat) == -1) {
	errx(1, "Error getting statistics\nerror: %s\n", strerror(errno));
    }
    printf("Received: %d Dropped by filter:%d\n", stat.bs_recv, stat.bs_drop);
    close(bpf_fd);
    free(spy_dev);
    
    return 0;
}


void cancel_handler(int arg)
{
    printf("\n");
    if (bpf_fd != -1) {
	if (ioctl(bpf_fd, BIOCGSTATS, &stat) == -1) {
	    errx(1, "Error getting statistics\nerror: %s\n", strerror(errno));
	}
	printf("Received:%d Dropped by filter:%d\n", 
	       stat.bs_recv, stat.bs_drop);
	close(bpf_fd);
    }
    free(spy_dev);
    exit(0);
}


void usage()
{
    printf("Usage: bpf [-b][-t][-i interface_name][-h]\n");
    printf("       -b   - buffered input from BPF\n");
    printf("       -t   - set read timeout\n");
    printf("       -i   - set interfaceto sniff from\n");
    printf("       -h   - this help\n");
    exit(0);
}


char *if_type(int _if_type)
{
    switch (_if_type) {
    case DLT_NULL:
	return "no link-layer encapsulation";
    case DLT_EN10MB:
	return "Ethernet (10Mb)";
    case DLT_EN3MB:
	return "Experimental Ethernet (3Mb)";
    case DLT_AX25:
	return "Amateur Radio AX.25";
    case DLT_PRONET:
	return "Proteon ProNET Token Ring";
    case DLT_CHAOS:
	return "Chaos";
    case DLT_IEEE802:
	return "IEEE 802 Networks";
    case DLT_ARCNET:
	return "ARCNET";
    case DLT_SLIP:
	return "Serial Line IP";
    case DLT_PPP:
	return "Point-to-Point Protocol";
    case DLT_FDDI:
	return "FDDI";
    case DLT_ATM_RFC1483:
	return "LLC/SNAP encapulated ATM";
    }
    
    return "Unknown";
}
