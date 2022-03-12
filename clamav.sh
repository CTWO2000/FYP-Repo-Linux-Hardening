#!/bin/bash

command -v "clamscan" >/dev/null 2>&1

if [[ $? -ne 0 ]]; then
	sudo apt -y install clamav
fi

command -v "clamtk" >/dev/null 2>&1

if [[ $? -ne 0 ]]; then
	sudo apt -y install clamtk
fi
