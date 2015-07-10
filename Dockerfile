############################################################
# Dockerfile to build DELLY workflow container
# Based on Ubuntu
############################################################

# Set the base image to Ubuntu
FROM ubuntu

# File Author / Maintainer
MAINTAINER Brian O'Connor <boconnor@oicr.on.ca>

USER root
RUN apt-get -m update

RUN apt-get install -y make gcc libconfig-simple-perl libdbd-sqlite3-perl \
    libjson-perl apache2 libcgi-session-perl libipc-system-simple-perl \
    libcarp-always-perl libdata-dumper-simple-perl libio-socket-ssl-perl \
    sqlite3 libsqlite3-dev libcapture-tiny-perl git cpan

RUN a2enmod cgi

RUN cd /usr/lib/cgi-bin/ && 

COPY scripts/* /usr/bin/
RUN echo 'install.packages("/usr/bin/DNAcopy_1.38.1.tar.gz")' >> /tmp/dnacopy; R CMD BATCH /tmp/dnacopy
COPY DELLY /home/seqware/DELLY
RUN chown -R seqware /home/seqware/DELLY
USER seqware
WORKDIR /home/seqware/DELLY/
RUN mvn clean install
CMD ["/bin/bash", "/start.sh"]
