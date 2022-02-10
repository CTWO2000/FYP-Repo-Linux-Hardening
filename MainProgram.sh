#!/bin/bash


#/================================================================================================/
# Configuration Functions

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

Back_Up_Config () {
	timeshift --create --comments "Backup with Program" | dialog --programbox 12 70
}



#/================================================================================================/
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
				# Allow the description dialog to loop back toits configuration page
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
				# Allow the description dialog to loop back toits configuration page
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
						--menu "Second Function:" 10 30 3 1 Function 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Second in
						   # Second Configuration
						1) echo "Second Function" ;;
						
						   # Description Dialog
						2) dialog --title "Message"  --msgbox "Second Function's Descriptions" 6 25 
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done

			#/================================================================================================/
				# Allow the description dialog to loop back toits configuration page
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
						--menu "Third Function:" 10 30 3 1 Function 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $Third in
						   # Third Configuration
						1) echo "Third Function";;
						
						   # Description Dialog
						2) dialog --title "Message"  --msgbox "Third Function's Descriptions" 6 25 
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
																 unexpected error were to occur." 10 65
				msg_status=$?
				description_loop=1 ;;
				
				   # Return to HomePage
				3) quit_config=0
			esac

		done  ;;

	esac
done

