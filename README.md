# Open Source S2S VPN + NAT Instance for OCI Object STORAGE   #
_Access OCI Object Storage over S2S IPSEC VPN using private IP (StrongSwan S2S VPN + NAT Instance for Object Storage)._ 



***Prerequisites:***

- An OCI user account with enough permissions to provision a new Compute VM Instance 
- One Virtual Cloud Network and one Public Subnet already created to host the VPN+NAT Instance. 
- One private ip address available in your VCN/Subnet. 
- One OCI Reserved Public IP address.  
-	CPE Public IP address (on-premises VPN router public IP address) 
-	On-premises internal network ip address range in CIDR notation.
 
 
### 1- Prepare the CloudInit script for the migration server(AZ2OCIVM).

 1.1-	Download the following CloudInit script : https://raw.githubusercontent.com/BaptisS/oci_os_vpn_nat_storage/master/strong_nat_storage_v2_cloudinit.sh
 
 1.2-   Locate the section 'conn OCIPri' and update the S2S IPSEC VPN parameters with your own values : 
 
    -conn OCIPri
        authby=psk
        auto=start
        keyexchange=ikev2
        left=192.168.241.5 (Private Ip address for the VPN+NAT Instance. Must be in VCN/Subnet IP address range) 
        leftid=1.2.3.4 (Reserved Public Ip address for the VPN+NAT Instance.)
        leftsubnet=192.168.241.0/24 (VCN IP address range in CIDR notation.)
        right=9.8.7.6 (CPE Public Ip address.)
        rightid=9.8.7.6 (CPE Public IKE IDentifier.)
        rightsubnet=192.168.240.0/24 (On-premises internal network IP address range in CIDR notation.)
        ike=aes256-sha384-modp1536 (Phase 1 hashing, encryption + PFS proposals.)
        esp=aes256-sha1-modp1536 (Phase 2 hashing, encryption + PFS proposals.)
 
 1.3-   Locate the following section ('cat <<EOF >> /etc/strongswan/ipsec.secrets') and update the content with your own pre shared key. 
  
     cat <<EOF >> /etc/strongswan/ipsec.secrets
      192.168.241.5 9.8.7.6 : PSK "baptiste123456789!"
      1.2.3.4 9.8.7.6 : PSK "baptiste123456789!"
     EOF
 
 1.4-   Save the updated CloudInit script.  
 

### 3- Provision the S2S VPN + NAT Instance (OCIVPNNAT01).    

 3.1-	Sign-in to the OCI web console with your OCI user account. 
 
 3.2-	Go to the OCI menu -> Compute -> Instances section . 
 
 3.3-   Click on 'Create Instance'.
 
 3.3.1-   Provide a Name such as 'OCIVPNNAT01'.
 
 3.3.2-   Keep the default image selected (Oracle Linux 7.x).
 
 3.3.3-   Select the desired Availability Domain for the Migration VM. 
 
 3.3.4-   Choose a Shape based on your requirements. (+2.1 recommended)
 
 3.3.5-   Select destination Compartment, VCN and subnet for the VPN+NAT VM. (Must be a Public Subnet)  
 
 3.3.6-   Ensure 'Assign a Public IP Address' is selected.
 
 3.3.8-   Provide SSH Public Key for the Migration VM. 
 
 3.3.9-   Click the 'Show Advanced Options' link. 
 
 3.3.10-  In the 'Management' tab, ensure proper Compartment is selected. 

 3.3.11-  Select/Paste the updated Cloud Init Script containing your variables.  
 
 3.3.12-  In the 'Networking' tab , specify the desired private ip address for the VPN+NAT instance. (Must be the same as defined in the cloudInit script for the 'leftid' variable)
 
 3.3.13-  Click 'Create Button' to start provisioning the VPN+NAT VM Instance. (End-to-end deployment including post-provisioning tasks should take approx. 3 min)
 

### 4- Assign desired Reserved Public IP address to the VPN+NAT Instance.   

 4.1-	Once the VPN+NAT server has been provisionned successfully, you should assign the desired Reserved public IP address to it's primary virtual network interface. For this purpose go in the Resources section of the Compute VM instance dashboard and select 'Attached VNICs'. 
 
 4.2-   Click on the 'Primary VNIC' name. 

 4.3-   In the Resources section , click on 'IP Addresses (1)'. 
 
 4.4-   Edit the IP addresses configuration (Right menu -> Edit). 
 
 4.5-   In the 'Public IP Address' section , select 'NO PUBLIC IP' instead of the default 'EPHEMEREAL PUBLIC IP'. 
 
 4.6-   Click 'Update' button. 
 
 4.7-   Edit (again) the IP addresses configuration (Right menu -> Edit).
 
 4.8-   In the 'Public IP Address' section , select 'RESERVED PUBLIC IP' instead of the current 'NO PUBLIC IP'. Choose the desired reserved Public IP address in the list.  
 
 4.9-   Click 'Update' button. 
 

![PMScreens](/img/01.jpg)

