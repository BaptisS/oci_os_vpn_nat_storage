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

vmmeta=$(curl -L http://169.254.169.254/opc/v1/instance/)
curegnoq=$(echo $vmmeta | jq -r '.region')
storip=$(dig +short objectstorage.$curegnoq.oraclecloud.com. | awk '{line = $0} END {print line}')
localip=$(hostname -I | awk '{print $1}')
firewall-offline-cmd --zone=public --add-rich-rule="rule family=ipv4 destination address='$localip' forward-port port=443 protocol=tcp to-port=443 to-addr='$storip'"

systemctl restart firewalld

systemctl enable strongswan

##### IPSEC Variables #####

leftid=a.b.c.d                   #OCI Reserved Public IP address :
leftsubnet=192.168.241.0/24      #OCI VCN IP address range in CIDR notation :
right=e.f.g.h                    #On-premises VPN Public IP address :
rightid=$right                   #Custom IKE IDentifier (Optional) :
rightsubnet=192.168.240.0/24     #On-premises internal network IP address range in CIDR notation:
P1props=aes256-sha384-modp1536   #Phase 1 proposals. Should be modified to match on-premises VPN endpoint configuration.
P2props=aes256-sha1-modp1536     #Phase 2 proposals. Should be modified to match on-premises VPN endpoint configuration.
PSK="Baptiste123456789!"         #Pre-Shared Key

##### IPSEC Variables #####

mv /etc/strongswan/ipsec.conf /etc/strongswan/ipsec.conf.bak
cat <<EOF >> /etc/strongswan/ipsec.conf

conn OCIPri
        authby=psk
        auto=start
        keyexchange=ikev2
        left=$localip
        leftid=$leftid 
        leftsubnet=$leftsubnet 
        right=$right
        rightid=$rightid   
        rightsubnet=$rightsubnet 
        ike=$P1props
        esp=$P2props
EOF
cat <<EOF >> /etc/strongswan/ipsec.secrets
$localip $right : PSK $PSK 
$leftid $right : PSK $PSK
EOF
strongswan restart

cd /home/opc/
echo $storip > curip
wget https://raw.githubusercontent.com/BaptisS/oci_nat_storage/master/netmask.sh
wget https://raw.githubusercontent.com/BaptisS/oci_nat_storage/master/natcheck.sh
chmod +x netmask.sh
chmod +x natcheck.sh

#echo "0 */12 * * * /home/opc/natcheck.sh" |crontab -
echo "* * * * * /home/opc/natcheck.sh" |crontab -

touch ~opc/userdata.`date +%s`.finish
#strongswan status
