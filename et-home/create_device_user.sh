#!/bin/bash

if [ "$1" == "" ]
then
  echo "Usage: $0 <device_id> <ssh_rsa_key>"
  exit
fi

deviceuser=device$1

sudo adduser --disabled-password $deviceuser
sudo -u $deviceuser mkdir /home/$deviceuser/.ssh
echo "$2" | sudo -u $deviceuser tee /home/$deviceuser/.ssh/authorized_keys
sudo chmod 400 /home/$deviceuser/.ssh/authorized_keys
