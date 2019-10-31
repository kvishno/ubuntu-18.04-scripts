#!/bin/bash
######################################################
#### WARNING PIPING TO BASH IS STUPID: DO NOT USE THIS
######################################################
# modified from:  jimangel/ubuntu-18.04-scripts/blob/master/prepare-ubuntu-18.04-template.sh
# TESTED ON UBUNTU 18.04 LTS

# SETUP & RUN
# curl -sL https://raw.githubusercontent.com/shingonoide/ubuntu-18.04-scripts/master/prepare-ubuntu-18.04-template.sh | sudo -E bash -

if [ `id -u` -ne 0 ]; then
	echo Needs sudo
	exit 1
fi

set -v

#update apt-cache
apt update -y
apt upgrade -y

#install packages
apt install -y open-vm-tools

#Stop services for cleanup
service rsyslog stop

#clear audit logs
if [ -f /var/log/wtmp ]; then
    truncate -s0 /var/log/wtmp
fi
if [ -f /var/log/lastlog ]; then
    truncate -s0 /var/log/lastlog
fi

#cleanup /tmp directories
rm -rf /tmp/*
rm -rf /var/tmp/*

#cleanup current ssh keys
rm -f /etc/ssh/ssh_host_*

# prevent cloudconfig from preserving the original hostname
sed -i 's/preserve_hostname: false/preserve_hostname: true/g' /etc/cloud/cloud.cfg
truncate -s0 /etc/hostname
hostnamectl set-hostname base-vm

#cleanup apt
apt clean

# cleans out all of the cloud-init cache / logs - this is mainly cleaning out networking info
sudo cloud-init clean --logs

#cleanup shell history
cat /dev/null > ~/.bash_history && history -c
history -w

#shutdown
shutdown -h now
