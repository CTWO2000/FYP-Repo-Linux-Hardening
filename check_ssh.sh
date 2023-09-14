#!/bin/bash


if $(systemctl status sshd >/dev/null 2>&1); then
	echo "ssh installed"
else
	echo "ssh not installed"
fi
