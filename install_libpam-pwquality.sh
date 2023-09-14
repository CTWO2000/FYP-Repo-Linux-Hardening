#!/bin/bash

apt -y install libpam-pwquality 2>/dev/null | dialog --programbox "Installing libpam-pwquality for password complexity" 20 70


pwquality=$(cat /etc/pam.d/common-password | grep password | grep requisite | grep pam_pwquality.so)

if [ ! "$pwquality" ]; then 
	dialog --title "Missing pam_pwquality.so"  --msgbox "pam_pwquality.so Not Installed" 10 65	
else
	sed -i.bak 's/pam_pwquality.so .*/pam_pwquality.so retry=1 minlen=8 difok=4 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 reject_username enforce_for_root/' /etc/pam.d/common-password
fi


