#!/bin/bash

# Check if telnet server is installed 

if $(systemctl status inetd >/dev/null 2>&1); then
	echo "Telnet Server Installed"
	telnet_server=1
else
	echo "Telnet Server not Installed"
	telnet_server=0
fi

if [ $telnet_server -eq 1 ]; then
	
	apt purge telnetd -y
	apt autoremove -y

fi
