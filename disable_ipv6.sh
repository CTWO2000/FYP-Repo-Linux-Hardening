#!/bin/bash

sed -i.bak 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash ipv6.disable=1"/' /etc/default/grub
sed -i.bak 's/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="ipv6.disable=1"/' /etc/default/grub

# Redirect stderr to stdout for dialog
update-grub 2>&1 | dialog --programbox 12 70


