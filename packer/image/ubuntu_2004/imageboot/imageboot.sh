#!/bin/bash

# run steps
env
mkdir -p /opt/imageboot/state/

# remove provisioning artifacts
rm -f /tmp/script.sh

# disk setup (requires metadata)
if [ ! -f /opt/imageboot/state/mdisk ]; then
	bash /opt/imageboot/mdisk.sh >>/var/log/imageboot.log 2>&1
	touch /opt/imageboot/state/mdisk
	rm -f /opt/imageboot/mdisk.sh
fi

# hostname
if [ ! -f /opt/imageboot/state/hostname ]; then
	bash /opt/imageboot/hostname.sh >>/var/log/imageboot.log 2>&1
	touch /opt/imageboot/state/hostname
	rm -f /opt/imageboot/hostname.sh
fi

# locale
if [ ! -f /opt/imageboot/state/locale ]; then
	bash /opt/imageboot/locale.sh >>/var/log/imageboot.log 2>&1
	touch /opt/imageboot/state/locale
	rm -f /opt/imageboot/locale.sh
fi

# unblock ssh port
if [ ! -f /opt/imageboot/state/unblock_ssh ]; then
	echo "y" | ufw delete 1
	echo "y" | ufw delete 1
	ufw disable
	touch /opt/imageboot/state/unblock_ssh
fi

# uninstall
/bin/systemctl disable imageboot.service
rm -f /etc/systemd/system/imageboot.service

rm -rf /opt/imageboot/
