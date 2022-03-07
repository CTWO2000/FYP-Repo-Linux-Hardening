#!/bin/bash


limit_core_soft=$(cat /etc/security/limits.conf | grep -P "\* soft core 0") 
limit_core_hard=$(cat /etc/security/limits.conf | grep -P "\* hard core 0") 
sysctl_core=$(cat /etc/sysctl.conf| grep -P "fs.suid_dumpable=0") 

if [ ! "$limit_core_soft" ]; then
	echo -e "\n#Disable Coredump\n* soft core 0" >> /etc/security/limits.conf
fi

if [ ! "$limit_core_hard" ]; then
	echo -e "\n#Disable Coredump\n* hard core 0" >> /etc/security/limits.conf
fi


if [ ! "$sysctl_core" ]; then
	cp /etc/sysctl.conf /etc/sysctl.conf.bak
	echo -e "\n#Disable Coredump\nfs.suid_dumpable=0" >> /etc/sysctl.conf

	sysctl -p
fi 


