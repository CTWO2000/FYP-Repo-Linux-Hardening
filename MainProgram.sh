#!/bin/bash


# Get username and check if the username exist
check_user(){
	exec 3>&1 
	username=$(dialog --inputbox "Enter Username" 0 0 2>&1 1>&3) 
	exit_status=$? 
	exec 3>&-   
	
	if [ $exit_status -eq 1 ]; then
		exit 0
	fi

	if id $username >/dev/null 2>&1; then
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

# Configuration Functions
#/=====================================================================================================================================================================/
# Install and Configure pam_pwquality.so
configure_pw_complexity() {
	apt -y install libpam-pwquality 2>/dev/null | dialog --programbox "Installing libpam-pwquality for password complexity" 20 70


	pwquality=$(cat /etc/pam.d/common-password | grep password | grep requisite | grep pam_pwquality.so)

	if [ ! "$pwquality" ]; then 
		dialog --title "Missing pam_pwquality.so"  --msgbox "pam_pwquality.so Not Installed" 10 65	
	else
		sed -i.bak 's/pam_pwquality.so .*/pam_pwquality.so retry=1 minlen=8 difok=4 ucredit=-1 lcredit=-1 dcredit=-1 ocredit=-1 reject_username enforce_for_root/' /etc/pam.d/common-password
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
							      Minimum 8 characters, 1 Uppercase, 1 Lowercase, 1 Digit, 1 Symbol, No Re-use Password and No Username. \
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
	echo "Hello World"
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
	timeshift --create --comments "Backup with Program" | dialog --programbox 12 70
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
											     updates." 10 40 
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
						--menu "Sudo Timeout:" 10 30 3 1 "Sudo Timeout" 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Second in
						   # Authenticate user each time sudo command is executed
						1) sudo_timeout ;;
						
						   # Description Dialog
						2) dialog --title "Sudo Timeout Description"  --msgbox "This will force the the user authenticate each time the 'sudo' command is executed." 10 40 
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
						--menu "Configure Password Complexity" 10 40 3 1 Function 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Third in
						   # change password Configuration
						1) configure_pw_complexity ;;
						
						   # Description Dialog
						2) dialog --title "Configure Password Complexity"  --msgbox "This will install libpam-pwquality in order to configure user password complexity. \
													       The configuration will include: Minimum 8 characters, 1 Uppercase, 1 Lowercase, 1 Digit, \
													       1 Symbol, No Re-use Password and No Username." 6 25 
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
						--menu "Change Password:" 10 30 3 1 Function 2 Description 3 Exit 2>&1 1>&3)
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
						2) dialog --title "Change Password"  --msgbox "Change Password's Descriptions" 6 25 
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done ;;

			#/================================================================================================/
		# HomePage's Description Dialog
		2) dialog --title "Message"  --msgbox "HomePage's Descriptions" 6 25 ;;
		
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
				1) Back_Up_Config ;;

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

