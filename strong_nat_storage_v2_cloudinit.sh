#!/bin/bash
sudo su
yum install strongswan lsof -y
for vpn in /proc/sys/net/ipv4/conf/*;
do echo 0 > $vpn/accept_redirects;
echo 0 > $vpn/send_redirects;
done
echo net.ipv4.ip_forward = 1 >> /etc/sysctl.conf
echo net.ipv4.conf.all.accept_redirects = 0 >> /etc/sysctl.conf
echo net.ipv4.conf.all.send_redirects = 0 >> /etc/sysctl.conf
echo net.ipv4.tcp_max_syn_backlog = 1280 >> /etc/sysctl.conf
echo net.ipv4.icmp_echo_ignore_broadcasts = 1 >> /etc/sysctl.conf
echo net.ipv4.conf.all.accept_source_route = 0 >> /etc/sysctl.conf
echo net.ipv4.conf.all.accept_redirects = 0 >> /etc/sysctl.conf
echo net.ipv4.conf.all.secure_redirects = 0 >> /etc/sysctl.conf
echo net.ipv4.conf.all.log_martians = 1 >> /etc/sysctl.conf
echo net.ipv4.conf.default.accept_source_route = 0 >> /etc/sysctl.conf
echo net.ipv4.conf.default.accept_redirects = 0 >> /etc/sysctl.conf
echo net.ipv4.conf.default.secure_redirects = 0 >> /etc/sysctl.conf
echo net.ipv4.icmp_echo_ignore_broadcasts = 1 >> /etc/sysctl.conf
echo net.ipv4.icmp_ignore_bogus_error_responses = 1 >> /etc/sysctl.conf
echo net.ipv4.tcp_syncookies = 1 >> /etc/sysctl.conf
echo net.ipv4.conf.all.rp_filter = 1 >> /etc/sysctl.conf
echo net.ipv4.conf.default.rp_filter = 1 >> /etc/sysctl.conf
echo net.ipv4.tcp_mtu_probing = 1 >> /etc/sysctl.conf
echo 2 > /proc/sys/net/ipv4/conf/all/rp_filter
echo 2 > /proc/sys/net/ipv4/conf/default/rp_filter
echo 2 > /proc/sys/net/ipv4/conf/eth0/rp_filter
echo 2 > /proc/sys/net/ipv4/conf/eth1/rp_filter
echo 2 > /proc/sys/net/ipv4/conf/ens3/rp_filter
echo 2 > /proc/sys/net/ipv4/conf/ens4/rp_filter
sysctl -p

systemctl mask iptables
systemctl stop iptables
firewall-offline-cmd --zone=public --add-port=443/tcp 
firewall-offline-cmd --zone=public --add-port=500/udp 
firewall-offline-cmd --zone=public --add-port=500/tcp
firewall-offline-cmd --zone=public --add-port=4500/udp 
firewall-offline-cmd --zone=public --add-port=4500/tcp
firewall-offline-cmd --zone=public --add-masquerade 
#firewall-offline-cmd --zone=public --add-forward-port=port=443:proto=tcp:toport=443:toaddr=1.2.3.4
localip=$(hostname -I | awk '{print $1}')
firewall-offline-cmd --zone=public --add-rich-rule="rule family=ipv4 destination address='$localip' forward-port port=443 protocol=tcp to-port=443 to-addr=1.2.3.4"
systemctl restart firewalld

systemctl enable strongswan
mv /etc/strongswan/ipsec.conf /etc/strongswan/ipsec.conf.bak
cat <<EOF >> /etc/strongswan/ipsec.conf

conn OCIPri
        authby=psk
        auto=start
        keyexchange=ikev2
        left=192.168.241.5
        leftid=1.2.3.4
        leftsubnet=192.168.241.0/24
        right=9.8.7.6
        rightid=9.8.7.6
        rightsubnet=192.168.240.0/24
        ike=aes256-sha384-modp1536
        esp=aes256-sha1-modp1536
EOF
cat <<EOF >> /etc/strongswan/ipsec.secrets
192.168.241.5 9.8.7.6 : PSK "baptiste123456789!"
1.2.3.4 9.8.7.6 : PSK "baptiste123456789!"
EOF
strongswan restart

cd /home/opc/
echo 1.2.3.4 > curip
wget https://raw.githubusercontent.com/BaptisS/oci_nat_storage/master/netmask.sh
wget https://raw.githubusercontent.com/BaptisS/oci_nat_storage/master/natcheck.sh
chmod +x netmask.sh
chmod +x natcheck.sh

#echo "0 */12 * * * /home/opc/natcheck.sh" |crontab -
echo "* * * * * /home/opc/natcheck.sh" |crontab -

touch ~opc/userdata.`date +%s`.finish
#strongswan status
