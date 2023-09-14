#!/bin/bash

username=fyp


if [ ! -f "/home/$username/Desktop/test2.txt" ]; then
    touch test2.txt
    echo "test2.txt does not exist "
else
    mv test2.txt test2.txt.bak
    touch test2.txt
    echo "test2.txt exist" 
fi
