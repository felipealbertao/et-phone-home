# ET Phone Home

_Simple remote control for OpenWRT IoT devices using SSH tunnels_

The biggest problem in managing IoT devices is actually connecting to them because they are often deployed behind a local network firewall. ET Phone Home is a solution that uses SSH reverse tunnels to bypass the firewall, by "pinging" an external server every minute and then forwarding the device's port from inside the firewall to the outside server. This solution also provides a basic way to monitor the device's health.

This solution was customized for OpenWRT, but it likely works with little or no modifications on other Linux-based platforms such as Raspberry Pi, BeagleBone or Arduino Yun.


## How It Works

- A SSH server is provisioned, and a user and home directory is created for every device on the server.
- The device connects to the server every minute, looking for a file in the device's home dir. This servers as a poor-man's "inbox" messaging process.
- A file indicates the intent to control the device, containing the port that should be forwarded. If that file is present, then the device establishes the tunnel with the server and forwards the requested port.
- If a file does not exists, the device simply disconnects and waits for the next tentative in a minute.
- The "footprint" left by the device's minute-by-minute connection in the ssh auth logs serves as a kind of "heartbeat" that can be used to check the device's health.
- More than one port can be forwarded, allowing the remote administration of the OpenWRT device using its Web interface.


## AWS SSH Server Set-up

### SSH Server provisioning

- EC2 > Launch Instance
    - Ubuntu > t2.micro > Review and Launch
    - Security Groups: Only ssh
    - Launch
    - Create a new key-pair
    - Save the new key-pair locally, and `chmod 400 <key pair>.pem`
- EC2 > Elastic IP > Allocate New Address
    - EIP used in: VPC
    - Select new IP > Associate Address
        - Click on Instance, select it


### ET Phone Home Installation

Do the following on the AWS-provisioned server:

```bash
sudo apt-get install git
cd /home/ubuntu
git clone https://github.com/felipealbertao/et-phone-home.git
```

Note that the script `et-home-ping.sh` must be under the absolute directory
  `/home/ubuntu/et-phone-home/et-home/et-home-ping.sh`


### SSH Server Config

- `sudo nano /etc/ssh/sshd_config`  
    ```
    PermitRootLogin no
    ```

## OpenWRT Device Installation

Connect to the device as root and execute the following command:

```bash
export SSH_SERVER=52.20.12.167 ; wget -qO - http://s3-us-west-2.amazonaws.com/et-phone-home/et-phone-home-install.sh | ash
```

*IMPORTANT*: Change the `SSH_SERVER` ip address above to your own IP address provisioned by AWS.

The script above will install the files needed to run the scripts on OpenWRT, and it will also generate a SSH key to connect with the server.

Instructions will be shown at the end of the script execution: Follow the instructions to copy and paste the public key to the AWS SSH server. The script mentioned in the instructions will create the user and the ssh key the device needs to connect to the server.

Also make a note of the device id generated for the device: This is the id you will use to connect to the device later. The device id is the MAC Address of the wireless port.

_Note:_ The files needed to install the scripts on OpenWRT are available on S3 for your convenience, but you may upload `s3/et-phone-home.sh` and `s3/et-phone-home-install.sh` to your own S3 bucket, setting the permission as "Make everything public". Also note that S3 is used (as oppose to GitHub) because it exposes the files as plain http, since OpenWRT's `wget` does not support https.


## Usage

### List the available devices

SSH to the AWS server (ex: `ssh -i <key-pair>.pem ubuntu@<AWS SSH Server>`)

```bash
/home/ubuntu/et-phone-home/remote-control/list_devices.sh
```

### Connecting to the remote device

SSH to the AWS server (ex: `ssh -i <key-pair>.pem ubuntu@<AWS SSH Server>`)

```bash
/home/ubuntu/et-phone-home/remote-control/forward_device_port.sh <device_id> <device_port>:<server_port>
```

Example:
```bash
/home/ubuntu/et-phone-home/remote-control/forward_device_port.sh 6466b34bde54 22:9876
```

## Forward the device's web management interface to your local computer

SSH to the AWS server (ex: `ssh -i <key-pair>.pem ubuntu@<AWS SSH Server>`), then use the same forward command
above but on port 80. Example:

```bash
/home/ubuntu/et-phone-home/remote-control/forward_device_port.sh 6466b34bde54 80:8765
```

Then, on your local PC, create a tunnel from the SSH server to a local port:

```bash
ssh -N -v -i <key-pair>.pem -L 3000:127.0.0.1:8765 ubuntu@<AWS SSH Server>
```

Access the web interface with http://localhost:3000

### Manage devices connected to the SSH server

- List devices connected to server:  
   `ps -ef | grep ssh` or  
   `ps -ef | grep <device id>`

- Kill devices connected to server:
   `sudo kill <pid>`

### Checking the active device's "heartbeats" and last-connected time

   ```bash
   ssh ubuntu@<AWS SSH Server>
   tail -f /var/log/auth.log   # Shows all devices
   tail /var/log/auth.log | grep <device id>  # Shows only that specific device
   ```

### Testing the device's ability to connect to the server

(execute this on the device)

```bash
ssh -i /root/.ssh/id_rsa <device_id>@52.20.12.167 /home/ubuntu/et-phone-home/et-home/et-home-ping.sh
```

The script will return 0 if no "message" is found (that is, the device should be on stand-by),
or it will return a message in the format of "<local device port>:<remote server port>"


## Reference

This system is an expansion to the solution described in http://blogs.wcode.org/2015/04/howto-ssh-to-your-iot-device-when-its-behind-a-firewall-or-on-a-3g-dongle/
