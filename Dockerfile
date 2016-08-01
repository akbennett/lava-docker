FROM debian:sid

RUN export LANG=en_US.UTF-8

#start and stop services helper utilities
ADD stop.sh .
ADD start.sh .

#install lava and configure apache to run the lava server
ADD preseed.txt /data/
RUN apt-get update && apt-get install -y postgresql && \
    service postgresql start && \
    debconf-set-selections < /data/preseed.txt && \
    DEBIAN_FRONTEND=noninteractive apt-get -y install lava && \
    a2dissite 000-default && \
    a2ensite lava-server && \ 
    /stop.sh && \
    hostname > /hostname  #log the hostname used during install for the slave name 

# Add qemu-system so we can run jobs on a qemu target
RUN apt-get update && apt-get -y install qemu-system

# Create a admin user (Insecure note, this creates a default user, username: admin/admin)
ADD createsuperuser.sh /tools/
RUN apt-get update && apt-get -y install expect && \
    /start.sh && /tools/createsuperuser.sh && /stop.sh 

# Add devices to the server (ugly, but it works)
ADD add-kvm-to-lava.sh /tools/
RUN /start.sh && /tools/add-kvm-to-lava.sh && \
    /usr/share/lava-server/add_device.py kvm kvm01 && \
    /usr/share/lava-server/add_device.py qemu-aarch64 qemu-aarch64-01 && \
    echo "root_part=1" >> /etc/lava-dispatcher/devices/kvm01.conf && \
    /stop.sh

# To run jobs using python XMLRPC, we need the API token (really ugly)
ADD getAPItoken.sh /tools/
RUN /start.sh && /tools/getAPItoken.sh && /stop.sh

#Add a Pipeline device
RUN /start.sh && mkdir -p /etc/dispatcher-config/devices && \
    cp /usr/lib/python2.7/dist-packages/lava_scheduler_app/tests/devices/qemu01.jinja2 \
       /etc/dispatcher-config/devices/ && \
    echo "{% set arch = 'amd64' %}">> /etc/dispatcher-config/devices/qemu01.jinja2 && \
    echo "{% set base_guest_fs_size = 2048 %}" >> /etc/dispatcher-config/devices/qemu01.jinja2 && \
    lava-server manage device-dictionary --hostname qemu01 \
       --import /etc/dispatcher-config/devices/qemu01.jinja2 && \
    /stop.sh

# Add some job submission utilities
ADD submit.py /tools/
ADD submityaml.py /tools/
ADD submittestjob.sh .
ADD kvm-basic.json /tools/
ADD kvm-qemu-aarch64.json /tools/
ADD qemu.yaml /tools/

# Add additional packages for remote configuration
#  -- Add SSH
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd
RUN sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
RUN echo 'root:password' | chpasswd
EXPOSE 22

# Install basic tools for physically connected LAVA target control 
RUN apt-get update && \
     apt-get -y install vim && \
     apt-get -y install android-tools-fastboot && \
     apt-get -y install cu && \
     apt-get -y install screen

EXPOSE 80
CMD bash -C '/start.sh' && \
    '/usr/sbin/sshd' && \
    '/bin/bash'

