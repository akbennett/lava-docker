FROM debian:jessie-backports

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

# (Optional) Add lava user SSH key and/or configuration
# or mount a host file as a data volume (read-only)
# e.g. -v /path/to/id_rsa_lava.pub:/home/lava/.ssh/authorized_keys:ro
#COPY lava-credentials/.ssh /home/lava/.ssh

ENV LANG en_US.UTF-8

# Remove comment to enable local proxy server (e.g. apt-cacher-ng)
#RUN echo 'Acquire::http { Proxy "http://dockerproxy:3142"; };' >> /etc/apt/apt.conf.d/01proxy

# Install debian packages used by the container
# Configure apache to run the lava server
# Log the hostname used during install for the slave name

RUN echo "deb http://ftp.debian.org/debian jessie-backports main" >> /etc/apt/sources.list

RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
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
 sudo \
 vim \
 && echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen \
 && service postgresql start \
 && debconf-set-selections < /data/preseed.txt \
 && DEBIAN_FRONTEND=noninteractive apt-get -t jessie-backports -y install lava \
 && apt-get -t jessie-backports -y upgrade qemu-system-aarch64 \
 && a2dissite 000-default \
 && a2ensite lava-server \
 && /stop.sh \
 && rm -rf /var/lib/apt/lists/*

# Add lava user with super-user privilege
RUN useradd -m -G plugdev lava \
 && echo 'lava ALL = NOPASSWD: ALL' > /etc/sudoers.d/lava \
 && chmod 0440 /etc/sudoers.d/lava \
 && mkdir -p /var/run/sshd \
 && mkdir -p /home/lava/.ssh \
 && chmod 0700 /home/lava/.ssh \
 && chown -R lava:lava /home/lava/.ssh

# Create a admin user (Insecure note, this creates a default user, username: admin/admin)
RUN /start.sh \
 && /tools/createsuperuser.sh \
 && /stop.sh

# Add devices to the server (ugly, but it works)
RUN /start.sh \
 && lava-server manage pipeline-worker --hostname lava-docker \
 && echo "lava-docker" > /hostname \
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

# To run jobs using python XMLRPC, we need the API token (really ugly)
RUN /start.sh \
 && /tools/getAPItoken.sh \
 && /stop.sh

EXPOSE 22 80
CMD /start.sh && bash
# Following CMD option starts the lava container without a shell and exposes the logs
#CMD /start.sh && tail -f /var/log/lava-*/*
