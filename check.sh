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

XPLUGINS="license marvel-agent shield watcher"

echo -e "\n-----------------Package Information----------------------------------"
dpkg --list $PRODUCTS

echo -e "\n-----------------Service Status---------------------------------------"
for i in $PRODUCTS; do service $i status; done

echo -e "\n-----------------Shield Users-----------------------------------------"
/usr/share/elasticsearch/bin/shield/esusers list

rm index.html*
# try 10 times, 2 seconds apart
echo -e "\n-----------------Elasticserach----------------------------------------"
for i in `seq 1 10`; do echo "wget es index" && sleep 2 && wget -q --http-user=admin --http-password=notsecure localhost:9200 && break; done
cat index.html

echo -e "\n-----------------Kibana log-------------------------------------------"
# try 10 times, 2 seconds apart
for i in `seq 1 10`; do echo "grep kibana log for 'green'" && sleep 2 && grep "plugin:elasticsearch.*green" /var/log/kibana/kibana.stdout && break; done
echo -e "\n----------------------------------------------------------------------"

~
