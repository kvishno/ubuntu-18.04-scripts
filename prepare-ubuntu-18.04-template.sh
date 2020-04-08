#!/bin/bash
######################################################
#### WARNING PIPING TO BASH IS STUPID: DO NOT USE THIS
######################################################
# modified from:  jimangel/ubuntu-18.04-scripts/blob/master/prepare-ubuntu-18.04-template.sh
# TESTED ON UBUNTU 18.04 LTS
#
# Also  modified from: https://infiniteloop.io/vmware-template-ubuntu-18-04-3-lts/

# SETUP & RUN
# curl -sL https://raw.githubusercontent.com/kvishno/ubuntu-18.04-scripts/master/prepare-ubuntu-18.04-template.sh | sudo -E bash -

if [ `id -u` -ne 0 ]; then
	echo Needs sudo
	exit 1
fi

set -v

# Update apt-cache
apt update -y && apt upgrade -y

# Install packages
apt install -y open-vm-tools net-tools nload

# Stop services for cleanup
service rsyslog stop

# Clear audit logs
if [ -f /var/log/wtmp ]; then
    truncate -s0 /var/log/wtmp
fi
if [ -f /var/log/lastlog ]; then
    truncate -s0 /var/log/lastlog
fi

# Cleanup /tmp directories
rm -rf /tmp/*
rm -rf /var/tmp/*

# Cleanup current SSH keys
rm -f /etc/ssh/ssh_host_*

# Create /etc/rc.local to regenerate ssh host keys if needed
cat << 'EOL' > /etc/rc.local 
#!/bin/sh
if [ ! -e /etc/ssh/ssh_host_rsa_key ]; then
  dpkg-reconfigure openssh-server
  systemctl restart ssh
fi
exit 0
EOL
chmod +x /etc/rc.local

# Prevent cloudconfig from preserving the original hostname
sed -i 's/preserve_hostname: false/preserve_hostname: true/g' /etc/cloud/cloud.cfg
truncate -s0 /etc/hostname
hostnamectl set-hostname ''

# Remove snapd service
apt-get -y remove --purge snapd

# Cleanup apt
apt clean

# cleans out all of the cloud-init cache / logs - this is mainly cleaning out networking info
sudo cloud-init clean --logs

# Clear machine-id
cp /dev/null /etc/machine-id

# Remove unwanted MOTD detail
chmod -x /etc/update-motd.d/10-help-text
chmod -x /etc/update-motd.d/50-motd-news

# VMware fix
if [ ! -e vmwarefixran.log ]; then
  echo vmware customization fix https://kb.vmware.com/s/article/56409
  sed -i 's/^D \/tmp 1777 root root -/#D \/tmp 1777 root root -/' /usr/lib/tmpfiles.d/tmp.conf
  sed -i '/^\[Unit\]/a\After=dbus.service' /lib/systemd/system/open-vm-tools.service
  touch vmwarefixran.log
else
  echo vmware fix already ran
fi

# Clear bash history
cp /dev/null ~/.bash_history && history -cw

# Shutdown
shutdown now
