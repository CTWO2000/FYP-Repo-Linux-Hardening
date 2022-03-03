#!/bin/bash

apt -y install fail2ban 2>/dev/null | dialog --programbox "Installing Fail2Ban" 20 70

ssh_port=$(cat /etc/ssh/sshd_config | grep "Port " | awk '{print $2}')

if [ ! -f "/etc/fail2ban/jail.local" ]; then
	touch /etc/fail2ban/jail.local
	echo -e "[sshd]\nport = $ssh_port\nfilter = sshd\nlogpath = /var/log/auth.log\nmaxretry = 3\nbantime = 60\n" >> /etc/fail2ban/jail.local
    
else
	mv /etc/fail2ban/jail.local /etc/fail2ban/jail.local.bak
	touch /etc/fail2ban/jail.local
	echo -e "[sshd]\nport = $ssh_port\nfilter = sshd\nlogpath = /var/log/auth.log\nmaxretry = 3\nbantime = 60\n" >> /etc/fail2ban/jail.local
fi

systemctl restart fail2ban

