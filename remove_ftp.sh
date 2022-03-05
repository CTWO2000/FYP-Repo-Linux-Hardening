#!/bin/bash

# Check if ftp server is installed 

if $(systemctl status vsftpd >/dev/null 2>&1); then
	echo "ftp Server Installed"
	ftp_server=1
else
	echo "ftp Server not Installed"
	ftp_server=0
fi

if [ $ftp_server -eq 1 ]; then
	
	apt purge vsftpd -y
	apt autoremove -y

fi
