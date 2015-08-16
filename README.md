# ET Phone Home

_Simple remote control for OpenWRT IoT devices using SSH tunnels_

## EC2 Server Set-up

### SSH Server provisioning

- EC2 > Launch Instance
    - Ubuntu > t2.micro > Review and Launch
    - Security Groups: Only ssh
    - Launch
    - Create a new key-pair `ssh-server` for ssh use, and save under `et-phone-home/ssh-server.pem`
    - `chmod 400 ssh-server.pem`
- EC2 > Elastic IP > Allocate New Address
    - EIP used in: VPC
    - Select new IP > Associate Address
        - Click on Instance, select it
- Add elastic IP to `ssh-server.sh`

## Installation

```bash
sudo apt-get install git
cd /home/ubuntu
git clone ...
```

- Note that the script et-home-ping.sh must be under the absolute directory
  `/home/ubuntu/et-phone-home/et-home/et-home-ping.sh`
- Upload `s3/et-phone-home.sh` and `s3/et-phone-home-install.sh` to S3, setting the permission as "Make everything public"

### SSH Server Config

- `sudo nano /etc/ssh/sshd_config`  
    ```
    PermitRootLogin no
    ```
- Install et-phone-home scripts:  
  ```
  sudo mkdir /opt/et-home
  sudo cp ... /opt/et-home/et-home-ping.sh
  ```

## OpenWRT Installation

```bash
export SSH_SERVER=52.20.12.167 ; wget -qO - http://s3-us-west-2.amazonaws.com/et-phone-home/et-phone-home-install.sh | ash
```



- Create device_id:  
  `cat /sys/class/net/wlan0/address | tr -d ':' > /etc/device_id`
- Config ssh server address:
  `echo "52.20.12.167" > /etc/et-phone-home-ssh-server`

```bash
echo "`cat /etc/et-phone-home-ssh-server`  <server key without trailing root@...>" >> /root/.ssh/known_hosts

mkdir /root/et-phone-home
dropbearkey -t rsa -f /root/.ssh/id_rsa
```
- Copy the public key and send via Skype

- Copy `et-phone-home.sh` script
- `chmod +x /root/et-phone-home.sh`

- Configure crontab to run script every minute:  
  `(crontab -l ; echo "*/1 * * * * /root/et-phone-home.sh") | crontab -`

### Create device user

```
sudo adduser --disabled-password device830283
sudo -u device830283 mkdir /home/device830283/.ssh
echo "<paste public key>" | sudo -u device830283 tee /home/device830283/.ssh/id_rsa.pub
sudo chmod 400 /home/device830283/.ssh/authorized_keys
```





## Operation

- Active devices:  
    `tail -f /var/log/auth.log`

- On server, post message to forward device's port 22 to server's port 5678:  
    `echo "22:5678" | sudo -u device830283 tee /home/device830283/et-home-msg`  
    or  
    `echo "80:5690" | sudo -u device830283 tee /home/device830283/et-home-msg`  

- Connect to OpenWRT from server:  
  `ssh -o "NoHostAuthenticationForLocalhost yes" -p 5678 root@localhost`

- On PC, tunnel OpenWRT web port to localhost:  
  `ssh -N -v -i ssh-server.pem -L 3000:127.0.0.1:5690 ubuntu@52.20.12.167`

 - Read message from OpenWRT:  
   `ssh -i /root/.ssh/id_rsa device830283@52.20.12.167 /opt/et-home/et-home-ping.sh`


 - List devices connected to server:  
   `ps -ef | grep ssh` or  
   `ps -ef | grep <device id>`

 - Kill devices connected to server:
   `sudo kill <pid>`

## Reference

ssh -i ~/.ssh/id_rsa device830283@52.20.12.167 /opt/et-home/et-home-ping.sh

export SSH_SERVER=52.20.12.167 ; cat et-phone-home-install.sh | ash

http://blogs.wcode.org/2015/04/howto-ssh-to-your-iot-device-when-its-behind-a-firewall-or-on-a-3g-dongle/
