# lava-docker
Deploying LAVA in a docker image

Run the container
```
  sudo docker run -it -p 8000:80 --privileged=true akbennett/lava
```

Then from inside the container, Start the services and run a simple test job
```
  /start.sh
  /submittestjob.sh
```

# Docker tags in this project
base-lava-install/ - This Dockerfile creates a base lava installation on Debian sid.  You will have to configure the server
demo-lava-install/ - This Dockerfile and utilities create a fully functional server ready to run jobs on a qemu-system-x86_64 device

# Docker hub tags
* akbennett/lava --> akbennett/latest --> akbennett/lava:lava-demo
* akbennett/lava:lava-demo  # LAVA installed and fully configured to run a demo on a kvm device *unsecure*
* akbennett/lava:lava-on-sid  # LAVA installed clean on Debian sid
* akbennett/lava:debian-sid  # Base Debian sid image
