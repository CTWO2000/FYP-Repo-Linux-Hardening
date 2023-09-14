#!/bin/bash

username=fyp

umask=$(cat /home/$username/.bashrc | grep -P "umask\t")
umask_value=$(cat /home/$username/.bashrc | grep -P "umask\t" | awk '{print $2}')

if [ ! "$umask" ]; then 
	cp /home/$username/.bashrc /home/$username/.bashrc.bak
	echo $'\n\n# Change Default Umask Value (Personal) \numask\t077' >> /home/$username/.bashrc	
elif [ $umask_value -ne 0077 ] || [ $umask_value -ne 077 ]; then
	sed -i.bak 's/umask\t.*/umask\t077/' /home/$username/.bashrc
fi


# Change Default Umask Value (Personal)
# umask	0077
