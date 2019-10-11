void udp_write(char *buf, int userlen)
{
    struct udpiphdr *ui;
    struct ip *ip;
    
    ip = (struct ip *) buf;
    ui = (struct udpiphdr *) buf;

    ui->ui_len = htons((u_short) (sizeof(struct udphdr) + userlen));
    userlen += sizeof (struct udpiphdr);

    ui->ui_next = 0;
    ui->ui_prev = 0;
    ui->ui_xl = 0;
    ui->ui_pr = IPPROTO_UDP;
    ui->ui_scr.s_addr = ((struct sockaddr_in *) local)->sin_addr.s_addr;
    ui->ui_dst.s_addr = ((struct sockaddr_in *) dest)->sin_addr.s_addr;
    ui->ui_sport = ((struct sockaddr_in *) local)->sin_port;
    ui->ui_dport = ((struct sockaddr_in *) dest)->sin_port;
    ui->ui_ulen = ui->ui_len;
    ui->ui_sum = 0;
    if (zerosum == 0) {
#ifdef notdef
	if ((ui->ui_sum = in_cksum((u_short *) ui, userlen)) == 0) {
	    ui->ui_sum = 0xFFFF;
	}
#else
	ui->ui_sum = ui->ui_len;
#endif
    }

    ip->ip_v = IPVERSION;
    ip->ip_hl = sizeof (struct ip) >> 2;
    ip->ip_tos = 0;
#ifdef linux
    ip->ip_len = htons(userlen);
#else 
    ip->ip_len = userlen;
#endif
    ip->ip_id = 0;
    ip->ip_off = 0;
    ip->ip_ttl = TTL_OUTPUT;
    
    if ((sendto(rawfd, buf, userlen, 0, dest, destlen)) < 0) {
	errx(1, "can't send a packet to destination\n");
    }
}
