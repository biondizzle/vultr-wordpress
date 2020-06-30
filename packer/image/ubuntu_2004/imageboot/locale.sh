#!/bin/bash

echo "Imageboot: Updating locale" | logger -s

locale-gen en_US.UTF-8
update-locale en_US.UTF-8
echo "LANG=\"en_US.UTF-8\"" > /etc/default/locale
