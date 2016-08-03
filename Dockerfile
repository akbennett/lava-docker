FROM debian:sid

# Add services helper utilities to start and stop LAVA
COPY stop.sh .
COPY start.sh .

# Add some job submission utilities
COPY submittestjob.sh .
COPY *.json /tools/
COPY *.py /tools/
COPY *.yaml /tools/

# Add misc utilities
COPY createsuperuser.sh /tools/
COPY add-kvm-to-lava.sh /tools/
COPY getAPItoken.sh /tools/
COPY preseed.txt /data/

ENV DEBIAN_FRONTEND noninteractive
ENV LANG en_US.UTF-8

# Remove comment to enable local proxy server (e.g. apt-cacher-ng)
#RUN echo 'Acquire::http { Proxy "http://dockerproxy:3142"; };' >> /etc/apt/apt.conf.d/01proxy

# Install debian packages used by the container
# Configure apache to run the lava server
# Log the hostname used during install for the slave name
RUN apt-get update \
 && apt-get install -y \
 android-tools-fastboot \
 cu \
 expect \
 lava-coordinator \
 lava-dev \
 lava-dispatcher \
 lava-tool \
 linaro-image-tools \
 openssh-server \
 postgresql \
 qemu-system \
 screen \
 vim \
 && service postgresql start \
 && debconf-set-selections < /data/preseed.txt \
 && apt-get -y install lava \
 && a2dissite 000-default \
 && a2ensite lava-server \
 && /stop.sh \
 && hostname > /hostname \
 && rm -rf /var/lib/apt/lists/*

# Create a admin user (Insecure note, this creates a default user, username: admin/admin)
RUN /start.sh \
 && /tools/createsuperuser.sh \
 && /stop.sh

# Add devices to the server (ugly, but it works)
RUN /start.sh \
 && /tools/add-kvm-to-lava.sh \
 && /usr/share/lava-server/add_device.py kvm kvm01 \
 && /usr/share/lava-server/add_device.py qemu-aarch64 qemu-aarch64-01 \
 && echo "root_part=1" >> /etc/lava-dispatcher/devices/kvm01.conf \
 && /stop.sh

# Add a Pipeline device
RUN /start.sh \
 && mkdir -p /etc/dispatcher-config/devices \
 && cp -a /usr/lib/python2.7/dist-packages/lava_scheduler_app/tests/devices/qemu01.jinja2 /etc/dispatcher-config/devices/ \
 && echo "{% set arch = 'amd64' %}">> /etc/dispatcher-config/devices/qemu01.jinja2 \
 && echo "{% set base_guest_fs_size = 2048 %}" >> /etc/dispatcher-config/devices/qemu01.jinja2 \
 && lava-server manage device-dictionary --hostname qemu01 --import /etc/dispatcher-config/devices/qemu01.jinja2 \
 && /stop.sh

# CORTEX-M3: add python-sphinx-bootstrap-theme
RUN sudo apt-get update && apt-get install -y python-sphinx-bootstrap-theme \
 && rm -rf /var/lib/apt/lists/*

# CORTEX-M3: apply patches to enable cortex-m3 support
COPY monitor-test-jobs-hack.patch /tools
RUN /start.sh && \
    echo "CORTEX-M3: adding patches for lava-dispatcher" && \
    git clone -b master https://github.com/linaro/lava-dispatcher /lava-dispatcher && \
    #cd /lava-dispatcher && git checkout e545969affcc449d833b2fcd3b8efe2d966f72a3 && \
    cd /lava-dispatcher && \
        git fetch https://review.linaro.org/lava/lava-dispatcher refs/changes/11/12711/5 && git cherry-pick FETCH_HEAD && \
    echo "CORTEX-M3: adding patches for lava-server" && \
    git clone -b master https://github.com/linaro/lava-server /lava-server && \
    #cd /lava-server && git checkout 30facc1290ad2dd28ed4ad41ff971546e360f92e && \
    cd /lava-server && \
        git fetch https://review.linaro.org/lava/lava-server refs/changes/70/12670/1 && git cherry-pick FETCH_HEAD && \
        git fetch https://review.linaro.org/lava/lava-server refs/changes/23/12723/2 && git cherry-pick FETCH_HEAD && \
        git am /tools/monitor-test-jobs-hack.patch && \
    echo "CORTEX-M3: add build then install capability to debian-dev-build.sh" && \
    echo "cd \${DIR} && dpkg -i *.deb" >> /lava-server/share/debian-dev-build.sh && \
    echo "CORTEX-M3: Installing patched versions of dispatcher & server" && \
    cd /lava-dispatcher && /lava-server/share/debian-dev-build.sh -p lava-dispatcher && \
    cd /lava-server && /lava-server/share/debian-dev-build.sh -p lava-server && \
    /stop.sh

# CORTEX-M3: add a qemu-cortex-m3 Pipeline device
COPY qemu-cortex-m3.yaml /tools/
COPY qemu-cortex-m3-01.jinja2 /etc/dispatcher-config/devices/
RUN /start.sh && \
    lava-server manage device-dictionary --hostname qemu-cortex-m3-01 \
       --import /etc/dispatcher-config/devices/qemu-cortex-m3-01.jinja2 && \
    /stop.sh

# To run jobs using python XMLRPC, we need the API token (really ugly)
RUN /start.sh \
 && /tools/getAPItoken.sh \
 && /stop.sh

# Add support for SSH for remote configuration
RUN mkdir /var/run/sshd \
 && sed -i 's/PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config \
 && echo 'root:password' | chpasswd

EXPOSE 22 80
CMD /start.sh && bash
# Following CMD option starts the lava container without a shell and exposes the logs
#CMD /start.sh && tail -f /var/log/lava-*/*
