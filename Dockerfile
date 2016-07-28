FROM akbennett/lava:debian-sid

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

# Create a admin user
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

# add python-sphinx-bootstrap-theme
RUN sudo apt-get update && apt-get install -y python-sphinx-bootstrap-theme

#Apply patches to enable cortex-m3 support
ADD monitor-test-jobs-hack.patch /tools
RUN /start.sh && \
    echo "add build then install capability to debian-dev-build.sh" && \
    echo "cd \${DIR} && dpkg -i *.deb" >> /usr/share/lava-server/debian-dev-build.sh && \
    echo "adding patches for dispatcher" && \
    cd / && git clone https://github.com/linaro/lava-dispatcher && cd /lava-dispatcher && git checkout master && \
    #cd /lava-dispatcher && git checkout e545969affcc449d833b2fcd3b8efe2d966f72a3 && \
    cd /lava-dispatcher && git fetch https://review.linaro.org/lava/lava-dispatcher refs/changes/11/12711/5 && git cherry-pick FETCH_HEAD && \
    echo "adding patches for server" && \
    cd / && git clone https://github.com/linaro/lava-server && cd /lava-server && git checkout master && \
    #cd /lava-server && git checkout 30facc1290ad2dd28ed4ad41ff971546e360f92e && \
    cd /lava-server && git fetch https://review.linaro.org/lava/lava-server refs/changes/70/12670/1 && git cherry-pick FETCH_HEAD && \
    cd /lava-server && git fetch https://review.linaro.org/lava/lava-server refs/changes/23/12723/2 && git cherry-pick FETCH_HEAD && \
    cd /lava-server && git am /tools/monitor-test-jobs-hack.patch && \
    echo "Installing patched versions of dispatcher & server" && \
    cd /lava-dispatcher && /usr/share/lava-server/debian-dev-build.sh -p lava-dispatcher && \
    cd /lava-server && /usr/share/lava-server/debian-dev-build.sh -p lava-server &&\
    /stop.sh

#Add a qemu-cortex-m3 Pipeline device
ADD qemu-cortex-m3.yaml /tools/
ADD qemu-cortex-m3-01.jinja2 /etc/dispatcher-config/devices/
RUN /start.sh && \
    lava-server manage device-dictionary --hostname qemu-cortex-m3-01 \
       --import /etc/dispatcher-config/devices/qemu-cortex-m3-01.jinja2 && \
    /stop.sh

# Add some job submission utilities
ADD submit.py /tools/
ADD submityaml.py /tools/
ADD submittestjob.sh .
ADD kvm-basic.json /tools/
ADD kvm-qemu-aarch64.json /tools/
ADD qemu.yaml /tools/

EXPOSE 80
CMD bash -C '/start.sh' && \
    '/bin/bash'

