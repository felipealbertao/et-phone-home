#!/bin/ash

ssh_remote_server=`cat /etc/et-phone-home-ssh-server`
device_id=`cat /etc/device_id`
ssh_message=`ssh -i /root/.ssh/id_rsa device$device_id@$ssh_remote_server /home/ubuntu/et-phone-home/et-home/et-home-ping.sh`

if [ $? -ne 0 ]
then
  logger "ET Phone Home: Server not found"
  exit
fi

if [ $ssh_message = "0" ]
then
  echo "ET Phone Home: No message"
else
  ssh_local_port=`echo $ssh_message | cut -d":" -f1`
  ssh_remote_port=`echo $ssh_message | cut -d":" -f2`
  logger "ET Phone Home Session: Local port $ssh_local_port - Remote port $ssh_remote_port"
  ssh -N -i /root/.ssh/id_rsa -R $ssh_remote_port:localhost:$ssh_local_port device$device_id@$ssh_remote_server &
fi
