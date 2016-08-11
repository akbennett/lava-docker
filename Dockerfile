FROM debian:jessie-backports

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

# CORTEX-M3: add python-sphinx-bootstrap-theme
RUN sudo apt-get update && apt-get install -y python-sphinx-bootstrap-theme node-uglify docbook-xsl xsltproc python-mock \
 && rm -rf /var/lib/apt/lists/*

# CORTEX-M3: apply patches to enable cortex-m3 support
COPY monitor-test-jobs-hack.patch /home/lava/
RUN /start.sh \
 && echo "CORTEX-M3: adding patches for lava-dispatcher" \
 && git clone -b master https://github.com/linaro/lava-dispatcher /home/lava/lava-dispatcher \
 && cd /home/lava/lava-dispatcher \
 && git checkout 8753b43 \
 && git fetch https://review.linaro.org/lava/lava-dispatcher refs/changes/11/12711/9 && git cherry-pick FETCH_HEAD \
 && echo "CORTEX-M3: adding patches for lava-server" \
 && git clone -b master https://github.com/linaro/lava-server /home/lava/lava-server \
 # && cd /home/lava/lava-server && git checkout 30facc1290ad2dd28ed4ad41ff971546e360f92e \
 && cd /home/lava/lava-server \
 && git fetch https://review.linaro.org/lava/lava-server refs/changes/70/12670/1 && git cherry-pick FETCH_HEAD \
 && git fetch https://review.linaro.org/lava/lava-server refs/changes/23/12723/3 && git cherry-pick FETCH_HEAD \
 && git am /home/lava/monitor-test-jobs-hack.patch \
 && echo "CORTEX-M3: add build then install capability to debian-dev-build.sh" \
 && echo "cd \${DIR} && dpkg -i *.deb" >> /home/lava/lava-server/share/debian-dev-build.sh \
 && echo "CORTEX-M3: Installing patched versions of dispatcher & server" \
 && cd /home/lava/lava-dispatcher && /home/lava/lava-server/share/debian-dev-build.sh -p lava-dispatcher \
 && cd /home/lava/lava-server && /home/lava/lava-server/share/debian-dev-build.sh -p lava-server \
 && /stop.sh

# CORTEX-M3: add a qemu-cortex-m3 Pipeline device
COPY qemu-cortex-m3-01.jinja2 /etc/dispatcher-config/devices/
RUN /start.sh \
 && lava-server manage device-dictionary --hostname qemu-cortex-m3-01 \
       --import /etc/dispatcher-config/devices/qemu-cortex-m3-01.jinja2 \
 && /stop.sh

# To run jobs using python XMLRPC, we need the API token (really ugly)
RUN /start.sh \
 && /home/lava/bin/getAPItoken.sh \
 && /stop.sh

EXPOSE 22 80
CMD /start.sh && bash
# Following CMD option starts the lava container without a shell and exposes the logs
#CMD /start.sh && tail -f /var/log/lava-*/*
