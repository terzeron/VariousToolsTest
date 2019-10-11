#include <stdio.h>
#include <string.h>
#include <err.h>
#include <string.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <net/if.h>


int main()
{
    int s;
    char device[] = "dc1";
    char ipaddr[] = "10.0.3.200";
    char netmask[] = "255.255.0.0";
    struct sockaddr_in sin_ipaddr;
    struct sockaddr_in sin_netmask;
    struct ifaliasreq addreq;
    
    if ((s = socket(AF_INET, SOCK_DGRAM, 0)) < 0) {
	errx(1, "socket error");
    }

    // IP address를 socket address 타입으로 하여 생성
    sin_ipaddr.sin_len = 16;
    sin_ipaddr.sin_family = AF_INET;
    sin_ipaddr.sin_port = 0;
    inet_aton(ipaddr, &sin_ipaddr.sin_addr);
    bzero(sin_ipaddr.sin_zero, 8);
    // netmask를 socket address 타입으로 하여 생성
    sin_netmask.sin_len = 16;
    sin_netmask.sin_family = AF_UNSPEC;
    sin_netmask.sin_port = 0;
    inet_aton(netmask, &sin_netmask.sin_addr);
    bzero(sin_netmask.sin_zero, 8);

    // device name
    strncpy(addreq.ifra_name, device, IFNAMSIZ);
    // IP address
    bcopy(&sin_ipaddr, &addreq.ifra_addr, sizeof (struct sockaddr_in));
    // netmask 
    bcopy(&sin_netmask, &addreq.ifra_mask, sizeof (struct sockaddr_in));

    if (ioctl(s, SIOCAIFADDR, &addreq) < 0) {
	errx(1, "ioctl (SIOCAIFADDR)");
    }

    close(s);

    return 0;
}


#ifdef DEVELOP
(gdb) p *(struct ifaliasreq *) afp->af_addreq
{
    ifra_name = "dc1", '\000' <repeats 12 times>,  // @NEMFd@L=: dc1?!
    ifra_addr = {
	sa_len = 16 '\020', // 16 byte
	sa_family = 2 '\002', // AF_INET
	sa_data = "\000\000\n\000\003휫000\000\000\000\000\000\000"}, 
    ifra_broadaddr = {
	sa_len = 0 '\000', 
	sa_family = 0 '\000',
	sa_data = '\000' <repeats 13 times>
    }, 
    ifra_mask = {
	sa_len = 0 '\000', 
	sa_family = 0 '\000', 
	sa_data = '\000' <repeats 13 times>
    }
}
#endif
