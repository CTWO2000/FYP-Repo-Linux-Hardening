#!/bin/bash

update=$(cat /etc/apt/apt.conf.d/20auto-upgrades | grep Update-Package-Lists | awk '{print $2}' | cut -d'"' -f 2)

if [ $update -ne 1 ]; then 
	sed -i.bak 's/APT::Periodic::Update-Package-Lists .*/APT::Periodic::Update-Package-Lists "1";/' /etc/apt/apt.conf.d/20auto-upgrades
fi

