#!/bin/bash

systemctl is-active --quiet apparmor
service_status=$?

if [ $service_status -ne  0 ]; then
	systemctl start apparmor 
fi

apt install apparmor-profiles apparmor-utils 
aa-enforce /etc/apparmor.d/* 
