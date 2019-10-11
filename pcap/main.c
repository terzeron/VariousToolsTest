#include <unistd.h>
#include <signal.h>
#include <netdb.h>
#include <string.h>
#include <err.h>
#include "udpcksum.h"

struct sockaddr *dest, *local;
socklen_t destlen, locallen;

int datalink;
char *device;
int fddipad;
pcap_t *pd;
int rawfd;
int snaplen = 200;
int verbose;
int zerosum;

static void usage(const char *);

struct addrinfo *host_serv(const char *host, const char *serv, int family, int socktype);

int main(int argc, char *argv[]) 
{
    int c, on = 1;
    char *ptr, localname[1024], *localport;
    struct addrinfo *aip;

    if (argc < 2) {
	usage("");
    }

    if (gethostname(localname, sizeof (localname)) < 0) {
	errx(1, "gethostname error");
    }
    localport = LOCALPORT;
    opterr = 0;
    while ((c = getopt(argc, argv, "0i:l:v")) != -1) {
	switch (c) {
	case '0':
	    zerosum = 1;
	    break;

	case 'i':
	    device = optarg;
	    break;
	    
	case 'l':
	    if ((ptr = strrchr(optarg, '.')) == NULL) {
		usage("invalid -l option");
	    }
	    *ptr++ = 0;
	    localport = ptr;
	    strncpy(localname, optarg, sizeof(localname));
	    break;
	    
	case 'v':
	    verbose = 1;
	    break;
	    
	case '?':
	    usage("unrecognized option");
	    break;
	}
    }
    
    if (optind != argc - 2) {
	usage("missing <host> and/or <serv>");
    }

    aip = host_serv(argv[optind], argv[optind + 1], AF_INET, SOCK_DGRAM);
    dest = aip->ai_addr;
    destlen = aip->ai_addrlen;

    aip = host_serv(localname, localport, AF_INET, SOCK_DGRAM);
    local = aip->ai_addr;
    locallen = aip->ai_addrlen;

    rawfd = socket(dest->sa_family, SOCK_RAW, 0);
    if (rawfd < 0) {
	errx(1, "can't open socket\n");
    }
    setsockopt(rawfd, IPPROTO_IP, IP_HDRINCL, &on, sizeof(on));
    open_pcap();
    setuid(getuid());

    signal(SIGTERM, cleanup);
    signal(SIGINT, cleanup);
    signal(SIGHUP, cleanup);
    
    test_udp();
    
    cleanup(0);
    
    return 0;
}
	
struct addrinfo *host_serv(const char *host, const char *serv, int family, 
			   int socktype)
{
    int             n;
    struct addrinfo hints, *res;
    
    bzero(&hints, sizeof(struct addrinfo));
    hints.ai_flags = AI_CANONNAME;  /* always return canonical name */
    hints.ai_family = family;       /* AF_UNSPEC, AF_INET, AF_INET6, etc. */
    hints.ai_socktype = socktype;   /* 0, SOCK_STREAM, SOCK_DGRAM, etc. */
    
    if ( (n = getaddrinfo(host, serv, &hints, &res)) != 0)
        return(NULL);
    
    return(res);    /* return pointer to first on linked list */
}
    
    
void usage(const char *msg)
{
    printf(
	"usage: udpcksum [ options ]\n"
	"options: -h <host>    (can be hostname or address string)\n"
	"         -s <service> (can be service name or decimal port number)\n"
	"         -c    AI_CANONICAL flag\n"
	"         -p    AI_PASSIVE flag\n"
	"         -l N  loop N times (check for memory leaks with ps)\n"
	"         -f X  address family, X = inet, inet6, unix\n"
	"         -r X  protocol (not yet implemented)\n"
	"         -t X  socket type, X = stream, dgram, raw, rdm, seqpacket\n"
	"         -v    verbose\n"
	"         -e    only do test of error returns (no options required)\n"
	"  without -e, one or both of <host> and <service> must be specified.\n"
	);
    
    if (msg[0] != 0)
	printf("%s\n", msg);
    exit(1);
}


