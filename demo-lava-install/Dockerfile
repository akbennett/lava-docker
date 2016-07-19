FROM akbennett/lava:debian-sid

RUN export LANG=en_US.UTF-8

RUN apt-get update && apt-get -y install postgresql

ADD preseed.txt .
RUN debconf-set-selections < /preseed.txt
RUN service postgresql start && \
      apt-get update && \
      DEBIAN_FRONTEND=noninteractive apt-get -y install lava && \
      a2dissite 000-default && \
      a2ensite lava-server && \
      hostname > /hostname  #log the hostname used during install for the slave name

RUN apt-get update && apt-get -y install qemu-system

ADD start.sh .
ADD stop.sh . 

RUN apt-get update && apt-get -y install expect
ADD createsuperuser.sh /tools/
RUN /start.sh && /tools/createsuperuser.sh && /stop.sh 

ADD add-kvm-to-lava.sh /tools/
RUN /start.sh && /tools/add-kvm-to-lava.sh && \
    /usr/share/lava-server/add_device.py kvm kvm01 && \
    /usr/share/lava-server/add_device.py qemu-aarch64 qemu-aarch64-01 && \
    echo "root_part=1" >> /etc/lava-dispatcher/devices/kvm01.conf && \
    /stop.sh

# Add some basic tools and run a job on the server
ADD kvm-basic.json /tools/
ADD kvm-qemu-aarch64.json /tools/

ADD getAPItoken.sh /tools/
RUN /start.sh && /tools/getAPItoken.sh && /stop.sh

ADD submit.py /tools/
ADD submittestjob.sh .
# To use this container, run /start.sh
# To add a test job, run /submittestjob.sh

ADD submityaml.py /tools/
#Add a qemu Pipeline device
ADD qemu.yaml /tools/
RUN /start.sh && mkdir -p /etc/dispatcher-config/devices && \
    cp /usr/lib/python2.7/dist-packages/lava_scheduler_app/tests/devices/qemu01.jinja2 \
       /etc/dispatcher-config/devices/ && \
    echo "{% set arch = 'amd64' %}">> /etc/dispatcher-config/devices/qemu01.jinja2 && \
    echo "{% set base_guest_fs_size = 2048 %}" >> /etc/dispatcher-config/devices/qemu01.jinja2 && \
    lava-server manage device-dictionary --hostname qemu01 \
       --import /etc/dispatcher-config/devices/qemu01.jinja2 && \
    /stop.sh

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

EXPOSE 80
#CMD ["/bin/bash", "/start.sh"]

