#!/bin/bash

username=fyp


if [ ! -d "/home/$username/Desktop/test" ]; then
    mkdir /home/$username/Desktop/test
    echo "test directory created"
else
    echo "Directory /home/$username/ssh exists." 
fi
