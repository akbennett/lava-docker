# Debian LAVA docker-container
Designed to build and run a debian-based Docker container with LAVA pre-installed and pre-configured.

Note: At this time, running LAVA in Docker is not formally supported by Linaro or the LAVA team, but the team is exploring the ease of use that docker and containers enable.

## To build a new image locally
It may be desired to disable or add to the Dockerfile.  This requires locally rebuilding the Docker Image.  To build an image locally, execute the following from the directory you cloned the repo:

```
sudo docker build -t lavadev .
```
Where `lavadev` is the Docker image name and can be chosen at the time of build.

## To run the image
To run the image from a host terminal / command line execute the following:

```
sudo docker run -it  -v /boot:/boot  -v /lib/modules:/lib/modules -v $PWD/fileshare:/opt/fileshare -v /dev/bus/usb:/dev/bus/usb --device=/dev/ttyUSB0 -p 8000:80 -p 2022:22  -h de2384825135 --privileged=true lavadev
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
* The final parameter is the image ID that the Container will be run.  In the above example, we use `lavadev` that was defined at build time.  This dockerfile is also built and stored on [docker hub](https://hub.docker.com/r/akbennett/lava-docker) as `akbennett/lava-docker`. 

## A quick test
A script is included in the install to verify that this install was successful. It will kick off several QEMU tests within LAVA.  Once kicked off from the command line, progress of the tests can also be monitored from the LAVA Browser interface.  To execute this command from the container command line, enter `/submittestjob.sh`.  Point your browser to https://localhost:8000/scheduler/alljobs to view the job status.

# Alternative Configuration Options
* Check out the Wiki for additional configuration options https://github.com/akbennett/lava-docker/wiki

# Known Issues / Warnings
* https://github.com/akbennett/lava-docker/issues

# Interesting Docker hub tags
* akbennett/lava-docker
