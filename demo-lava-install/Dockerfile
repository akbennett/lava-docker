FROM akbennett/lava:debian-sid

RUN apt-get update
RUN export LANG=en_US.UTF-8

RUN apt-get -y install postgresql

ADD preseed.txt .
RUN debconf-set-selections < /preseed.txt
RUN service postgresql start && DEBIAN_FRONTEND=noninteractive apt-get -y install lava
RUN a2dissite 000-default
RUN a2ensite lava-server

RUN apt-get -y install expect
RUN apt-get -y install qemu-system

ADD start.sh .
ADD stop.sh . 

RUN apt-get -y install expect
ADD createsuperuser.sh /tools/
RUN /start.sh && /tools/createsuperuser.sh && /stop.sh 

ADD add-kvm-to-lava.sh /tools/
RUN /start.sh && /tools/add-kvm-to-lava.sh && /stop.sh
RUN /start.sh && /usr/share/lava-server/add_device.py kvm kvm01 && \
                 /usr/share/lava-server/add_device.py qemu-aarch64 qemu-aarch64-01 && /stop.sh
RUN echo "root_part=1" >> /etc/lava-dispatcher/devices/kvm01.conf

# Add some basic tools and run a job on the server
ADD kvm-basic.json /tools/
ADD kvm-qemu-aarch64.json /tools/

ADD getAPItoken.sh /tools/
RUN /start.sh && /tools/getAPItoken.sh && /stop.sh

ADD submit.py /tools/
ADD submittestjob.sh .
# To use this container, run /start.sh
# To add a test job, run /submittestjob.sh

CMD ["/bin/bash", "/start.sh"]
