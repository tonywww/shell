#!/bin/bash

echo ""
echo "systemctl status rc.local.service"
systemctl status rc.local.service
echo "cat /etc/rc.local"
cat /etc/rc.local
echo ""
read -p "Do you still want to enable rc.local service? [y/n} " answer

case $answer in
    Y|y)
    echo "continue..."

cat >>/etc/rc.local <<EOF 
#!/bin/sh -e
#
# rc.local
#
# This script is executed at the end of each multiuser runlevel.
# Make sure that the script will "exit 0" on success or any other
# value on error.
#
# In order to enable or disable this script just change the execution
# bits.
#
# By default this script does nothing.



exit 0

EOF

chmod +x /etc/rc.local
systemctl start rc-local
systemctl status rc-local
echo "cat /etc/rc.local"
cat /etc/rc.local

echo ""


## go exit
    ;;

    *)
    echo "exit"
    ;;
esac
exit 0
