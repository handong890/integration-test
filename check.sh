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

rm index.html*
# try 10 times, 2 seconds apart
echo -e "\n-----------------Elasticserach----------------------------------------"
for i in `seq 1 10`; do echo "wget es index" && sleep 2 && wget -q --http-user=elastic --http-password=changeme http://localhost:9200 && break; done
cat index.html

echo -e "\n-----------------Kibana log-------------------------------------------"
# try 10 times, 2 seconds apart
for i in `seq 1 10`; do echo "grep kibana log for 'green'" && sleep 2 &&  journalctl -u kibana.service --since "5 minutes ago"| grep "plugin:elasticsearch.*green" && break; done
#journalctl --since "2016-03-30"
#journalctl -u kibana.service
echo -e "\n----------------------------------------------------------------------"
#/usr/share/elasticsearch/bin/xpack/esusers useradd admin -r admin -p notsecure

echo -e "\n-----------------Shield File Users-----------------------------------------"
/usr/share/elasticsearch/bin/x-pack/users list
echo -e "\n-----------------Shield Native Users-----------------------------------------"
curl GET http://elastic:changeme@localhost:9200/_shield/user?pretty

