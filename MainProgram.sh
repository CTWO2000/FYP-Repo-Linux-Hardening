#!/bin/bash

# If user does not have root privilege, close the program. 
if [[ $EUID -ne 0 ]]; then
   echo "This program must be run with an account with root privilege (sudo privilege)" 
   exit 1
fi

apt -y update

# Install Dialog if not installed 
command -v "dialog" >/dev/null 2>&1

if [[ $? -ne 0 ]]; then
	apt -y install dialog 
fi


# Get username and check if the username exist
check_user(){
	exec 3>&1 
	username=$(dialog --inputbox "Enter Username" 0 0 2>&1 1>&3) 
	exit_status=$? 
	exec 3>&-   
	
	if [ $exit_status -eq 1 ]; then
		exit 0
	fi

	if [ ! "$username" ]; then
		checkUser=0
		dialog --title "Invalid Username"  --msgbox "Please enter a username" 10 65
	elif [ "$username" = "root" ]; then
		checkUser=0
		dialog --title "Root Account"  --msgbox "Please do not use root account as the main account.  \
							  It poses a huge security risk as anyone that have access \
							  to the device would be able to execute/run any programs/tasks \
							  without any authentication." 10 65	
	elif id $username >/dev/null 2>&1; then
		# User Exist
		checkUser=1
	else
		# User Does Not Exist
		checkUser=0
		dialog --title "Invalid Username"  --msgbox "Entered username ($username) does not exist " 10 65
	fi
}

checkUser=0

while [ $checkUser -eq 0 ]
do
	check_user
done

# Check if sshd/ssh server is installed 
if $(systemctl status sshd >/dev/null 2>&1); then
	# echo "ssh Server Installed"
	ssh_server=1
else
	# echo "ssh Server Installed"
	ssh_server=0
fi

# Check if ftp server is installed 
if $(systemctl status vsftpd >/dev/null 2>&1); then
	# echo "ftp Server Installed"
	ftp_server=1
else
	# echo "ftp Server not Installed"
	ftp_server=0
fi

# Check if telnet server is installed 
if $(systemctl status inetd >/dev/null 2>&1); then
	# echo "telnet Server Installed"
	telnet_server=1
else
	# echo "telnet Server Installed"
	telnet_server=0
fi



# Check if ufw is active, if its active, don't configure.
ufw status | grep -qw active
ufw_status=$?


# Configuration Functions
#/=====================================================================================================================================================================/
# Configure Apparmor
configure_apparmor() {
	apt install -y apparmor-profiles apparmor-utils 2>/dev/null | dialog --programbox "Installing AppArmor Profiles" 20 70
	aa-enforce /etc/apparmor.d/* | dialog --programbox "Enforcing AppArmor Profiles (Output would take awhile show up)" 20 70
}
#/=====================================================================================================================================================================/
# Enable AppArmor
enable_apparmor() {
	systemctl start apparmor | dialog --programbox "Starting AppArmor (No Output)" 20 70
	systemctl enable apparmor 2>&1 | dialog --programbox "Enabling AppArmor on Start Up" 20 70
}
#/=====================================================================================================================================================================/
# Check if AppArmor is enabled
check_apparmor() {
	systemctl is-active --quiet apparmor
	service_status=$?

	if [ $service_status -ne  0 ]; then
		apparmor_status=0
	else 
		apparmor_status=1
	fi
}
#/=====================================================================================================================================================================/
# Install Clamav
install_clamav() {
	sudo apt -y install clamav 2>/dev/null | dialog --programbox "Installing Clamav Antivirus" 20 70
	sudo apt -y install clamtk 2>/dev/null | dialog --programbox "Installing Clamav Antivirus GUI (Graphical User Interface)" 20 70
	clamav_installed=1
}
#/=====================================================================================================================================================================/
# Check if clamav is installed 
check_clamav() {
	command -v "clamtk" >/dev/null 2>&1

	if [[ $? -ne 0 ]]; then
		clamav_installed=0
	else 
		clamav_installed=1
	fi
}
#/=====================================================================================================================================================================/
# User's Home directory permission
home_directory() {
	chmod 700 /home/$username
}

#/=====================================================================================================================================================================/
# Harden Compiler (Only sudo/root is able to use compiler)
harden_compiler() {
	chmod 700 /usr/bin/as
	chmod 700 /usr/bin/gcc
	chmod 700 /usr/bin/g++
	chmod 700 /usr/bin/cc
}

#/=====================================================================================================================================================================/
# Disabling Unused Protocols such as dccp, rds, tipc and sctp
unused_protocols() {
	if [ ! -f "/etc/modprobe.d/unuse_protocol.conf" ]; then
		touch /etc/modprobe.d/unuse_protocol.conf
		echo -e "install dccp /bin/true\ninstall sctp /bin/true\ninstall rds /bin/true\ninstall tipc /bin/true" >> /etc/modprobe.d/unuse_protocol.conf
	fi
}

#/=====================================================================================================================================================================/
# Disable Coredump
disable_coredump() {
	limit_core_soft=$(cat /etc/security/limits.conf | grep -P "\* soft core 0") 
	limit_core_hard=$(cat /etc/security/limits.conf | grep -P "\* hard core 0") 
	sysctl_core=$(cat /etc/sysctl.conf| grep -P "fs.suid_dumpable=0") 

	if [ ! "$limit_core_soft" ]; then
		echo -e "\n#Disable Coredump\n* soft core 0" >> /etc/security/limits.conf
	fi

	if [ ! "$limit_core_hard" ]; then
		echo -e "\n#Disable Coredump\n* hard core 0" >> /etc/security/limits.conf
	fi


	if [ ! "$sysctl_core" ]; then
		cp /etc/sysctl.conf /etc/sysctl.conf.bak
		echo -e "\n#Disable Coredump\nfs.suid_dumpable=0" >> /etc/sysctl.conf

		sysctl -p | dialog --programbox "Disabling Core Dump" 20 70
	fi 
}


#/=====================================================================================================================================================================/
# Install UFW GUI
install_gufw() {
	apt install gufw -y 2>/dev/null | dialog --programbox "Install GUFW (UFW Graphical User Interface)" 20 70
}

#/=====================================================================================================================================================================/
# Check if GUFW is installed
check_gufw () {
	# Install GUFW if not installed 
	command -v "gufw" >/dev/null 2>&1

	if [[ $? -ne 0 ]]; then
		gufw_installed=0
	fi
}

#/=====================================================================================================================================================================/
# Enable UFW
enable_ufw() {
	ufw enable
}

#/=====================================================================================================================================================================/
# UFW allow Telnet
ufw_allow_telnet() {
	ufw allow telnet
}

#/=====================================================================================================================================================================/
# UFW allow FTP
ufw_allow_ftp() {
	ufw allow ftp
}

#/=====================================================================================================================================================================/
# UFW allow https
ufw_allow_https() {
	ufw allow https
}

#/=====================================================================================================================================================================/
# UFW allow http
ufw_allow_http() {
	ufw allow http
}

#/=====================================================================================================================================================================/
# UFW allow SSH
ufw_allow_ssh() {
	ssh_port_ufw=$(cat /etc/ssh/sshd_config | grep "Port " | awk '{print $2}')
	ufw allow $ssh_port_ufw
}

#/=====================================================================================================================================================================/
# Configure Default UFW policy
default_ufw() {
	ufw default deny incoming
	ufw default allow outgoing
}

#/=====================================================================================================================================================================/
# Remove FTP
remove_ftp() {
	apt purge vsftpd -y 2>/dev/null | dialog --programbox "Removing FTP Server" 20 70
	apt autoremove -y 2>/dev/null | dialog --programbox "Removing FTP Server" 20 70
	ftp_server=0
}

#/=====================================================================================================================================================================/
# Remove telnet
remove_telnet() {
	apt purge telnetd -y 2>/dev/null | dialog --programbox "Removing Telnet Server" 20 70
	apt autoremove -y 2>/dev/null | dialog --programbox "Removing Telnet Server" 20 70
	telnet_server=0
}

#/=====================================================================================================================================================================/
# Install and Configure Fail2Ban
fail_2_ban() {
	apt -y install fail2ban 2>/dev/null | dialog --programbox "Installing Fail2Ban" 20 70

	ssh_port=$(cat /etc/ssh/sshd_config | grep "Port " | awk '{print $2}')
	
	# check if "jail.local" file already exist
	# if it does create a backup file before creating a new file
	# NOTE: If SSH log is VERBOSE, each fail attempts will be counted as 2
	if [ ! -f "/etc/fail2ban/jail.local" ]; then
		touch /etc/fail2ban/jail.local
		echo -e "[sshd]\nport = $ssh_port\nfilter = sshd\nlogpath = /var/log/auth.log\nmaxretry = 3\nbantime = 3600\n" >> /etc/fail2ban/jail.local
	    
	else
		mv /etc/fail2ban/jail.local /etc/fail2ban/jail.local.bak
		touch /etc/fail2ban/jail.local
		echo -e "[sshd]\nport = $ssh_port\nfilter = sshd\nlogpath = /var/log/auth.log\nmaxretry = 3\nbantime = 3600\n" >> /etc/fail2ban/jail.local
	fi

	systemctl restart fail2ban
}

#/=====================================================================================================================================================================/
# Change Default SSH port number
ssh_change_port() {
	
	valid_port=0
	
	while [ $valid_port -eq 0 ]
	do
		exec 3>&1
		ssh_port=$(dialog --inputbox "Enter SSH Port Number (Default: 22)" 0 0 2>&1 1>&3) 
		exit_status=$? 
		exec 3>&- 
		
		# Check if user input is a valid port number and not a string or empty 
		if [[ $ssh_port ]] && [ $ssh_port -eq $ssh_port 2>/dev/null ]; then
			valid_port=1
			
			sed -i "s/#Port .*/Port /" /etc/ssh/sshd_config 
			sed -i "s/Port .*/Port $ssh_port/" /etc/ssh/sshd_config 
			systemctl restart sshd
			
		elif [ $exit_status -eq 1 ]; then
			valid_port=1
		else
			dialog --title "Invalid Port"  --msgbox "Please enter a number for the port." 10 65
		fi
	done
	
}

#/=====================================================================================================================================================================/
# Disable IPv6 for SSH
 ssh_disable_ipv6() {
	sed -i 's/#AddressFamily .*/AddressFamily inet/' /etc/ssh/sshd_config 
	
	systemctl restart sshd
}
 
#/=====================================================================================================================================================================/
# Remove Root Login
ssh_no_root() {
	sed -i 's/#PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config 
	
	systemctl restart sshd
}

#/=====================================================================================================================================================================/
# General SSH Server Hardening
ssh_server_hardening() {
	sed -i.bak 's/#AllowTcpForwarding .*/AllowTcpForwarding no/' /etc/ssh/sshd_config 
	sed -i 's/#ClientAliveCountMax .*/ClientAliveCountMax 2/' /etc/ssh/sshd_config
	sed -i 's/#Compression .*/Compression no/' /etc/ssh/sshd_config 
	sed -i 's/#LogLevel .*/LogLevel VERBOSE/' /etc/ssh/sshd_config 
	sed -i 's/#MaxAuthTries .*/MaxAuthTries 3/' /etc/ssh/sshd_config 
	sed -i 's/#MaxSessions .*/MaxSessions 2/' /etc/ssh/sshd_config 
	sed -i 's/#TCPKeepAlive .*/TCPKeepAlive no/' /etc/ssh/sshd_config 
	sed -i 's/#AllowAgentForwarding .*/AllowAgentForwarding no/' /etc/ssh/sshd_config 
	sed -i 's/X11Forwarding yes/X11Forwarding no/' /etc/ssh/sshd_config 

	systemctl restart sshd
}

#/=====================================================================================================================================================================/
# Disable IPv6
disable_ipv6() {
	sed -i.bak 's/GRUB_CMDLINE_LINUX_DEFAULT=.*/GRUB_CMDLINE_LINUX_DEFAULT="quiet splash ipv6.disable=1"/' /etc/default/grub
	sed -i 's/GRUB_CMDLINE_LINUX=.*/GRUB_CMDLINE_LINUX="ipv6.disable=1"/' /etc/default/grub

	# Redirect stderr to stdout for dialog
	update-grub 2>&1 | dialog --programbox "Disabling IPv6" 12 70 
}

#/=====================================================================================================================================================================/
# Remove Root Login
no_root_login() {
	sed -i.bak 's/root:x:0:0:root:\/root:.*/root:x:0:0:root:\/root:\/sbin\/nologin/' /etc/passwd
}

#/=====================================================================================================================================================================/
# sudo Umask
sudo_umask() {
	sed -i.bak 's/UMASK\t\t.*/UMASK\t\t026 \n# Default "umask" value./' /etc/login.defs
}

#/=====================================================================================================================================================================/
# global Umask
global_umask() {
	umask=$(cat /etc/bash.bashrc | grep -P "umask\t")
	umask_value=$(cat /etc/bash.bashrc | grep -P "umask\t" | awk '{print $2}')

	if [ ! "$umask" ]; then 
		cp /etc/bash.bashrc /etc/bash.bashrc.bak
		echo $'\n\n# Change Default Umask Value (Personal) \numask\t077' >> /etc/bash.bashrc	
	elif [ $umask_value -ne 0077 ] || [ $umask_value -ne 077 ]; then
		sed -i.bak 's/umask\t.*/umask\t077/' /etc/bash.bashrc
	fi
}

#/=====================================================================================================================================================================/
# Configure Password Expiration (90 days)
password_expiration() {
	sed -i.bak 's/PASS_MAX_DAYS\t.*/PASS_MAX_DAYS\t90 \n# Maximum number of days a password may be used./' /etc/login.defs
	chage -M 90 $username
}

#/=====================================================================================================================================================================/
# Configure Password Change Frequency (1 day)
password_min() {
	sed -i.bak 's/PASS_MIN_DAYS\t.*/PASS_MIN_DAYS\t1 \n# Minimum number of days allowed between password changes./' /etc/login.defs
	chage -m 1 $username
}

#/=====================================================================================================================================================================/
# Install and Configure pam_pwquality.so
configure_pw_complexity() {
					# Redirect stderr to null
	apt -y install libpam-pwquality 2>/dev/null | dialog --programbox "Installing libpam-pwquality for password complexity" 20 70


	pwquality=$(cat /etc/pam.d/common-password | grep password | grep requisite | grep pam_pwquality.so)

	if [ ! "$pwquality" ]; then 
		dialog --title "Missing pam_pwquality.so"  --msgbox "pam_pwquality.so Not Installed" 10 65	
	else
		sed -i.bak 's/pam_pwquality.so .*/pam_pwquality.so retry=1 minlen=8 difok=4 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 reject_username enforce_for_root/' /etc/pam.d/common-password
		sed -i 's/pam_unix.so .*/pam_unix.so obscure use_authtok try_first_pass sha512 remember=3/' /etc/pam.d/common-password
	fi

}

#/=====================================================================================================================================================================/
# Change User's Password
change_password() {
	exec 3>&1 
	new_password=$(dialog --insecure --passwordbox "Enter your new password" 0 0 2>&1 1>&3) 
	exit_status=$? 
	exec 3>&- 

	exec 3>&1 
	confirm_password=$(dialog --insecure --passwordbox "Confirm password" 0 0 2>&1 1>&3) 
	exit_status=$? 
	exec 3>&- 
	
	
	
	$(echo -e "$new_password\n$confirm_password" | passwd $username)
	pass_status=$?
	
	# User cancel the password changing 
	if [ $exit_status -eq 1 ]; then
		password_loop=0
		# In the case where the password is changed even if the user cancels  
		if [ $pass_status -eq 0 ];then
			 dialog --title ""  --msgbox "Password Changed Successfully" 10 65
		fi
	# Pasword did not meet the requirements
	elif [ $pass_status -ne 0 ]; then
		password_loop=1
		dialog --title "Invalid Password"  --msgbox "Password Requirement: \
							      Minimum 8 characters, 1 Uppercase, 1 Lowercase, 1 Digit, 1 Symbol, No Re-use Password and No Username.
							      
							      If all the requirement is satisfied, means that the password is the new password and the confirm password is not the same or \
							      the password is too predictable and can be brute forced easily." 10 65
	# Successfully change the password
	else
		password_loop=0
		dialog --title ""  --msgbox "Password Changed Successfully" 10 65
	fi
}

#/=====================================================================================================================================================================/
# Enable Auto-Update
auto_update () {
	# Cut out the auto-update string 
	update=$(cat /etc/apt/apt.conf.d/20auto-upgrades | grep Update-Package-Lists | awk '{print $2}' | cut -d'"' -f 2)

	# if update is not equal to 1
	# Set auto-update to daily
	if [ $update -ne 1 ]; then 
		sed -i.bak 's/APT::Periodic::Update-Package-Lists .*/APT::Periodic::Update-Package-Lists "1";/' /etc/apt/apt.conf.d/20auto-upgrades
	fi
}

#/=====================================================================================================================================================================/

sudo_timeout () {
	timestamp_timeout=$(cat /etc/sudoers | grep timestamp_timeout=)
	timeout_duration=$(cat /etc/sudoers | grep timestamp_timeout= | awk '{print $2}' | cut -d'=' -f 2)

	if [ ! "$timestamp_timeout" ]; then 
		cp /etc/sudoers /etc/sudoers.bak
		echo $'\n\n# Always ask for sudo password \nDefaults    timestamp_timeout=0' >> /etc/sudoers	
	elif [ $timeout_duration -ne 0 ]; then
		sed -i.bak 's/timestamp_timeout=.*/timestamp_timeout=0/' /etc/sudoers
	fi
}

#/=====================================================================================================================================================================/

Back_Up_Config () {
	timeshift --create --comments "Backup with Program" | dialog --programbox "Backing Up Configuration (Would take quite awhile)" 12 70
}

#/=====================================================================================================================================================================/
# Install TimeShift
install_timeshift() {
	if [ $timeshift_installed -eq 0 ]; then
		exec 3>&1 
		First=$(dialog --cancel-label "Back" \
			       --menu "Install TimeShift (Highly Recommended)" 10 50 3 1 "Install" 2 Exit 2>&1 1>&3)
		exit_status=$? 
		exec 3>&-
		case $First in
			1) apt -y install timeshift 2>/dev/null | dialog --programbox "Installing TimeShift" 20 70;;
			2) quit_config=0
		esac
	fi
}
#/=====================================================================================================================================================================/

check_timeshift () {
	# Install Timeshift if not installed 
	command -v "timeshift" >/dev/null 2>&1

	if [[ $? -ne 0 ]]; then
		timeshift_installed=0
	fi
}


#/=====================================================================================================================================================================/
## Main Loop

while true 
do
	# HomePage Dialog Menu 
	exec 3>&1 
	homepage=$(dialog --cancel-label "Exit" \
		--menu "HomePage:" 10 55 3 1 Start 2 Description 3 "Back Up Configurations(Highly Recommended)" 2>&1 1>&3)
	exit_status=$? 
	exec 3>&-
	
	# Set exit/quit configuration variable
	quit_config=1
	
	# Exit the program
	if [ $exit_status -eq 1 ]; then
		exit 0
	fi
	
	case $homepage in
		1)	#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					# Configuration Dialog Menu
					exec 3>&1 
					First=$(dialog --cancel-label "Skip" \
					       --menu "Daily Auto-Update" 10 50 3 1 "Enable" 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $First in
						   # Enable Daily Update
						1) auto_update ;;

						   # Description Dialog
						2) dialog --title "Auto-Update Description"  --msgbox "This configuration would make sure that the updates is checked daily. \
											     This is to ensure that the system always stay up-to-date especially on security \
											     updates." 10 65 
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
					
					# Configuration Dialog Menu
					exec 3>&1 
					Second=$(dialog --cancel-label "Skip" \
						--menu "Sudo Timeout" 10 30 3 1 "Sudo Timeout" 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Second in
						   # Authenticate user each time sudo command is executed
						1) sudo_timeout ;;
						
						   # Description Dialog
						2) dialog --title "Sudo Timeout Description"  --msgbox "This will force the the user authenticate each time the 'sudo' command is executed.
													  By doing so it prevents potential attackers from running 'sudo' without authentication." 10 65 
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done
			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
				
					# Configuration Dialog Menu
					exec 3>&1 
					Third=$(dialog --cancel-label "Skip" \
						--menu "Configure Password Complexity" 10 40 3 1 Configure 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Third in
						   # change password Configuration
						1) configure_pw_complexity ;;
						
						   # Description Dialog
						2) dialog --title "Configure Password Complexity"  --msgbox "This will install libpam-pwquality in order to configure user password complexity.
						
													       The configuration will include: Minimum 8 characters, 1 Uppercase, 1 Lowercase, 1 Digit, \
													       1 Symbol, No Re-use Password (Remember up to 3 passwords) and No Username." 10 65
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
				
					# Configuration Dialog Menu
					exec 3>&1 
					fourth=$(dialog --cancel-label "Skip" \
						--menu "Change Password" 10 30 3 1 Change 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# Keep on prompting the user to enter new password if the password does not meet the requirements
					password_loop=1
					
					# User's Choice
					case $fourth in
						   # change password Configuration
						   # Keep on prompting the user to enter new password if the password does not meet the requirements
						1) while [ $password_loop -eq 1 ]
						   do
							change_password
						   done ;;
						   # Description Dialog
						2) dialog --title "Change Password"  --msgbox "This configuration simply changes the user's account password" 10 65
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
				
					# Configuration Dialog Menu
					exec 3>&1 
					Third=$(dialog --cancel-label "Skip" \
						--menu "Configure Password Expiration (90 days)" 10 45 3 1 Configure 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Third in
						   # Password Expires in 90 days
						1) password_expiration ;;
						
						   # Description Dialog
						2) dialog --title "Configure Password Expiration (90 days)"  --msgbox "This configuration forces users to change their password every 90 days. \
															  By doing so, it will be able to minimised the chance for someone to steal \
															  the user's password as it is changed frequently" 10 65 
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
				
					# Configuration Dialog Menu
					exec 3>&1 
					Third=$(dialog --cancel-label "Skip" \
						--menu "Password Change Frequency (Restrictive)" 10 45 3 1 Configure 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Third in
						   # User only able to change password once a day (Restrictive)
						1) password_min;;
						
						   # Description Dialog
						2) dialog --title "Password Change Frequency (Restrictive)"  --msgbox "This configuration can be quite restrictive as it only allow the users \
															  to change their password once a day. This is to prevent the user to re-use \
															  their password by keep on changing their password in order to go through the \
															  remembered password cycle." 10 65
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
				
					# Configuration Dialog Menu
					exec 3>&1 
					Third=$(dialog --cancel-label "Skip" \
						--menu "Configure Sudo Umask (Restrictive)" 10 45 3 1 Configure 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Third in
						   # Change sudo Umask to 026 (Restrictive) (Group: File (read), Directory (Read and Execute), Other: File (None), Directory (Execute))
						1) sudo_umask ;;
						
						   # Description Dialog
						2) dialog --title "Configure Sudo Umask (Restrictive)"  --msgbox "This configuration can be quite restrictive as any new file and directory created  \
														    by sudo can only be access with Root Priviledge ('# sudo <command>'). " 10 65 
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
				
					# Configuration Dialog Menu
					exec 3>&1 
					Third=$(dialog --cancel-label "Skip" \
						--menu "Configure Global Umask (Restrictive)" 10 45 3 1 Configure 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Third in
						   # Change Global Umask to 077
						1) global_umask ;;
						
						   # Description Dialog
						2) dialog --title "Configure Global Umask (Restrictive)"  --msgbox "With this configuration, any new file and directory created \
														      can only be access by the User and Root." 10 65 
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
				
					# Configuration Dialog Menu
					exec 3>&1 
					Third=$(dialog --cancel-label "Skip" \
						--menu "Remove Root Login" 10 45 3 1 Remove 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Third in
						   # Remove Root Login
						1) no_root_login ;;
						
						   # Description Dialog
						2) dialog --title "Remove Root Login"  --msgbox "With this configuration, the user would no longer be able to login as root. The 'sudo' command \
												   still works.
												   This is to prevent anyone to take advantage of the root account." 10 65 
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
				
					# Configuration Dialog Menu
					exec 3>&1 
					Third=$(dialog --cancel-label "Skip" \
						--menu "Disabling IPv6" 10 45 3 1 Disable 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Third in
						   # Completely Disable IPv6
						1) disable_ipv6 ;;
						
						   # Description Dialog
						2) dialog --title "Disabling IPv6"  --msgbox "This configuration would disable the IPv6 on the user's machine.
												As IPv6 is rarely used it is better to disable it in order to \
												reduce the surface of attack.
												
												NOTE: Disabling IPv6 would cause vsftpd (FTP server) to not work properly" 10 65 
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
					
					if [ $ssh_server -eq 1 ]; then
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "General SSH Server Hardening" 10 45 3 1 Enable 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # General SSH Server Hardening
							1) ssh_server_hardening ;;
							
							   # Description Dialog
							2) dialog --title "General SSH Server Hardening"  --msgbox "This configuration would Harden the SSH server." 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac
					else
						# Break the description dialog loop
						description_loop=0
					fi

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
					
					if [ $ssh_server -eq 1 ]; then
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Remove Root login for SSH" 10 45 3 1 Remove 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # Remove Root login for SSH
							1) ssh_no_root ;;
							
							   # Description Dialog
							2) dialog --title "Remove Root login for SSH"  --msgbox "SSH Client can no longer login as root. 
														   This is to prevent attackers from remote login \
														   to the root account." 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac
					else
						# Break the description dialog loop
						description_loop=0
					fi

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
					
					if [ $ssh_server -eq 1 ]; then
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Disable IPv6 for SSH" 10 45 3 1 Disable 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # Remove IPv6for SSH
							1) ssh_disable_ipv6 ;;
							
							   # Description Dialog
							2) dialog --title "Disable IPv6 for SSH"  --msgbox "SSH client can no longer connect to SSH server via IPv6.
													     As SSH is rarely used, disabling IPv6 reduces the surface of attack." 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac
					else
						# Break the description dialog loop
						description_loop=0
					fi

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
					
					if [ $ssh_server -eq 1 ]; then
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Change Default SSH Port Number (Port 22)" 10 45 3 1 Change 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # Change default SSH port
							1) ssh_change_port ;;
							
							   # Description Dialog
							2) dialog --title "Change Default SSH Port Number (Port 22)"  --msgbox "This configuration would allow the user to \
																   change the default SSH port number to prevent \
																   spam bot from attacking the default SSH port" 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac
					else
						# Break the description dialog loop
						description_loop=0
					fi

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
					
					if [ $ssh_server -eq 1 ]; then
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Install and Configure Fail2Ban" 10 45 3 1 "Install and Configure" 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # Install and Configure Fail2Ban
							1) fail_2_ban ;;
							
							   # Description Dialog
							2) dialog --title "Install and Configure Fail2Ban"  --msgbox "Fail2Ban is a tool to either permanently or temporarily ban/block \
															ip addresses that tries to brute forces remote connections. \
															For this configuration, the Fail2Ban will ban/block any ip address \
															for 1 hours after 2-3 login attempts." 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac
					else
						# Break the description dialog loop
						description_loop=0
					fi

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
					
					if [ $telnet_server -eq 1 ]; then
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Uninstall Telnet Server" 10 45 3 1 Uninstall 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # Uninstall Telnet Server
							1) remove_telnet ;;
							
							   # Description Dialog
							2) dialog --title "Uninstall Telnet Server"  --msgbox "Telnet is a very insecure protocol as messages are not encrypted. \
														 Use SSH as an alternative." 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac
					else
						# Break the description dialog loop
						description_loop=0
					fi

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
					
					if [ $ftp_server -eq 1 ]; then
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Uninstall FTP Server" 10 45 3 1 Uninstall 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # Uninstall FTP Server
							1) remove_ftp ;;
							
							   # Description Dialog
							2) dialog --title "Uninstall FTP Server"  --msgbox "FTP is a very insecure protocol as messages are not encrypted. \
													      Use SCP (SSH file transfer) as an alternative." 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac
					else
						# Break the description dialog loop
						description_loop=0
					fi

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
					
					if [ $ufw_status -eq 0 ]; then
						dialog --title "UFW Firewall"  --msgbox "It seems that UFW firewall is already configured. \
											  Therefore, the UWF firewall configuration would not \
											  be implemented." 10 65
						# Break the description dialog loop
						description_loop=0
					elif [ $ufw_status -eq 1 ]; then
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Configure Default UFW Policy/Behaviour" 10 45 3 1 Configure 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # Set the default outgoing and incoming firewall
							1) default_ufw ;;
							
							   # Description Dialog
							2) dialog --title "Configure Default UFW Policy/Behaviour"  --msgbox "By default, UFW firewall would allow all outgoing traffic \
																 and deny all incoming traffic" 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac
					else
						# Break the description dialog loop
						description_loop=0
					fi

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
					
					if [ $ufw_status -eq 1 ] && [ $ssh_server -eq 1 ]; then
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Firewall Allow incoming SSH Connection" 10 45 3 1 Allow 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # Allow SSH throught the firewall
							1) ufw_allow_ssh ;;
							
							   # Description Dialog
							2) dialog --title "Firewall Allow incoming SSH Connection"  --msgbox "This configuration will allow remote devices to connect \
																to the User's device via SSH" 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac
					else
						# Break the description dialog loop
						description_loop=0
					fi

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
					
					if [ $ufw_status -eq 1 ] && [ $ftp_server -eq 1 ]; then
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Firewall Allow incoming FTP Connection (Not Recommended)" 12 45 3 1 Allow 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # Allow FTP throught the firewall
							1) ufw_allow_ftp ;;
							
							   # Description Dialog
							2) dialog --title "Firewall Allow incoming FTP Connection (Not Recommended)"  --msgbox "This configuration will allow remote devices \
																		   to connect to the User's device via FTP.
																		   
																		   This is not recommended as FTP is a very insecure \
																		   protocol as messages are not encrypted." 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac
					else
						# Break the description dialog loop
						description_loop=0
					fi

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
					
					if [ $ufw_status -eq 1 ] && [ $telnet_server -eq 1 ]; then
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Firewall Allow incoming Telnet Connection (Not Recommended)" 12 45 3 1 Allow 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # Allow Telnet throught the firewall
							1) ufw_allow_telnet ;;
							
							   # Description Dialog
							2) dialog --title "Firewall Allow incoming Telnet Connection (Not Recommended)"  --msgbox "This configuration will allow remote devices \
																		   to connect to the User's device via Telnet.
																		   
																		   This is not recommended as Telnet is a very insecure \
																		   protocol as messages are not encrypted." 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac
					else
						# Break the description dialog loop
						description_loop=0
					fi

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
					
					if [ $ufw_status -eq 1 ] ; then
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Firewall Allow incoming HTTP Connection (For Hosting Website)" 12 45 3 1 Allow 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # Allow HTTP throught the firewall
							1) ufw_allow_http ;;
							
							   # Description Dialog
							2) dialog --title "Firewall Allow incoming HTTP Connection (For Hosting Website)"  --msgbox "This configuration is only applicable for Users\
																			who are hosting website on port 80 (http)" 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac
					else
						# Break the description dialog loop
						description_loop=0
					fi

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
					
					if [ $ufw_status -eq 1 ] ; then
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Firewall Allow incoming HTTPS Connection (For Hosting Website)" 12 45 3 1 Allow 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # Allow HTTPS throught the firewall
							1) ufw_allow_https ;;
							
							   # Description Dialog
							2) dialog --title "Firewall Allow incoming HTTPS Connection (For Hosting Website)"  --msgbox "This configuration is only applicable for Users\
																			who are hosting website on port 443 (https)" 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac
					else
						# Break the description dialog loop
						description_loop=0
					fi

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
					
					if [ $ufw_status -eq 1 ] ; then
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Enable UFW Firewall" 10 45 3 1 Enable 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # Enable UFW Firewall
							1) enable_ufw ;;
							
							   # Description Dialog
							2) dialog --title "Enable UFW Firewall"  --msgbox "This configuration would enable UFW Firewall." 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac
					else
						# Break the description dialog loop
						description_loop=0
					fi

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				
				check_gufw
				if [ $gufw_installed -eq 0 ]; then
					description_loop=1
					while [ $description_loop -eq 1 ]
					do
						# Skip this configuration (Returning to HomePage)
						if [ $quit_config -eq 0 ]; then
							break
						fi
						
						# Configuration Dialog Menu
						exec 3>&1 
						Second=$(dialog --cancel-label "Skip" \
							--menu "Install GUFW (UFW Graphical User Interface)" 12 45 3 1 Install 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Second in
							   # Install GUFW
							1) install_gufw ;;
							
							   # Description Dialog
							2) dialog --title "Install GUFW (UFW Graphical User Interface)"  --msgbox "This will install a UFW Graphical User Interface application." 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac

					done
				fi
			#/================================================================================================/
				
				if [ $quit_config -eq 1 ]; then
					dialog --title "GUFW (UFW Graphical User Interface)"  --msgbox "To reconfigure the UFW firewall, search/install for GUFW for the UFW Graphical User \
											  Interface Application" 10 65 
				fi 
			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
				
					# Configuration Dialog Menu
					exec 3>&1 
					Third=$(dialog --cancel-label "Skip" \
						--menu "Disabling Core Dump" 10 45 3 1 Disable 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Third in
						   # Disabling Core Dumps
						1) disable_coredump ;;
						
						   # Description Dialog
						2) dialog --title "Disabling Core Dump"  --msgbox "Core Dumps are are usually used by developers for troubleshooting \
												     if it is not used, it is better to disable it as the cored dumps could \
										      		     contain sensitive information." 10 65 
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
				
					# Configuration Dialog Menu
					exec 3>&1 
					Third=$(dialog --cancel-label "Skip" \
						--menu "Disabling DCCP, RDS, TIPC and SCTP Protocols" 12 45 3 1 Disable 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Third in
						   # Disable DCCP, RDS, TIPC and SCTP Protocols
						1) unused_protocols ;;
						
						   # Description Dialog
						2) dialog --title "Disabling DCCP, RDS, TIPC and SCTP Protocols"  --msgbox "These protocols are not used often, hence, it is recommended to \
												     			       disable it in order to reduce the surface of attack." 10 65 
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
				
					# Configuration Dialog Menu
					exec 3>&1 
					Third=$(dialog --cancel-label "Skip" \
						--menu "Hardening Compiler (GCC, G++, CC and AS)" 10 45 3 1 Configure 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Third in
						   # Hardening Default compilers
						1) harden_compiler ;;
						
						   # Description Dialog
						2) dialog --title "Hardening Compiler (GCC, G++, CC and AS)"  --msgbox "This configuration would ensure that the compilers (GCC, G++, CC and AS) \
														  	   can only be executed with root/sudo provilege. This is to prevent \
														  	   attacker to compile malicious code within the user's machine." 10 65 
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done 

			#/================================================================================================/
				# Allow the description dialog to loop back to its configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					
					# Skip this configuration (Returning to HomePage)
					if [ $quit_config -eq 0 ]; then
						break
					fi
				
					# Configuration Dialog Menu
					exec 3>&1 
					Third=$(dialog --cancel-label "Skip" \
						--menu "Harden Home Directory Permission" 10 45 3 1 Enable 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Third in
						   # Change user's home directory permission to 700 
						1) home_directory ;;
						
						   # Description Dialog
						2) dialog --title "Harden Home Directory Permission"  --msgbox "This configuration ensure that only user is able to access \
														   his/her home directory." 10 65 
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done 

			#/================================================================================================/
				check_clamav
				if [ $clamav_installed -eq 0 ]; then 
					# Allow the description dialog to loop back to its configuration page
					description_loop=1
					while [ $description_loop -eq 1 ]
					do
						
						# Skip this configuration (Returning to HomePage)
						if [ $quit_config -eq 0 ]; then
							break
						fi
					
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Installing Clamav Antivirus with Graphical User Interface" 12 60 3 1 Install 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # installing clamav antivirus 
							1) install_clamav ;;
							
							   # Description Dialog
							2) dialog --title "Installing Clamav Antivirus with Graphical User Interface"  --msgbox "This would install Clamav antivirus \
																		    along with it GUI application 'Clamtk'." 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac

					done  
				fi

			#/================================================================================================/
				if [ $quit_config -eq 1 ] && [ $clamav_installed -ne 0 ] ; then
					dialog --title "Clamtk (Clamav Graphical User Interface)"  --msgbox "To configure or to perform scan use the clamtk application for the \
														Graphical User Interface" 10 65 
				fi 
			#/================================================================================================/
				check_apparmor
				if [ $apparmor_status -eq 0 ]; then 
					# Allow the description dialog to loop back to its configuration page
					description_loop=1
					while [ $description_loop -eq 1 ]
					do
						
						# Skip this configuration (Returning to HomePage)
						if [ $quit_config -eq 0 ]; then
							break
						fi
					
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Enable Apparmor" 10 45 3 1 Enable 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # installing clamav antivirus 
							1) enable_apparmor ;;
							
							   # Description Dialog
							2) dialog --title "Enable Apparmor"  --msgbox "AppArmor is tool that ensure applications only does what it is suppose to do \
													if the application deviates from its task, AppArmor would block it." 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac

					done  
				fi

			#/================================================================================================/
				check_apparmor
				if [ $apparmor_status -ne 0 ]; then 
					# Allow the description dialog to loop back to its configuration page
					description_loop=1
					while [ $description_loop -eq 1 ]
					do
						
						# Skip this configuration (Returning to HomePage)
						if [ $quit_config -eq 0 ]; then
							break
						fi
					
						# Configuration Dialog Menu
						exec 3>&1 
						Third=$(dialog --cancel-label "Skip" \
							--menu "Install Additional Apparmor Profiles" 10 45 3 1 Install 2 Description 3 Exit 2>&1 1>&3)
						exit_status=$? 
						exec 3>&-
						
						# Break the description dialog loop
						description_loop=0
						
						# User's Choice
						case $Third in
							   # installing clamav antivirus 
							1) configure_apparmor ;;
							
							   # Description Dialog
							2) dialog --title "Install Additional Apparmor Profiles"  --msgbox "AppArmor is tool that ensure applications \
															      only does what it is suppose to do if the \
															      application deviates from its task, AppArmor \
															      would block it. 
															      
															      This configuration install and \
															      enforce additional rules for AppArmor." 10 65 
							msg_status=$?
							description_loop=1 ;;
							
							   # Return to HomePage
							3) quit_config=0
						esac

					done  
				fi ;;

			#/================================================================================================/
		# HomePage's Description Dialog
		2) dialog --title "Linux System Hardening"  --msgbox "The intend of this system is to assist the user to harden their system in order to minimized the risk of \
									being a victim to a cyber attack
									
									NOTE: This system simply minimized the risk of attack, it does not completely stop the attack. \
									Hence, general security practices still needs to be followed. 
									
									Such as not installing suspicious looking files and clicking on suspicious looking links" 12 65 ;;
		
		#
		3) description_loop=1

		while [ $description_loop -eq 1 ]
		do
			# Configuration Dialog Menu
			exec 3>&1 
			First=$(dialog --cancel-label "Back" \
			       --menu "Back Up Configuration (Highly Recommended)" 10 50 3 1 "Back Up" 2 Description 3 Exit 2>&1 1>&3)
			exit_status=$? 
			exec 3>&-
			
			# Break the description dialog loop
			description_loop=0
			
			# User's Choice
			case $First in
				   # First Configuration
				1) check_timeshift
				install_timeshift
				Back_Up_Config ;;

				   # Description Dialog
				2) dialog --title "Back Up Description (Highly Recommended For First Time Usage)"  --msgbox "This back up does not include personal files but only include \
																 the system's configuration files. This is highly recommended \
																 as it allow you to revert back to the old configuration if any \
																 unexpected error were to occur. NOTE: By restoring the configurations \
																 any updates done after the backup will also be reverted" 10 65
				msg_status=$?
				description_loop=1 ;;
				
				   # Return to HomePage
				3) quit_config=0
			esac

		done  ;;

	esac
done

