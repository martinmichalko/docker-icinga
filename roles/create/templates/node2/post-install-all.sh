#!/bin/bash

# Configure mgmt network interface
cat >/etc/network/interfaces <<EOF
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

# The loopback network interface
auto lo
iface lo inet loopback

# Management Network
auto eth0
iface eth0 inet static
    address 192.168.92.11 
    netmask 255.255.255.0
    gateway 192.168.92.1
    dns-nameservers 192.168.1.1

# second Network
auto eth1
iface eth1 inet static
    address 192.168.93.11
    netmask 255.255.255.0
    dns-nameservers 192.168.1.1
EOF


# Set SSH options to allow root password login
# line could look like '# PermitRootLogin without-password'
sed -i 's/.\{0,2\}PermitRootLogin.*/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i 's/.\{0,2\}PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sed -i '3 i\UseDNS no' /etc/ssh/sshd_config

#new machine is without the ssh keys and there in problem of running the sshd
dpkg-reconfigure openssh-server


#in this step the correction of resolv.conf does not work so in playbook
#cat >/etc/resolv.conf <<EOF
#nameserver 192.168.1.1
#EOF
