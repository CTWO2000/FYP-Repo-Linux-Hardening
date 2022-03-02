#!/bin/bash



sed -i 's/#AllowTcpForwarding .*/AllowTcpForwarding no/' /etc/ssh/sshd_config /
sed -i 's/#ClientAliveCountMax .*/ClientAliveCountMax 2/' /etc/ssh/sshd_config /
sed -i 's/#Compression .*/Compression no/' /etc/ssh/sshd_config /
sed -i 's/#LogLevel .*/LogLevel VERBOSE/' /etc/ssh/sshd_config /
sed -i 's/#MaxAuthTries .*/MaxAuthTries 3/' /etc/ssh/sshd_config /
sed -i 's/#MaxSessions .*/MaxSessions 2/' /etc/ssh/sshd_config /
sed -i 's/#TCPKeepAlive .*/TCPKeepAlive no/' /etc/ssh/sshd_config 
sed -i 's/#AllowAgentForwarding .*/AllowAgentForwarding no/' /etc/ssh/sshd_config /
sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config /

sed -i 's/#AddressFamily .*/AddressFamily inet/' /etc/ssh/sshd_config /
sed -i 's/#PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config /
sed -i 's/#Port .*/Port 5000/' /etc/ssh/sshd_config /



#Get User input for the port number and ensure that the user input is an integer
#while [ $valid_port -eq 0 ]
#do
#	exec 3>&1
#	ssh_port=$(dialog --inputbox "Enter SSH Port Number (Default: 22)" 0 0 2>&1 1>&3) 
#	exit_status=$? 
#	exec 3>&- 
		
#	if [[ $ssh_port ]] && [ $ssh_port -eq $ssh_port 2>/dev/null ]; then
#		valid_port=1
#	else
#		dialog --title "Invalid Port"  --msgbox "Please enter a number for the port." 10 65
#	fi
#done




#PermitRootLogin
#Port 
# X11Forwarding yes

#AllowTcpForwarding NO
#ClientAliveCountMax 2
#Compression (set YES to NO)
#LogLevel (set INFO to VERBOSE)
#MaxAuthTries (set 6 to 3)
#MaxSessions (set 10 to 2)
#Port (set 22 to )
#TCPKeepAlive (set YES to NO)
#X11Forwarding (set YES to NO)
#AllowAgentForwarding (set YES to NO)



#AllowTcpForwarding 
#ClientAliveCountMax
#Compression
#LogLevel 
#MaxAuthTries
#MaxSessions 
#TCPKeepAlive
#AllowAgentForwarding
#AddressFamily any


