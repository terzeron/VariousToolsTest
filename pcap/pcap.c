#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <err.h>
#include "udpcksum.h"

#define MAXLINE 4096

#define CMD "udp and src host %s and src port %d"


int sock_get_port(const struct sockaddr *sa, socklen_t salen)
{
    struct sockaddr_in  *sin = (struct sockaddr_in *) sa;
    
    switch (sa->sa_family) {
    case AF_INET: 
        return(sin->sin_port);
    }

    return(-1);     /* ??? */
}


char *sock_ntop_host(const struct sockaddr *sa, socklen_t salen)
{
    static char str[128];               /* Unix domain is largest */
    
    switch (sa->sa_family) {
    case AF_INET: {
	struct sockaddr_in *sin = (struct sockaddr_in *) sa;
	
	if (inet_ntop(AF_INET, &sin->sin_addr, str, sizeof(str)) == NULL) {
	    return(NULL);
	}
	return(str);
    }

#ifdef  HAVE_SOCKADDR_DL_STRUCT
    case AF_LINK: {
	struct sockaddr_dl *sdl = (struct sockaddr_dl *) sa;

	if (sdl->sdl_nlen > 0) {
	    snprintf(str, sizeof (str), "%*s", sdl->sdl_nlen, 
		     &sdl->sdl_data[0]);
	} else {
	    snprintf(str, sizeof (str), "AF_LINK, index=%d", sdl->sdl_index);
	}
	return(str);
    }
#endif
    default:
	snprintf(str, sizeof(str), "sock_ntop_host: unknown AF_xxx: %d, len %d", sa->sa_family, salen);
	return(str);
    }
    return (NULL);
}


void open_pcap(void)
{
    uint32_t localnet, netmask;
    char cmd[MAXLINE], errbuf[PCAP_ERRBUF_SIZE], str1[INET_ADDRSTRLEN],
	str2[INET_ADDRSTRLEN];
    struct bpf_program fcode;
    
    if (device == NULL) {
	if ((device = pcap_lookupdev(errbuf)) == NULL) {
	    errx(1, "pcap_lookup: %s\n", errbuf);
	}
    }
    printf("device=%s\n", device);

    if ((pd = pcap_open_live(device, snaplen, 0, 500, errbuf)) == NULL) {
	errx(1, "pcap_open_live: %s\n", errbuf);
    }
    if (pcap_lookupnet(device, &localnet, &netmask, errbuf) < 0) {
	errx(1, "pcap_lookupnet: %s\n", errbuf);
    }
    if (verbose) {
	printf("localnet=%s, netmask=%s\n", 
	       inet_ntop(AF_INET, &localnet, str1, sizeof (str1)), 
	       inet_ntop(AF_INET, &netmask, str2, sizeof (str2)));
    }

    snprintf(cmd, sizeof (cmd), CMD, sock_ntop_host(dest, destlen), 
	     ntohs(sock_get_port(dest, destlen)));
    
    if (verbose) {
	printf("cmd=%s\n", cmd);
    }
    if (pcap_compile(pd, &fcode, cmd, 0, netmask) < 0) {
	errx(1, "pcap_compile: %s", pcap_geterr(pd));
    }
    if (pcap_setfilter(pd, &fcode) < 0) {
	errx(1, "pcap_setfilter: %s", pcap_geterr(pd));
    }
    if ((datalink = pcap_datalink(pd)) < 0) {
	errx(1, "pcap_datalink: %s", pcap_geterr(pd));
    }
    if (verbose) {
	printf("datalink=%d\n", datalink);
    }
}


char *next_pcap(int *len)
{
    char *ptr;
    struct pcap_pkthdr hdr;

    while ((ptr = (char *) pcap_next(pd, &hdr)) == NULL)
	;
    *len = hdr.caplen;
    
    return ptr;
}
