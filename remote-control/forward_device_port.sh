#!/bin/bash

if [ "$1" == "" ]
then
  echo "Usage: <device_id> <device port>:<server port>"
  exit
fi

DEVICE_USER=device$1
DEVICE_HOME=/home/$DEVICE_USER
DEVICE_MSG=$2
DEVICE_PORT=`echo "$DEVICE_MSG" | cut -d":" -f1`
SERVER_PORT=`echo "$DEVICE_MSG" | cut -d":" -f2`

if [ ! -d $DEVICE_HOME ]
then
  echo "Device user home dir does not exist: $DEVICE_HOME"
  exit
fi

echo "$DEVICE_MSG" | grep ":"
if [ $? -ne 0 ]
then
  echo "Define the device and server ports to be forwarded"
  exit
fi

echo $DEVICE_MSG | sudo -u $DEVICE_USER tee $DEVICE_HOME/et-home-msg

# Loop until msg is removed
while :
do
  [[ ! -f $DEVICE_HOME/et-home-msg ]] && break
  echo "Waiting until device connects"
  sleep 2
done

echo "Connecting to device port $DEVICE_PORT on server port $SERVER_PORT"
sleep 2
ssh -o "NoHostAuthenticationForLocalhost yes" -p $SERVER_PORT root@localhost
