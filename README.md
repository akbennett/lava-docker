# lava-docker
This project is a simple project to deploy LAVA into a docker image and pre-configure it to run some initial tests on some demonstration devices.  At this time, running LAVA in Docker is not formally supported by Linaro or the LAVA team, but we exploring the possibility that containers enable.  

Using Docker, a new user can have their first LAVA install up and running in a matter of seconds.  

To run the container
```
  sudo docker run -t -i -p 8000:80 -h de2384825135 --privileged=true -v /boot:/boot -v /lib/modules:/lib/modules akbennett/lava
  # NOTE, new command line options for the docker run in order to work with the pipeline devices
  # --privileged=true is necessary to mount an image (uses loopback) within the container
  # NEW: -v /boot:/boot and -v /lib/modules:/lib/modules is neccessary due to libguestfs requireing a kernel and modules before it will run
  # NEW: -h de2384825135  -- with v2, LAVA needs to know the name of the worker machine
```

Once the Container starts, you can submit jobs via the web interface, or run a few sample jobs using the helper script
```
  /submittestjob.sh
  LAUNCH your web browser and navigate to http://localhost:8000
```

# Docker hub tags
* akbennett/lava --> akbennett/latest --> akbennett/lava:lava-demo
* akbennett/lava:lava-demo  # LAVA installed and fully configured to run a demo on a kvm device *unsecure*
