# Install Timeshift if not installed 
command -v "gufw" >/dev/null 2>&1

if [[ $? -ne 0 ]]; then
	echo "gufw not installed"
else
	echo "gufw installed"
fi
