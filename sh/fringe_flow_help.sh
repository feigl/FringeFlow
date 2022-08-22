#!/bin/bash
############################################################
# Help                                                     #
# https://www.redhat.com/sysadmin/arguments-options-bash-scripts
############################################################
Help()
{
   # Display Help
   echo "Add description of the script functions here."
   echo
   echo "Syntax: scriptTemplate [-g|h|v|V]"
   echo "options:"
   echo "g     Print the GPL license notification."
   echo "h     Print this Help."
   echo "v     Verbose mode."
   echo "V     Print software version and exit."
   echo
}

############################################################
############################################################
# Main program                                             #
############################################################
############################################################

# Set variables
Name="world"

############################################################
# Process the input options. Add options as needed.        #
############################################################
# Get the options
while getopts ":hn:" option; do
   case $option in
      h) # display Help
          Help
         exit;;
      n) # Enter a name
         Name=$OPTARG;;
     \?) # Invalid option
         echo "Error: Invalid option"
         exit;;
   esac
done

# test existence of variable
#https://unix.stackexchange.com/questions/212183/how-do-i-check-if-a-variable-exists-in-an-if-statement
if [[ -n ${Name+set} ]]; then
   echo Name is $Name
else
   Name=${USER}
fi

echo "hello $Name!"
# test command and redirect standard error 
#https://stackoverflow.com/questions/16842014/redirect-all-output-to-file-using-bash-on-linux
(ls /home/$Name > /dev/null 2>&1 ) && (echo "OK"; exit 0) || (err=$?; echo "ERROR $err"; (exit $err))
(ls /home/$Name 2>&1 ) && (echo "OK"; exit 0) || (err=$?; echo "ERROR $err"; (exit $err))