# Debian LAVA docker-container
Designed to build and run a debian-based Docker container with LAVA pre-installed and pre-configured.

Note: At this time, running LAVA in Docker is not formally supported by Linaro or the LAVA team, but the team is exploring the ease of use that docker and containers enable.

## To build a new image locally
It may be desired to edit the Dockerfile. This requires locally rebuilding the Docker Image. To build an image locally, execute the following from the directory you cloned the repo:

```
sudo docker build -t lavadev .
```
Where `lavadev` is the Docker image name and can be chosen at the time of build.

## To run the image
To run the image from a host terminal / command line execute the following:

```
sudo docker run -it -v /boot:/boot -v /lib/modules:/lib/modules -v $PWD/fileshare:/opt/fileshare -v /dev/bus/usb:/dev/bus/usb -v /PATH/TO/id_rsa_lava.pub:/home/lava/.ssh/authorized_keys:ro --device=/dev/ttyUSB0 -p 8000:80 -p 2022:22 -h <HOSTNAME> --privileged lavadev
```
Where HOSTNAME is the hostname used during the container build process (check the docker build log), as that is the name used for the lava-slave. You can use `lava-docker` as the pre-built container hostname.

In the above command:
* `-v /boot:/boot` and `-v /lib/modules:/lib/modules` is neccessary due to libguestfs requireing a kernel and modules before it will run
* `-v $PWD/fileshare:/opt/fileshare` Includes a shared directory volume between the container and the host OS (./fileshare). Thus when invoking the docker run command, it should be done from a directory with ./fileshare in it.
* `-v /dev/bus/usb:/dev/bus/usb` opens up the USB ports so that fastboot can be connected to a physical target through USB.
* `-v /PATH/TO/id_rsa_lava.pub:/home/lava/.ssh/authorized_keys:ro` mounts a host file as a data volume (read-only) to allow remote SSH access. Note that the path to the SSH public key should be adjusted as appropriate.
* `--device=/dev/ttyUSB0` associates the physical serial USB debug port so that a console can be accessed from the container command line using the pre-installed "screen" utility. Note that `ttyUSB0` can change from host to host.
    ```shell
    screen /dev/ttyUSB0 115200    // to exit screen type `<ctl-a> <ctl-d>`
    ```
* `-p 8000:80` Opens up a network port to the host network so that the user can access the LAVA UI from a browser on another computer on the network `<host network IP address>:8000`
* `-p 2022:22` opens up a ssh port 2022 for access from other hosts on the network to the container. The user is "lava" and SSH key is used for the credential. Example: `ssh -p 2022 lava@<ip address of LAVA container host> -i /path/to/id_rsa_lava`. This is mapped to 2022 for the use case where the host is already running SSH server with the default port of 22 to prevent a conflict. SSH is not enabled by default, edit Dockerfile and enable if needed (avoid security issues).
* `-h lava-docker`  -- with v2, LAVA needs to know the name of the worker machine to submit jobs to devices on that machine
* The final parameter is the image ID that the Container will be run.  In the above example, we use `lavadev` that was defined at build time.  This dockerfile is also built and stored on [docker hub](https://hub.docker.com/r/akbennett/lava-docker) as `akbennett/lava-docker`.

## A quick test
A script is included in the image to verify that the install was successful. It will kick off several QEMU tests within LAVA. Once kicked off from the command line, progress of the tests can also be monitored from the LAVA web user interface. To execute this command from the container command line, enter `/submittestjob.sh`. Point your browser to https://localhost:8000/scheduler/alljobs to view the job status.

## Pushing jobs from your local host
You can also use the submit python helpers to submit test jobs to the running container. To submit jobs from your host machine you first need to extract the LAVA api key that was defined when building the container, then just use the same scripts that are available in this repository.

Extract the LAVA api key:

```
sudo docker run lavadev cat /apikey.txt
ss1c4huo3qw9mqnysm367buth09yuqwkohfd3hct0f62dwstmggpdexg1hrrwck5w0g1oxo3nqnx0ny6n38b1uxeo4s8ii6gz1jiles3zhjo1qiyyr0qzqk51prt7sb7
```

Submit a custom job from your host machine:

```
echo ss1c4huo3qw9mqnysm367buth09yuqwkohfd3hct0f62dwstmggpdexg1hrrwck5w0g1oxo3nqnx0ny6n38b1uxeo4s8ii6gz1jiles3zhjo1qiyyr0qzqk51prt7sb7 > apikey.txt
./submit.py -k apikey.txt --port 8000 kvm-qemu-aarch64.json
./submityaml.py -k apikey.txt --port 8000 -p qemu.yaml
```

# Running the container as a background service
Edit the Dockerfile to execute the lava-server and output the log files by default (`CMD /start.sh && tail -f /var/log/lava-*/*`), and detach the running container:

```
sudo docker run -d -v /boot:/boot -v /lib/modules:/lib/modules -v $PWD/fileshare:/opt/fileshare -v /dev/bus/usb:/dev/bus/usb -v /PATH/TO/id_rsa_lava.pub:/home/lava/.ssh/authorized_keys:ro --device=/dev/ttyUSB0 -p 8000:80 -p 2022:22 -h lava-docker --privileged lavadev
```

To access the LAVA service log files just run docker logs:

```
sudo docker logs -f lavadev
```

# Alternative Configuration Options
* Check out the Wiki for additional configuration options https://github.com/akbennett/lava-docker/wiki

# Known Issues / Warnings
* https://github.com/akbennett/lava-docker/issues

# Interesting Docker hub tags
* akbennett/lava-docker
