# lava-docker
Deploying LAVA in a docker image

Run the container
```
  sudo docker run -it -p 8000:80 --privileged=true <IMAGE-ID>
```

base-lava-install/ - This Dockerfile creates a base lava installation on Debian sid.  You will have to configure the server
