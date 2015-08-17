#!/bin/ash

# This script is meant to be executed from the OpenWRT box, like so:
#   export SSH_SERVER=<ssh server address> ; wget http://.../et-phone-home-install.sh | ash

if [ "$SSH_SERVER" == "" ]
then
  echo "No SSH_SERVER defined"
  exit
fi

# Check if the SSH certificate is already defined
grep "$SSH_SERVER" /root/.ssh/known_hosts > /dev/null
if [ $? -ne 0 ]
then
  echo "=============================="
  echo "Press 'y' to accept the server's SSH certificate"
  echo "=============================="
  ssh -T -N $SSH_SERVER
fi

# Check again if the SSH certificate was correctly saved
grep "$SSH_SERVER" /root/.ssh/known_hosts > /dev/null
if [ $? -ne 0 ]
then
  echo "SSH certificate was not accepted. Check /root/.ssh/known_hosts"
else
  # Save the ssh server
  echo $SSH_SERVER > /etc/et-phone-home-ssh-server
fi

# Create the device id
cat /sys/class/net/wlan0/address | tr -d ':' > /etc/device_id

# Define the variables from config
ssh_remote_server=`cat /etc/et-phone-home-ssh-server`
device_id=`cat /etc/device_id`

# Download the script
wget -qO /root/et-phone-home.sh http://s3-us-west-2.amazonaws.com/et-phone-home/et-phone-home.sh
chmod +x /root/et-phone-home.sh

# Configure crontab to run script every minute
crontab -l | grep "/root/et-phone-home.sh" > /dev/null
if [ $? -ne 0 ]
then
  (crontab -l ; echo "*/1 * * * * /root/et-phone-home.sh") | crontab -
fi

# Generate the rsa key
dropbearkey -t rsa -f /root/.ssh/id_rsa > /dev/null

echo "Copy the snippet below and paste on the et-phone-home ssh server:"
echo "=============================="
echo "/home/ubuntu/et-phone-home/et-home/create_device_user.sh $device_id '`dropbearkey -f /root/.ssh/id_rsa -y | grep ssh-rsa`'"
echo "=============================="
