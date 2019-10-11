struct udpiphdr *udp_read()
{
    int len;
    char *ptr;
    struct ether_header *eptr;

    for ( ; ; ) {
	ptr = next_pcap(&len);
	
	switch (datlink) {
	case DLT_NULL:
	    return udp_check(ptr + 4, len - 4);
	case DLT_EN10MB:
	    eptr = (struct ether_header *) ptr;
	    if (ntohs(eptr->ether_type) != ETHERTYPE_IP) {
		errx(1, "Ethernet type %x not IP\n", ntohs(eptr->ether_type));
	    }
	    return udp_check(ptr + 14, len - 14);
	case DLT_SLIP:
	    return udp_check(ptr + 24, len - 24);
	case DLT_PPP:
	    return udp_check(ptr + 24, len - 24);
	default:
	    errx(1, "Unsupported datalink (%d)\n", datalink);
	}
    }
}


struct udpiphdr *udp_check(char *ptr, int len)
{
    int hlen;
    struct ip *ip;
    struct udpiphdr *ui;
    
    if (len < sizeof (struct ip) + sizeof (struct udphdr)) {
	errx(1, "len=%d\n", len);
    }

    ip = (struct ip *) ptr;
    if (ip->ip_v != IPVERSION) {
	errx(1, "ip_v=%d\n", ip->ip_v);
    }
    hlen = ip->ip_hl << 2;
    if (hlen < sizeof (struct ip)) {
	errx(1, "ip_hl=%d\n", ip->ip_hl);
    }
    if ((ip->ip_sum = in_cksum((u_short *) ip, hlen)) != 0) {
	errx(1, "ip checksum error\n");
    }
    if (ip->ip_p == IPPROTO_UDP) {
	ui = (struct udpiphdr *) ip;
	return ui;
    } else {
	errx(1, "not a UDP packet\n");
    }
}


void cleanup(int signo)
{
    struct pcap_stat stat;
    
    fflush(stdout);

    putc('\n', stdout);

    if (verbose) {
	if (pcap_stats(pd, &stat) < 0) {
	    errx(1, "pcap_stats: %s\n", pcap_getherr(pd));
	}
	printf("%d packets received by filter\n", stat.ps_recv);
	printf("%d packets dropped by kernel\n", stat.ps_drop);
    }
    
    exit(0);
}
