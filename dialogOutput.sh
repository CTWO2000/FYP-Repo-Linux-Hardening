#/bin/bash 

# dialog --prgbox "cal" 10 20
# cal | dialog --programbox 12 24



dialog --yesno "Update System?" 0 0

exit_status=$?

case $exit_status in
	0) dialog --prgbox "sudo apt update" 10 50 ;;
	1) exit 0
esac

