/**********************************************************************
* file:   testpcap3.c
* date:   Sat Apr 07 23:23:02 PDT 2001  
* Author: Martin Casado
* Last Modified:2001-Apr-07 11:23:05 PM
*
* Investigate using filter programs with pcap_compile() and
* pcap_setfilter()
*
**********************************************************************/

#include <pcap.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include <err.h>
#include <signal.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netinet/if_ether.h> 
#include <net/bpf.h>

#define ETHER_HDRLEN 14
#define PRINT_ETHER_ADDR(addr) { u_char *ptr = (addr); int i = ETHER_ADDR_LEN; do { printf("%s%02x", (i == ETHER_ADDR_LEN) ? "" : ":", *ptr++); } while (--i > 0); }

void ether_if_print(unsigned char *, const struct pcap_pkthdr *, const unsigned char *);
void ether_if_print(unsigned char *, const struct pcap_pkthdr *, const unsigned char *);

const u_char *packetp;
const u_char *snapend;
static pcap_t *pd;
struct printer {
    pcap_handler f;
    int type;
};
static struct printer printers[] = {
    { ether_if_print, DLT_IEEE802 }, 
    { ether_if_print, DLT_EN10MB }, 
    { NULL, 0}
};

void cleanup(int signo)
{
    struct pcap_stat stat;
    
    /* Can't print the summary if reading from a savefile */
    if (pd != NULL && pcap_file(pd) == NULL) {
	(void)fflush(stdout);
	putc('\n', stderr);
	if (pcap_stats(pd, &stat) < 0)
	    (void)fprintf(stderr, "pcap_stats: %s\n",
			  pcap_geterr(pd));
	else {
	    (void)fprintf(stderr, "%d packets received by filter\n",
			  stat.ps_recv);
	    (void)fprintf(stderr, "%d packets dropped by kernel\n",
			  stat.ps_drop);
	}
    }
    exit(0);
}


static inline void ether_print(register const u_char *bp, u_int length)
{
    register const struct ether_header *ep;
    int ether_type = 0;

    ep = (const struct ether_header *) bp;
    ether_type = ntohs(ep->ether_type);

    PRINT_ETHER_ADDR(ep->ether_shost);
    printf("-->");
    PRINT_ETHER_ADDR(ep->ether_dhost);
    printf(" ");
    switch (ether_type) {
    case ETHERTYPE_PUP:
	printf("PUP");
	break;
    case ETHERTYPE_IP:
	printf("IP");
	break;
    case ETHERTYPE_ARP:
	printf("ARP");
	break;
    case ETHERTYPE_REVARP:
	printf("REVARP");
	break;
    case ETHERTYPE_VLAN:
	printf("VLAN");
	break;
    case ETHERTYPE_IPV6:
	printf("IPV6");
	break;
    case ETHERTYPE_LOOPBACK:
	printf("LOOPBACK");
	break;
    default:
	printf("Unknown(0x%04X)", ether_type);
	break;
    }
    printf(" %dbytes", length);
}


void ether_if_print(u_char *user, const struct pcap_pkthdr *h, 
		    const u_char *p)
{
    u_int caplen = h->caplen;
    u_int length = h->len;
    struct ether_header *ep;
    u_short ether_type;
    //u_short extracted_ethertype;
    
    if (caplen < ETHER_HDRLEN) {
	printf("[|ether]");
	goto out;
    }
    
    // 프로그램 작성 유의사항
    // 이 위치에서 p->ether_dhost가 ff:ff:ff:ff:ff:ff일 경우 
    // broadcast되는 ARP request frame이므로 ifconfig alias를
    // 수행해야 함

    ether_print(p, length);

#ifdef TEST
    /*
     * Some printers want to get back at the ethernet addresses,
     * and/or check that they're not walking off the end of the packet.
     * Rather than pass them all the way down, we set these globals.
     */
    packetp = p;
    snapend = p + caplen;
    
    length -= ETHER_HDRLEN;
    caplen -= ETHER_HDRLEN;
    ep = (struct ether_header *)p;
    p += ETHER_HDRLEN;
    
    ether_type = ntohs(ep->ether_type);
    ether_print((u_char *) ep, length + ETHER_HDRLEN);
#endif

 out:
    putchar('\n');
}


static pcap_handler lookup_printer(int type)
{
    struct printer *p;
    
    for (p = printers; p->f; ++p) {
	if (type == p->type) {
	    return p->f;
	}
    }

    errx(1, "Unknown data link type");
}


int main(int argc, char **argv)
{ 
    int snapshot;
    int snaplen = 96;
    char errbuf[PCAP_ERRBUF_SIZE];
    struct bpf_program fp;      /* hold compiled program     */
    bpf_u_int32 maskp;          /* subnet mask               */
    bpf_u_int32 netp;           /* ip                        */
    char filter[] = "arp";
    char dev[] = "dc1"; // or "xl0"???
    void (*oldhandler)(int);
    pcap_handler printer;

    /* grab a device to peak into... */
    /*
      dev = pcap_lookupdev(errbuf);
      if (dev == NULL) { 
      fprintf(stderr,"%s\n", errbuf); 
      exit(1); 
      }
    */

    /* open device for reading this time lets set it in promiscuous
     * mode so we can monitor traffic to another machine             */
    printf("dev=%s snaplen=%d\n", dev, snaplen);
    pd = pcap_open_live(dev, snaplen, 1, 1000, errbuf);
    if (pd == NULL) { 
	errx(1, "pcap_open_live(): %s", errbuf); 
	exit(-1); 
    }

    // pcap_snapshot 처리
    snapshot = pcap_snapshot(pd);
    if (snaplen < snapshot) {
	warnx("pcap_snapshot: %s", pcap_geterr(pd));
	snaplen = snapshot;
    }

    /* ask pcap for the network address and mask of the device */
    if (pcap_lookupnet(dev, &netp, &maskp, errbuf) < 0) {
	errx(1, "pcap_lookup: %s", errbuf);
	exit(-1);
    }
    printf("localnet=%u netmask=%u\n", netp, maskp);

    /* Lets try and compile the program.. non-optimized */
    printf("cmdbuf=%s Oflag=%d netmask=%u\n", filter, 1, maskp);
   
    if (pcap_compile(pd, &fp, filter, 1, maskp) < 0) { 
	errx(1, "pcap_compile: %s", pcap_geterr(pd)); 
	exit(-1); 
    }

    // signal 등록
    signal(SIGTERM, cleanup);
    signal(SIGINT, cleanup);
    if ((oldhandler = signal(SIGHUP, cleanup)) != SIG_DFL) {
	signal(SIGHUP, oldhandler);
    }

    /* set the compiled program as the filter */
    if (pcap_setfilter(pd, &fp) < 0) { 
	errx(1, "pcap_setfilter: %s", pcap_geterr(pd)); 
	exit(-1); 
    }

    printer = lookup_printer(pcap_datalink(pd));

    /* ... and loop */ 
    if (pcap_loop(pd, -1, printer, NULL) < 0) {
	errx(1, "pcap_loop: %s", pcap_geterr(pd));
    }

    pcap_close(pd);
    return 0;
}




