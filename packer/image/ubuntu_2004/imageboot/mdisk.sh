#!/bin/bash

# list block devices
BLOCKDEV_LIST=`lsblk -da | grep disk | grep -v ram | grep -v loop | awk '{print $1}'`
MOUNT_NUM=1

for BLOCKDEV in $BLOCKDEV_LIST; do
	# skip primary disks
	if [ "$BLOCKDEV" == "sda" ] || [ "$BLOCKDEV" == "vda" ]; then
		continue
	fi

	echo "Imageboot: Formatting ${BLOCKDEV}..." | logger -s
	echo ${BLOCKDEV}

	# check for fstab entries
	FSTAB_COUNT=`cat /etc/fstab | grep $BLOCKDEV | wc -l`

	if [ $FSTAB_COUNT -gt 0 ]; then
		echo "$FSTAB_COUNT fstab entry(s) detected, ignoring disk."
		continue;
	fi

	# format disk
	echo 'Writing partition...'

	(
	echo o # create a new empty DOS partition table
	echo n # add a new partition
	echo p # primary partition
	echo 1 # partition number
	echo   # first sector (accept default: 2048)
	echo   # last sector (accept default: varies)
	echo w # write changes
	) | fdisk -c -u /dev/${BLOCKDEV}

	if [ "$?" != "0" ]; then
		echo "Partitioning failed."
		continue;
	fi

	echo 'Setting up filesystem...'
	mkfs.ext4 /dev/${BLOCKDEV}1

	if [ "$?" != "0" ]; then
		echo "Filesystem setup failed."
		continue;
	fi

	echo "Mounting filesystem..."

	MOUNT_POINT="/data"
	if [ $MOUNT_NUM -gt 1 ]; then
		MOUNT_POINT="/data$MOUNT_NUM"
	fi
	MOUNT_NUM=$((MOUNT_NUM + 1))

	mkdir $MOUNT_POINT
	echo "/dev/${BLOCKDEV}1 ${MOUNT_POINT} ext4 defaults 0 0" >> /etc/fstab
	mount $MOUNT_POINT
	if [ "$?" != "0" ]; then
		echo "Mount failed."
		continue;
	fi

	echo "Done formatting ${BLOCKDEV}."

done


exit 0
