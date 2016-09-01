FROM debian:jessie-backports

MAINTAINER Alan Bennett <alan.bennett@linaro.org>
LABEL Version="1.0" Description="lava running in docker and minimally configured"

# Add services helper utilities to start and stop LAVA
COPY stop.sh .
COPY start.sh .

# Install debian packages used by the container
# Configure apache to run the lava server
# Log the hostname used during install for the slave name
RUN echo 'lava-server   lava-server/instance-name string lava-docker-instance' | debconf-set-selections \
 && echo 'locales locales/locales_to_be_generated multiselect C.UTF-8 UTF-8, en_US.UTF-8 UTF-8 ' | debconf-set-selections \
 && echo 'locales locales/default_environment_locale select en_US.UTF-8' | debconf-set-selections \
 && apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y \
 android-tools-fastboot \
 cu \
 expect \
 lava-coordinator \
 lava-dev \
 lava-dispatcher \
 lava-tool \
 linaro-image-tools \
 locales \
 openssh-server \
 postgresql \
 screen \
 sudo \
 vim \
 && service postgresql start \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y -t jessie-backports \
 lava \
 qemu-system \
 && a2dissite 000-default \
 && a2ensite lava-server \
 && /stop.sh \
 && rm -rf /var/lib/apt/lists/*

# Add lava user with super-user privilege
RUN useradd -m -G plugdev lava \
 && echo 'lava ALL = NOPASSWD: ALL' > /etc/sudoers.d/lava \
 && chmod 0440 /etc/sudoers.d/lava \
 && mkdir -p /var/run/sshd /home/lava/bin /home/lava/.ssh \
 && chmod 0700 /home/lava/.ssh \
 && chown -R lava:lava /home/lava/bin /home/lava/.ssh

# Add some job submission utilities
COPY submittestjob.sh /home/lava/bin/
COPY *.json *.py *.yaml /home/lava/bin/

# Add misc utilities
COPY createsuperuser.sh add-kvm-to-lava.sh getAPItoken.sh lava-credentials.txt /home/lava/bin/

# (Optional) Add lava user SSH key and/or configuration
# or mount a host file as a data volume (read-only)
# e.g. -v /path/to/id_rsa_lava.pub:/home/lava/.ssh/authorized_keys:ro
#COPY lava-credentials/.ssh /home/lava/.ssh

# Remove comment to enable local proxy server (e.g. apt-cacher-ng)
#RUN echo 'Acquire::http { Proxy "http://dockerproxy:3142"; };' >> /etc/apt/apt.conf.d/01proxy

# Create a admin user (Insecure note, this creates a default user, username: admin/admin)
RUN /start.sh \
 && /home/lava/bin/createsuperuser.sh \
 && /stop.sh

# Add devices to the server (ugly, but it works)
RUN /start.sh \
 && lava-server manage pipeline-worker --hostname lava-docker \
 && echo "lava-docker" > /home/lava/bin/hostname.txt \
 && /home/lava/bin/add-kvm-to-lava.sh \
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
 && /home/lava/bin/getAPItoken.sh \
 && /stop.sh

EXPOSE 22 80
CMD /start.sh && bash
# Following CMD option starts the lava container without a shell and exposes the logs
#CMD /start.sh && tail -f /var/log/lava-*/*
