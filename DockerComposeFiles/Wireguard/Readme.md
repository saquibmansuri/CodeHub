# Setting Up WireGuard VPN Tunnel 
Basically, this will be used to access the resources inside the vnet/vpc like database which is not publicly accessible from the local network. 

## What is WireGuard 
Main Link: https://www.wireguard.com/  
Docker Setup Link: https://docs.linuxserver.io/images/docker-wireguard/#ports-p  
WireGuard is an extremely simple yet fast and modern VPN that utilizes state-of-the-art cryptography.   
It aims to be faster, simpler, leaner, and more useful than IPsec, while avoiding the massive headache.   
WireGuard is designed as a general purpose VPN for running on embedded interfaces and super computers alike, fit for many different circumstances.   
Initially released for the Linux kernel, it is now cross-platform (Windows, macOS, BSD, iOS, Android) and widely deployable.  
It is regarded as the most secure, easiest to use, and simplest VPN solution in the industry.   

## Purpose of the document
This document provides a comprehensive guide to setting up a WireGuard VPN to securely connect to an Azure PostgreSQL Flexible Server inside a vnet which is not publicly accessible.  
It covers prerequisites, configuration steps, and troubleshooting tips. 

## Prerequisites 
- **Azure Account**: An active Azure subscription and a resource group for provisioning resources. 
- **Vnet & Postgres Server Setup**: Create Vnet and spin up an azure postgres server in the vnet turning off all public access. 
- **Virtual Machine/Bastion Host**: Create a Virtual Machine (ubuntu linux recommended) within the same Virtual Network (VNet) where the Azure PostgreSQL server resides, ensure VM has a public ip for ssh access. 
- **SSH Access**: Ensure you can ssh into the virtual machine, for this allow access on port 22 from your ip in the network security group attached to the virtual machine. 
- **Docker and Docker Compose**: Ensure that Docker and Docker Compose are installed on the Azure VM. 

## Step 1: Configure Network Security Group (NSG) for WireGuard

1. **Access NSG Settings**:
- Navigate to the VM's networking settings in the Azure portal. 
- Locate and click on the associated Network Security Group (NSG). 
  
2. **Add Inbound Security Rule for WireGuard**:
- Click on "Inbound security rules". 
- Click "+ Add" to create a new rule: 
  - **Source**: Any (or specify IP ranges for more security). 
  - **Source port ranges**: * 
  - **Destination**: Any 
  - **Service**: Custom 
  - **Destination port ranges**: `51820` 
  - **Protocol**: UDP 
  - **Action**: Allow 
  - **Priority**: Set a priority number (e.g., 300). 
  - **Name**: `Allow_WireGuard`. 

3. **Add Outbound Rule for DNS Queries (if all outbound access is allowed then skip this step)**: 
- Still in NSG, click on "Outbound security rules".  
- Ensure there is a rule allowing outbound traffic on UDP port `53` for DNS queries.  

## Step 2: Set Up WireGuard VPN in the VM

1. **SSH into Your VM**:
Use SSH to connect to your Azure VM: `ssh username@your-vm-public-ip`  

2. **Create WireGuard Configuration Directory**:
```
mkdir ~/wireguard  
cd ~/wireguard
```

3. **Create Docker Compose File for WireGuard**:
Use a text editor (e.g., `nano`) to create `docker-compose.yml`:  
`nano docker-compose.yml`

5. **Add WireGuard Configuration to `docker-compose.yml`**:
Paste the following configuration:  
```
version: '3.9'
services:
  wireguard:
    image: lscr.io/linuxserver/wireguard:latest
    container_name: wireguard
    cap_add:
      - NET_ADMIN
    environment:
      - PUID=1000  # Your user ID (to get this puid simply run this command in vm - id)
      - PGID=1000  # Your group ID (to get this pgid simply run this command in vm - id)
      - TZ=UTC     # Set to UTC for neutral timezone
      - PEERS=client1  # Name of the peer/client configuration
    volumes:
      - ./config:/config  # Persist WireGuard config data, this will create all necessary files by default in this directory, then you can modify files in this directory later on
    ports:
      - 51820:51820/udp  # Map UDP port for WireGuard
    sysctls:
      - net.ipv4.conf.all.src_valid_mark=1
    restart: always
```
 
5. **Start WireGuard Service with Docker Compose**: 
`sudo docker compose up -d` 

6. **Display Client Configuration for WireGuard**:  
Run this command to display configuration for `client1`.<br> 
Although you can see it in the .config directory that you attached with the container:   
`sudo docker exec -it wireguard /app/show-peer client1`  

8. **Modify Client Configuration File (`peer_client1.conf`) on VM**:  
Open the generated configuration file located in `~/wireguard/config/peer_client1/`:   
`nano ~/wireguard/config/peer_client1/peer_client1.conf` 

9. **Update DNS & AllowedIPS's in Client Configuration File**:
Modify existing file as follows:

```
[Interface]
Address = <x.x.x.x/x>                     # DONT CHANGE THIS
PrivateKey = <your-client-private-key>    # DONT CHANGE THIS
ListenPort = 51820                        # DONT CHANGE THIS
DNS = 168.63.129.16                       # DELETE THE EXISITNG DNS IP AND USE THIS GLOBAL AZURE DNS IP MENTIONED HERE

[Peer]
PublicKey = <your-server-public-key>      # DONT CHANGE THIS 
PresharedKey = <your-preshared-key>       # DONT CHANGE THIS
Endpoint = <your-vm-public-ip>:51820      # DONT CHANGE THIS
AllowedIPs = X.X.X.X/X, 168.63.129.16/32  # ADD SUBNET CIDR AND AZURE DNS IP, YOU CAN ADD MULTIPLE ENTRIES SEPARATED BY A COMMA
```

9. **Save Changes and Exit Editor**.

## Step 3: Connect from Local Machine

1. **Install WireGuard on Local Machine (Windows)**:
Download and install WireGuard from [WireGuard's official website](https://www.wireguard.com/install/). 

2. **Import Client Configuration File into WireGuard App**: 
COPY the content of `wireguard/config/peer_client1/peer_client1.conf` file and save it in a file in local file example - `peer_client1_local.conf`.  
Then, Open WireGuard and click on "Add Tunnel," and select "Import Tunnel(s) from File."<br> 
Choose your file `peer_client1_local.conf`. 

3. **Activate Tunnel in WireGuard App**:<br> 
Select your tunnel and click on "Activate." 

4. **Test Connection to PostgreSQL Database**:
- Try to ping: `ping mydbserver.postgres.database.azure.com` 
- Try nslookup: `nslookup mydbserver.postgres.database.azure.com` 
- Use a PostgreSQL client like `psql` or pgAdmin to connect

## Step 4: Disconnect the tunnel from Local Machine
- Open wireguard desktop application , go to your tunnel and then click on 'Deactivate' 

## Conclusion
We have successfully set up a secure connection from our local machine to an Azure PostgreSQL Flexible Server using WireGuard VPN, ensuring that all traffic is routed through a private network without exposing sensitive data over public endpoints. 
