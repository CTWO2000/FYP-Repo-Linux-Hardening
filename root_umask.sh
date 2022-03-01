#!/bin/bash

sed -i.bak 's/UMASK\t\t.*/UMASK\t\t026 # Default "umask" value./' /etc/login.defs


