#!/bin/bash

username=fyp

umask=$(cat /etc/bash.bashrc | grep -P "umask\t")
umask_value=$(cat /etc/bash.bashrc | grep -P "umask\t" | awk '{print $2}')

if [ ! "$umask" ]; then 
	cp /etc/bash.bashrc /etc/bash.bashrc.bak
	echo $'\n\n# Change Default Umask Value (Personal) \numask\t077' >> /etc/bash.bashrc	
elif [ $umask_value -ne 0077 ] || [ $umask_value -ne 077 ]; then
	sed -i.bak 's/umask\t.*/umask\t077/' /etc/bash.bashrc
fi


# Change Default Umask Value (Personal)
# umask	0077
