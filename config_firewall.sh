#!/bin/bash

ufw status | grep -qw active
ufw_status=$?

if [ $ufw_status -eq 0 ]; then
	echo "firewall enabled"
else
	echo "firewall disabled"
#	ufw default deny incoming
#	ufw default allow outgoing
#	ufw allow ssh
#	ufw allow http
#	ufw allow https 
#	ufw allow ftp
#	ufw allow telnet
fi

#if [ $ufw_status -eq 1 ]; then
#	ufw default deny incoming
#	ufw default allow outgoing
#fi

#if [ $ufw_status -eq 1 ] && [ $ssh_server -eq 1 ]; then
#	ufw allow ssh
#fi

