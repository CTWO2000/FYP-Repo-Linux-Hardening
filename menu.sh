#!/bin/bash

while true 
do
	# HomePage Dialog Menu 
	exec 3>&1 
	test=$(dialog --cancel-label "Exit" \
		--menu "HomePage:" 10 30 3 1 Start 2 Description 2>&1 1>&3)
	exit_status=$? 
	exec 3>&-
	
	# Set exit/quit configuration variable
	quit_config=1
	
	# Exit the program
	if [ $exit_status -eq 1 ]; then
		exit 0
	fi
	
	case $test in
		1)	#/================================================================================================/
				# Allow the description dialog to loop back toits configuration page
				description_loop=1

				while [ $description_loop -eq 1 ]
				do
					# Configuration Dialog Menu
					exec 3>&1 
					First=$(dialog --cancel-label "Skip" \
					       --menu "First Function:" 10 30 3 1 Function 2 Description 3 Exit 2>&1 1>&3)
					exit_status=$? 
					exec 3>&-
					
					# Break the description dialog loop
					description_loop=0
					
					# User's Choice
					case $First in
						   # First Configuration
						1) echo "First Function" ;;

						   # Description Dialog
						2) dialog --title "Message"  --msgbox "First Function's Descriptions" 6 25 
						msg_status=$?
						description_loop=1 ;;
						
						   # Return to HomePage
						3) quit_config=0
					esac

				done

				# echo $First $msg_status
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

				# echo $Second $msg_status
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

				# echo $Third $msg_status  ;;
			#/================================================================================================/
		# HomePage's Description Dialog
		2) dialog --title "Message"  --msgbox "HomePage's Descriptions" 6 25
	esac
done

