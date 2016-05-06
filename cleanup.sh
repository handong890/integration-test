#!/bin/bash
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ `grep DISTRIB_ID /etc/*-release | cut -d= -f2` != 'Ubuntu' ]; then
  echo "This script was written for Ubuntu (apt-get, dpkg, etc)"
  exit 1
fi

PRODUCTS="packetbeat topbeat filebeat elasticsearch kibana logstash"



# Stop Services, Remove Services, Delete Packages 
for i in $PRODUCTS; do echo "-- Stopping $i" & service $i stop; done

for i in $PRODUCTS; do echo "-- apt-get purge $i" & apt-get purge -y -q $i; done
for i in $PRODUCTS; do echo "-- dpkg --purge $i" & dpkg --purge $i; done

# Kibana cleanup
rm -rf /opt/kibana

# Elasticsearch cleanup
rm -rf /var/log/elasticsearch
rm -rf /var/lib/elasticsearch
rm -rf /etc/elasticsearch
rm -rf /usr/share/elasticsearch

rm -rf /var/log/logstash
rm -rf /var/lib/logstash

rm -rf /var/log/kibana

#for i in $PRODUCTS; do echo "-- Deleting $i*.deb" & rm $i*.deb; done

