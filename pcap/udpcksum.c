#include <stdio.h>
#include <signal.h>
#include <setjmp.h>
#include <err.h>
#include <unistd.h>
#include "udpcksum.h"

static sigjmp_buf jmpbuf;
static int canjump;

void sig_alrm(int signo) 
{
    if (canjump == 0) {
	return;
    }
    siglongjmp(jmpbuf, 1);
}

void send_dns_query()
{
    size_t nbytes;
    char buf[sizeof (struct udpiphdr) * 100], *ptr;
    short one;
    
    ptr = buf + sizeof (struct udpiphdr);
    *((u_short *) ptr) = htons(1234);
    ptr += 2;
    *((u_short *) ptr) = htons(0x0);
    ptr += 2;
    *((u_short *) ptr) = htons(1);
    ptr += 2;
    *((u_short *) ptr) = 0;
    ptr += 2;
    *((u_short *) ptr) = 0;
    ptr += 2;
    *((u_short *) ptr) = 0;
    ptr += 2;

    memcpy(ptr, "\001a\014root-servers\003net\000", 20);
    ptr += 20;
    one = htons(1);
    memcpy(ptr, &one, 2);
    ptr += 2;
    memcpy(ptr, &one, 2);
    ptr += 2;

    nbytes = 36;
    udp_write(buf, nbytes);
    if (verbose) {
	printf("sent: %d bytes of data\n", nbytes);
    }
 

}


void test_udp()
{
    int nsent = 0, timeout = 3;
    struct udpiphdr *ui;

    signal(SIGALRM, sig_alrm);

    if (sigsetjmp(jmpbuf, 1)) {
	if (nsent >= 3) {
	    errx(1, "no response");
	}
	printf("timeout\n");
	timeout *= 2;
    }
    canjump = 1;
    
    send_dns_query();
    nsent++;

    alarm(timeout);
    ui = udp_read();
    canjump = 0;
    alarm(0);

    if (ui->ui_sum == 0) {
	printf("UDP checksums off\n");
    } else {
	printf("UDP checksums on\n");
    }
    if (verbose) {
	printf("received UDP checksum=%x\n", ui->ui_sum);
    }
}

