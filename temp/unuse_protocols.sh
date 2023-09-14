#!/bin/bash


if [ ! -f "/etc/modprobe.d/unuse_protocol.conf" ]; then
	touch /etc/modprobe.d/unuse_protocol.conf
	echo -e "install dccp /bin/true\ninstall sctp /bin/true\ninstall rds /bin/true\ninstall tipc /bin/true" >> /etc/modprobe.d/unuse_protocol.conf
fi


#install dccp /bin/true
#install sctp /bin/true
#install rds /bin/true
#install tipc /bin/true
