#!/bin/bash

command -v "$1" >/dev/null 2>&1

if [[ $? -ne 0 ]]; then
	echo "$1 not installed"
else
	echo "$1 installed"
fi
