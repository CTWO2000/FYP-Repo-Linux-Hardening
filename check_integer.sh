#!/bin/bash

exec 3>&1 
input=$(dialog --inputbox "Enter a Number" 0 0 2>&1 1>&3) 
exit_status=$? 
exec 3>&- 

if [[ $input ]] && [ $input -eq $input 2>/dev/null ]; then
   echo "$input is an integer"
else
   echo "$input is not an integer or not defined"
fi

