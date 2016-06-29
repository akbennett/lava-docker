FROM akbennett/lava:debian-sid

RUN apt-get update
RUN export LANG=en_US.UTF-8

RUN apt-get -y install postgresql

ADD preseed.txt .
RUN debconf-set-selections < /preseed.txt
RUN service postgresql start && DEBIAN_FRONTEND=noninteractive apt-get -y install lava
RUN a2dissite 000-default
RUN a2ensite lava-server

ADD start.sh .
