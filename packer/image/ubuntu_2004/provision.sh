#!/bin/bash

# save build date
date > /var/log/image_build_date

# remove swap file
swapoff /swapfile
rm -f /swapfile
sed -i -e "/swapfile/d" /etc/fstab

# install parted #17956
apt-get -y install curl wget parted mlocate

# install imageboot
cp /opt/imageboot/imageboot.service /etc/systemd/system/
/bin/systemctl enable imageboot.service

# prevent the OS from updating the persistent-net rules. if we don't do this the instance will randomly choose network adapters (starting with eth1, and increasing after every snapshot deploy)
echo > /etc/udev/rules.d/70-persistent-net.rules
chattr +i /etc/udev/rules.d/70-persistent-net.rules

# configure ntp
sed --follow-symlinks -i -e 's/#NTP=.*/NTP=1.time.constant.com 2.time.constant.com 3.time.constant.com/' /etc/systemd/timesyncd.conf

# sysctl values for v6 advertisement / ip forwarding issue #17761
echo "" >> /etc/sysctl.conf
echo "# Accept IPv6 advertisements when forwarding is enabled" >> /etc/sysctl.conf
echo "net.ipv6.conf.all.accept_ra = 2" >> /etc/sysctl.conf
echo "" >> /etc/sysctl.conf

# sysctl values for BBR #26215
echo 'net.core.default_qdisc=fq' >> /etc/sysctl.conf
echo 'net.ipv4.tcp_congestion_control=bbr' >> /etc/sysctl.conf
echo '' >> /etc/sysctl.conf

# force secure passwords for the root user.
# password        requisite                       pam_cracklib.so retry=3 minlen=8 difok=3
apt-get -y install libpam-cracklib cracklib-runtime
mkdir /usr/share/dict/
mv /root/common.hwm /usr/share/dict/
mv /root/common.pwd /usr/share/dict/
mv /root/common.pwi /usr/share/dict/
sed --follow-symlinks -i -e 's/pam_cracklib.so\(.*\)/pam_cracklib.so\1 enforce_for_root dictpath=\/usr\/share\/dict\/common/' /etc/pam.d/common-password

# blacklist modules
# - ast module #23510
echo 'blacklist ast' > /etc/modprobe.d/blacklist-ast.conf
echo 'blacklist astdrm' >> /etc/modprobe.d/blacklist-ast.conf
echo 'blacklist astdrmfb' >> /etc/modprobe.d/blacklist-ast.conf
chown root:root /etc/modprobe.d/blacklist-ast.conf
chmod 644 /etc/modprobe.d/blacklist-ast.conf

# - IPMI modules #23929
echo 'install ipmi_ssif /bin/true' > /etc/modprobe.d/ipmi_ssif.conf
echo 'install ipmi_si /bin/true' > /etc/modprobe.d/ipmi_si.conf
echo 'install ipmi_devintf /bin/true' > /etc/modprobe.d/ipmi_devintf.conf

echo 'blacklist ipmi_msghandler' > /etc/modprobe.d/ipmi_msghandler.conf
echo 'install ipmi_msghandler /bin/true' >> /etc/modprobe.d/ipmi_msghandler.conf

chown root:root /etc/modprobe.d/ipmi_*.conf
chmod 644 /etc/modprobe.d/ipmi_*.conf

update-initramfs -u

# -----------------------------

# block ssh port
echo "y" | ufw enable
ufw deny 22

# configure networking
python3 /opt/ethcon/ethcon.py write_default
rm -f /var/lib/dhcp/*.leases
echo "" > /etc/resolv.conf

# install ethcon
cp /opt/ethcon/ethcon.service /etc/systemd/system/
/bin/systemctl enable ethcon.service

# reset the root password to blank, so as to prevent the default root password from being used. this will be reset on launch.
echo "root:*" | chpasswd -e

# Use Ubuntu Defaults
echo 'APT::Install-Suggests "1";' > /etc/apt/apt.conf.d/99Recommended:
echo 'APT::Install-Recommends "1";' > /etc/apt/apt.conf.d/99Recommended:

# Disable this, they can enable if they want it, errors on first boot
systemctl disable apt-daily.service
systemctl disable apt-daily.timer

# wipe logs
rm -f /root/update.txt
rm -f /root/upgrade.txt
echo "" > /var/log/auth.log

# update mlocate db
/usr/bin/updatedb

# wipe random seed files
rm -f /var/lib/systemd/random-seed

# wipe machine id, systemd refuses to boot without this file ( https://bbs.archlinux.org/viewtopic.php?id=156651 )
rm -f /etc/machine-id
touch /etc/machine-id
