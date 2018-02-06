FROM boritzio/docker-base
MAINTAINER Maxime Devalland <maxime@factual.com>

RUN echo "deb http://archive.ubuntu.com/ubuntu xenial main universe" > /etc/apt/sources.list
RUN apt-get -q -y update
RUN apt-get -q -y install software-properties-common wget unzip curl
RUN apt-key adv --recv-keys --keyserver hkp://keyserver.ubuntu.com:80 0xF1656F24C74CD1D8
RUN add-apt-repository 'deb [arch=amd64,i386,ppc64el] http://mirror.daniel-jost.net/mariadb/repo/10.1/ubuntu xenial main'
RUN apt-get -q -y update
RUN echo mariadb-server mysql-server/root_password password root | debconf-set-selections
RUN echo mariadb-server mysql-server/root_password_again password root | debconf-set-selections
RUN LC_ALL=en_US.utf8 DEBIAN_FRONTEND=noninteractive apt-get -o Dpkg::Options::='--force-confnew' -qqy install mariadb-server
RUN service mysql restart
#SSHD
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y openssh-server &&	mkdir -p /var/run/sshd && \
    echo 'root:root' |chpasswd
ADD sshd_config /etc/ssh/sshd_config
RUN service ssh restart

#clean up
RUN apt-get -q -y autoremove && \
 apt-get -q -y clean

ADD start /bin/start
RUN chmod +x /bin/start
