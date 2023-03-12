# FYP Repository
## Execute Program
```
# sudo ./run.sh
```

## Change Default Umask Value
1. Change "root" umask
	- Navigate to "/etc/login.defs"  
	- Look for "umask" and change the value to the desired umask (077)
```
# sudo gedit /etc/login.defs

// Within the "login.defs" file
# If USERGROUPS_ENAB is set to "yes", that will modify this UMASK default value
# for private user groups, i. e. the uid is the same as gid, and username is
# the same as the primary group name: for these, the user permissions will be
# used as group permissions, e. g. 022 will become 002.
#
# Prefix these values with "0" to get octal, "0x" to get hexadecimal.
#
ERASECHAR       0177
KILLCHAR        025
UMASK           022    # Change this value

```
2. Change "user" umask
	- Navigate to the user's ".bashrc" file  
	- Append "umask <\umask value>" in the file  
3. **For the changes to take effect, simply logout and login.**
	
### Reference 
1. https://askubuntu.com/questions/805862/how-to-change-umask-mode-permanently
2. https://www.cyberithub.com/change-default-umask-values-permanently/
3. https://docs.oracle.com/cd/E19683-01/817-3814/userconcept-95347/index.html
4. https://www.cyberciti.biz/tips/understanding-linux-unix-umask-value-usage.html

## Change Password in One-line
```
echo -e "<\Current Password>\n<\New Password>\n<\Confirm New Password>" | passwd <\Account's Name>
eg. 
# echo -e "toor@12345\npass@12345\npass@12345" | passwd test
```

## TimeShift 
1. TimeShift "restore" does not restore local system files
2. To create a snapshot:
```
# sudo timeshift --create --comments "Backup with CLI" 
```

## Lynis
1. Installation and Executing
```
# git clone https://github.com/CISOfy/lynis
# cd lynis
# sudo ./lynis audit system
```
	
## Ignore This
1. Get sudo access prompt
	- use "pkexec"
	- require full path to use
```
eg:
# pkexec $(pwd)/scriptPath.sh
```
