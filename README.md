# lava-docker
This project is a simple project to deploy LAVA into a docker image and pre-configure it to run some initial tests on some demonstration devices.  At this time, running LAVA in Docker is not formally supported by Linaro or the LAVA team, but we are exploring the ease of use that docker and in-general containers enable.  

Using Docker, a new user can have their first LAVA install up and running in a matter of seconds (sans download time).  

To run the container
```
  sudo docker run -t -i -p 8000:80 -h de2384825135 --privileged=true -v /boot:/boot -v /lib/modules:/lib/modules akbennett/lava
  # NOTE, new command line options for docker
  # --privileged=true is necessary to mount an image (uses loopback) within the container
  # -v /boot:/boot and -v /lib/modules:/lib/modules is neccessary due to libguestfs has a dependency on the kernel and modules
  # -h de2384825135  -- with v2, LAVA needs to know the name of the worker machine
```

Once the Container starts, you can submit jobs via the web interface, or run a few sample jobs using the helper script
```
  /submittestjob.sh
  LAUNCH your web browser and navigate to http://localhost:8000
```

Cautions:

This LAVA installation is not very secure
- Default username / password for administration is "admin"/"admin"
- The API token is the same for all containers

Production LAVA instances should be installed on bare metal, outside of a container
- LAVA is a large system with many dependencies, installing it all in a container is great for ease of use, but long-term system maintenance within a container is not recommended

# Interesting Docker hub tags
* akbennett/lava --> akbennett/latest --> akbennett/lava:lava-demo
