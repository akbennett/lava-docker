#Debian LAVA docker-container
Designed to build and run a debian-based Docker container with LAVA on an Ubuntu 14.04 Host.

This project is a simple project to deploy LAVA into a docker image and pre-configure it to run some initial tests on some demonstration devices.  At this time, running LAVA in Docker is not formally supported by Linaro or the LAVA team, but we are exploring the ease of use that docker and in-general containers enable.

## To build a new image locally
It may be desired to disable or add to the Dockerfile.  This requires locally rebuilding the Docker Image.  To build an image locally, execute the following from the directory you cloned the repo:

```
sudo docker build -t "lava_base:dockerfile" .
```
Where `lava_base:dockerfile` is the Docker image name and can be chosen at the time of build.

## To run image
To run the container from a Ubuntu host terminal command line execute the following:

```
sudo docker run -it  -v /boot:/boot  -v /lib/modules:/lib/modules -v $PWD/fileshare:/opt/fileshare -v /dev/bus/usb:/dev/bus/usb  --device=/dev/ttyUSB0  -p 8000:80 -p 2022:22  -h de2384825135  --privileged=true arizidon/debian-lavaserver:testing
```
or
```
sudo docker run -it  -v /boot:/boot -v /lib/modules:/lib/modules -v $PWD/fileshare:/opt/fileshare -v /dev/bus/usb:/dev/bus/usb  --device=/dev/ttyUSB0  -p 8000:80 -p 2022:22  -h de2384825135  --privileged=true 4548d6b5a5b2
```

In the above command:


* `-v /boot:/boot` and `-v /lib/modules:/lib/modules` is neccessary due to libguestfs requireing a kernel and modules before it will run
*  `-v $PWD/fileshare:/opt/fileshare` Includes a shared directory volume between the container and the host OS (./fileshare).  Thus when invoking the docker run command, it should be done from a directory with ./fileshare in it.
* `-v /dev/bus/usb:/dev/bus/usb` opens up the USB ports so that fastboot can be connected to a physical target through USB.
* `--device=/dev/ttyUSB0` assosiates the physical serial USB debug port so that a console can be accessed from the container command line using the pre-installed "screen" utility. Note that `ttyUSB0` can change from host to host.
```shell
    screen /dev/ttyUSB0 115200        //  to exit screen type `<ctl-a> <ctl-d>`
```
* `-p 8000:80` Opens up a network port to the host network so that the user can access the LAVA UI from a browser on another computer on the network `<host network IP address>:8000`
* `-p 2022:22` opens up a ssh port 2022 for access from other hosts on the network to the container.  The host:password is "root" and "password".  Example:  `ssh root@<ip address of LAVA container host> -p 2022`.  This is mapped to 2022 for the use case where the Ubuntu host is already running sshd with the default port of 22 to prevent a conflict.
* `-h de2384825135`  -- with v2, LAVA needs to know the name of the worker machine.
* The final parameter is the image ID that the Container will be run.  In the above example, `4548d6b5a5b2` is the resulting Image ID built in the previous step and will be different each time an image is built.    The Image ID could also be a pre-built container such as `arizidon/debian-lavaserver:testing` used in the other example and comes from the prebuilt image that has been uploaded to [docker hub](https://hub.docker.com/r/arizidon/debian-lavaserver/) .  This pre-built image is the recommended image to install and test initially before building your own image.

## A quick test
A script is included in the install to verify that this install was successful. It runs several QEMU tests.  Once kicked off from the command line, progress of the tests can also be monitored from the LAVA Browser interface.  To execute this command from the container command line, enter `/submittestjob.sh`.

#Alternative Configuration Options
## Default Passwords
Default password for debian root is `root:password`.  This is used for ssh as well.

Default admin account and password for the LAVA Server is `admin:admin`

**NOTE:** These should be changed in a deployed use-case

## Create unique local network IP address

To this point, the procedure uses a specific port on the shared Host IP address on the local network (for example `192.168.0.1`**`:8000`**).  In some cases, it may be desirable for the LAVA Server to expose an entirely different IP address on the local network. To create a specific / secondary IP address to map to the LAVA Server on the host, the host can be configured as follows:

Reference: http://blog.codeaholics.org/2013/giving-dockerlxc-containers-a-routable-ip-address/

From Ubuntu Host OS

**Define Virtual Interface**
* use a macvlan type interface so that it could have its own MAC address and therefore receive an IP by DHCP if required.
```
sudo ip link add virtual0 link eth0 type macvlan mode bridge
```
* Use DHCP instead of selecting a static IP
```
sudo dhclient virtual0 &
```
Note: Must kill client when close container
```
sudo dhclient -d -r virtual0
```
* Bring it up
```
sudo ip link set virtual0 up
```

**Set up inbound routing**
```
sudo iptables -t nat -N BRIDGE-VIRTUAL0
sudo iptables -t nat -A PREROUTING -p all -d <container external IP> -j BRIDGE-VIRTUAL0
```
Where `<container external IP>` is the static OR DHCP defined IP address.  Can find it using
```
sudo ifconfig
sudo docker inspect <container id>   // to find the IP
sudo iptables -t nat -A OUTPUT -p all -d <container external IP> -j BRIDGE-VIRTUAL0
sudo iptables -t nat -A BRIDGE-VIRTUAL0 -p all -j DNAT --to-destination <container internal IP>
```

**Set up outbound Routing**
```
sudo iptables -t nat -I POSTROUTING -p all -s <container internal IP> -j SNAT --to-source <container external IP>
```

Can now connect to LAVA through a browser using the <container external IP>  from the local network

## Configuration Control
### Base Image Version Control
One very important step in using this LAVA server installation is backing up the Docker Image once it has been customized for a specific deployment.  Once a Docker  Base Image has been prepared for deployment (potentially across multiple servers), it is recommended that the image be placed in a repository on http:/hub.docker.com OR  if the above does not comply with company security policies, then it will be required to create a local docker repository within the company infrastructure and back up to this repository.

### Deployed Container Backups
Docker makes it very simple for the user to back up a running container that has been deployed and is configured.   This is quite convenient if a host were to fail.  The backed up image can effectively be restored and all configuration / test options will be present except those changed from the last backup.   See the`docker export` command for more details.

If for any reason a container is stopped using the `exit` command from the container command line, the state at exit can be saved from within the Ubuntu host using the `docker commit` command.   Command format may look similar to the following:
```
sudo docker commit <containerID>  <newimage:tag>
```
See `docker commit` in the Docker documentation for more details.

# Known Issues / Warnings
* Note that when the container is run, there is a privilege = true option in the command line.  This is because LAVA is required privilege access to the OS to be able to mount loopbacks in order to function.  The user should be aware  that the whole container is running in privileged mode due to this.
* An intermittent issue has been seen.  When running the `/submittingtestjob.sh` script which effectively runs an integrity test set of jobs against several QEMU installed targets, on occation an error occurs that looks similar below.  It occurs when running the /submittestjob.sh script.   If this occurs, it's an indicator that Apache2 has died.  The LAVA Server Web UI will also likely be unresponsive.  If this occurs, run `service apache2 reload` from within the running container and it should be resolved.
* The API token is the same for all containers

```
xmlrpclib.ProtocolError: ....500 Internal Server Error
```
* As noted in the previous bullet, the Dockerfile is currently configured to automotically install 3 different QEMU targets for testing.  If this is not desired, the user should modify these configuration options from within the Dockerfile and rebuild to remove them from the resulting image.

# Interesting Docker hub tags
* akbennett/lava --> akbennett/latest --> akbennett/lava:lava-demo
