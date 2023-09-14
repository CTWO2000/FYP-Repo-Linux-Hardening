#!/bin/bash


sed -i.bak 's/PASS_MAX_DAYS\t.*/PASS_MAX_DAYS\t90 # Maximum number of days a password may be used./' /etc/login.defs
sed -i.bak 's/PASS_MIN_DAYS\t.*/PASS_MIN_DAYS\t1 # Minimum number of days allowed between password changes./' /etc/login.defs

chage -m 1 fyp
chage -M 30 fyp

