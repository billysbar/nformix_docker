#!/bin/sh
# blobshow.sh - show an image in the background and then kill the process
# written by Erik Hennum 4/20/91

# Validation
#     arguments
if [ "$#" -lt 3 ]; then
    echo "${0}: usage $0 command options file [other ...]"
    echo "    command = A command that displays the file."
    echo "    options = All arguments before the file (enclose in"
    echo "              quotes to pass as single argument;"
    echo "              if none, enclose nothing in quotes)."
    echo "    file    = The file containing the image."
    echo "    other   = Optional arguments."
    exit
#     file
elif [ ! -f $3 ]; then
    echo "${0}: can't find $3 from `pwd`."
    exit
fi

# Execute the command in the background
$* 2> /tmp/shw_$$.errors & 
# let xwd diagnose any errors if it's gonna
sleep 3
# display errors if it found any
if [ -s /tmp/shw_$$.errors ]; then 
    echo " --------------------------"
    echo " Errors in display"
    echo "  "
    cat /tmp/shw_$$.errors
    echo " "
    echo "Press RETURN to continue ..."
    read nada
fi
# remove error file
# test /tmp/shw_$$.errors && rm /tmp/shw_$$.errors

# Create shell script to kill this process -- whether it is still up or not
# $! is the process ID of the last backgrounded process
# the exec line sends all output from this shell into /dev/null
echo '#!/bin/sh' >/tmp/kill.sh
echo 'exec >>/dev/null 2>>/dev/null' >>/tmp/kill.sh
echo "procno=$!" >>/tmp/kill.sh
echo 'procstat=`ps $procno | wc`' >>/tmp/kill.sh
echo 'set $procstat' >>/tmp/kill.sh
echo 'echo $1 $2 $3 >>/tmp/debug' >>/tmp/kill.sh
echo 'if ( test $2 -ne 5 ) then' >>/tmp/kill.sh
echo '	kill -9 $procno' >> /tmp/kill.sh
echo 'fi' >>/tmp/kill.sh
chmod 777 /tmp/kill.sh

exit
# NOTE:  If two people are running this program on the same 
# workstation, there are potential collisions over the kill.sh
# file.
