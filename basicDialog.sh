#!/bin/bash

# Reference
# https://askubuntu.com/questions/491509/how-to-get-dialog-box-input-directed-to-a-variable

# "--yesno uses the exit status"
# "0" is yes
# "1" is no
dialog --yesno "Input Username?" 0 0

# "$?" get the previous exit status
exit_status=$?

case $exit_status in
	0) exec 3>&1 
	   name=$(dialog --inputbox "Username?" 0 0 2>&1 1>&3) 
	   exit_status=$? 
	   exec 3>&-   ;;

	1) echo no 
esac

# variable can be use as condition
if [ ! $name ]; then
	echo $name
else
	echo "test"
fi

