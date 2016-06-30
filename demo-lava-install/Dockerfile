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
ADD createsuperuser.sh .
RUN /start.sh && /createsuperuser.sh && /stop.sh 

ADD add-kvm-to-lava.sh .
RUN /start.sh && /add-kvm-to-lava.sh && /stop.sh
RUN /start.sh && /usr/share/lava-server/add_device.py kvm kvm01 && /stop.sh
RUN echo "root_part=1" >> /etc/lava-dispatcher/devices/kvm02.conf

ADD kvm.json .
