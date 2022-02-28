#!/bin/bash


# apt install libpam-cracklib | dialog --programbox 12 70

#change_password() {
#
#	exec 3>&1 
#	new_password=$(dialog --insecure --passwordbox "Enter your new password" 0 0 2>&1 1>&3) 
#	exit_status=$? 
#	exec 3>&- 

#	exec 3>&1 
#	confirm_password=$(dialog --insecure --passwordbox "Confirm password" 0 0 2>&1 1>&3) 
#	exit_status=$? 
#	exec 3>&- 
	
#	echo -e "$new_password\n$confirm_password" | passwd fyp

#	if [ $? -ne 0 ]; then
#		password_loop=0
#	else
#		password_loop=1
#	fi
#}


#password_loop=0

#while [ $password_loop -eq 0 ]
#do
#	change_password
#done


exec 3>&1 
new_password=$(dialog --insecure --passwordbox "Enter your new password" 0 0 2>&1 1>&3) 
exit_status=$? 
exec 3>&- 

echo $exit_status






