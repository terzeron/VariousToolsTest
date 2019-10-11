#include <pcap.h>
#include <netinet/in_systm.h>
#include <netinet/in.h>
#include <netinet/ip.h>
#include <netinet/ip_var.h>
#include <netinet/udp.h>
#include <netinet/udp_var.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/if_ether.h>

#define LOCALPORT "39123"
#define TTL_OUT 64

extern struct sockaddr *dest, *local;
extern socklen_t destlen, locallen;
extern int datalink;
extern char *device;
extern pcap_t *pd;
extern int rawfd;
extern int snaplen;
extern int verbose;
extern int zerosum;

void cleanup(int);
char *next_pcap(int *);
void open_pcap();
void test_udp();
void udp_write(char *, int);
struct udpiphdr *udp_read(void);
