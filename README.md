# lava-docker
Deploying LAVA in a docker image and getting things ready to execute LAVA jobs.

Run the container
```
  sudo docker run -t -i -p 8000:80 -h de2384825135 --privileged=true -v /boot:/boot -v /lib/modules:/lib/modules akbennett/lava
  # NOTE, new command line options for the docker run in order to work with the pipeline devices
  # --privileged=true is necessary to mount an image (uses loopback) within the container
  # NEW: -v /boot:/boot and -v /lib/modules:/lib/modules is neccessary due to libguestfs requireing a kernel and modules before it will run
  # NEW: -h de2384825135  -- with v2, LAVA needs to know the name of the worker machine
```

Then from inside the container, Start the services and run a set of simple test jobs
```
  /start.sh
  /submittestjob.sh
```

# Docker tags in this project
base-lava-install/ - This Dockerfile creates a base lava installation on Debian sid.  You will have to configure the server
demo-lava-install/ - This Dockerfile and utilities create a fully functional server ready to run jobs on a qemu-system-x86_64 device, a qemu-system-aarch64 and a LAVA v2/pipeline qemu-system-x86_64 device

# Docker hub tags
* akbennett/lava --> akbennett/latest --> akbennett/lava:lava-demo
* akbennett/lava:lava-demo  # LAVA installed and fully configured to run a demo on a kvm device *unsecure*
* akbennett/lava:lava-on-sid  # LAVA installed clean on Debian sid
* akbennett/lava:debian-sid  # Base Debian sid image
