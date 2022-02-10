#!/bin/bash

test=$(cat /etc/sudoers | grep timestamp_timeout=)
timeout_duration=$(cat /etc/sudoers | grep timestamp_timeout= | awk '{print $2}' | cut -d'=' -f 2)

if [ ! "$test" ]; then 
	cp /etc/sudoers /etc/sudoers.bak
	echo $'\n\n# Always ask for sudo password #CHANGES# \nDefaults    timestamp_timeout=0' >> /etc/sudoers	
elif [ $timeout_duration -ne 0 ]; then
	sed -i.bak 's/timestamp_timeout=.*/timestamp_timeout=0/' /etc/sudoers
fi



