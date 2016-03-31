#!/bin/bash
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ `grep DISTRIB_ID /etc/*-release | cut -d= -f2` != 'Ubuntu' ]; then
  echo "This script was written for Ubuntu (apt-get, dpkg, etc)"
  exit 1
fi

#./cleanup.sh

PRODUCTS="packetbeat topbeat filebeat elasticsearch kibana logstash"

XPLUGINS="license marvel-agent shield watcher graph"


# Download latest packages

# ELASTICSEARCH
#wget https://download.elasticsearch.org/elasticsearch/staging/2.3.0-88e7cba/org/elasticsearch/distribution/deb/elasticsearch/2.3.0/elasticsearch-2.3.0.deb
#wget https://download.elasticsearch.org/elasticsearch/staging/2.3.0-95de616/org/elasticsearch/distribution/deb/elasticsearch/2.3.0/elasticsearch-2.3.0.deb
wget https://download.elasticsearch.org/elasticsearch/staging/2.3.0-8371be8/org/elasticsearch/distribution/deb/elasticsearch/2.3.0/elasticsearch-2.3.0.deb

# KIBANA
#wget http://download.elasticsearch.org/kibana/kibana-snapshot/kibana_4.5.0-snapshot_amd64.deb
wget https://download.elastic.co/kibana/kibana/kibana_4.5.0_amd64.deb

# LOGSTASH
#wget https://download.elastic.co/logstash/logstash/logstash_2.3.0~snapshot4-1_all.deb
wget https://download.elastic.co/logstash/logstash/packages/debian/logstash_2.3.0-1_all.deb

# FILEBEAT
#wget https://download.elastic.co/beats/filebeat/filebeat_1.2.0-SNAPSHOT_amd64.deb
wget https://download.elastic.co/beats/filebeat/filebeat_1.2.0_amd64.deb

# TOPBEAT
#wget https://download.elastic.co/beats/topbeat/topbeat_1.2.0-SNAPSHOT_amd64.deb
wget https://download.elastic.co/beats/topbeat/topbeat_1.2.0_amd64.deb

# PACKETBEAT
#wget https://download.elastic.co/beats/packetbeat/packetbeat_1.2.0-SNAPSHOT_amd64.deb
wget https://download.elastic.co/beats/packetbeat/packetbeat_1.2.0_amd64.deb


# Install packages
for i in $PRODUCTS; do echo "-- Installing $i*.deb" & dpkg -i ./$i*.deb; done

# Install Platinum License?

# Configure products
# beats need authentication for elasticsearch
sed -i 's/#username:.*/username: "admin"/' /etc/topbeat/topbeat.yml
sed -i 's/#password:.*/password: "notsecure"/' /etc/topbeat/topbeat.yml

sed -i 's/#username:.*/username: "admin"/' /etc/filebeat/filebeat.yml
sed -i 's/#password:.*/password: "notsecure"/' /etc/filebeat/filebeat.yml

sed -i 's/#username:.*/username: "admin"/' /etc/packetbeat/packetbeat.yml
sed -i 's/#password:.*/password: "notsecure"/' /etc/packetbeat/packetbeat.yml



# Install X-Plugins
#for i in $XPLUGINS; do echo "-- Installing $i plugin" & /usr/share/elasticsearch/bin/plugin -Des.plugins.staging=true install -b $i; done
for i in $XPLUGINS; do echo "-- Installing $i plugin" & /usr/share/elasticsearch/bin/plugin install -b $i; done

# Install Kibana UI Plugins
KPLUGINS="marvel shield sense timelion"
#/opt/kibana/bin/kibana plugin -i marvel -u https://download.elasticsearch.org/elasticsearch/marvel/marvel-2.3.0-SNAPSHOT.tar.gz
/opt/kibana/bin/kibana plugin -i marvel -u https://download.elasticsearch.org/elasticsearch/marvel/marvel-2.3.0.tar.gz

#/opt/kibana/bin/kibana plugin -i shield -u http://download.elastic.co/kibana/shield/shield-2.3.0-SNAPSHOT.tar.gz
/opt/kibana/bin/kibana plugin -i shield -u http://download.elastic.co/kibana/shield/shield-2.3.0.tar.gz

#/opt/kibana/bin/kibana plugin -i graph -u https://download.elasticsearch.org/elasticsearch/graph/graphui-plugin-2.3.0-SNAPSHOT.tar.gz
#/opt/kibana/bin/kibana plugin -i graph -u https://download.elasticsearch.org/elasticsearch/graph/graphui-plugin-2.3.0.tar.gz
/opt/kibana/bin/kibana plugin -i graph -u https://download.elastic.co/elasticsearch/graph/graph-2.3.0.tar.gz
#/opt/kibana/bin/kibana plugin -i elasticsearch/graphui-plugin/latest

## /opt/kibana/bin/kibana plugin -i elasticsearch/marvel
/opt/kibana/bin/kibana plugin -i elastic/sense
/opt/kibana/bin/kibana plugin -i elastic/timelion

# fix an issue in kibana if you install plugins as root before you've started kibana the first time
chown kibana:kibana /opt/kibana/optimize/.babelcache.json

# Create kibana user role
cat kibanaRole.txt >> /etc/elasticsearch/shield/roles.yml



echo "-- Configure Shield users/roles for Kibana and Marvel"
/usr/share/elasticsearch/bin/shield/esusers useradd kibana4 -r kibana4_server -p notsecure
/usr/share/elasticsearch/bin/shield/esusers useradd user -r kibana -p notsecure
/usr/share/elasticsearch/bin/shield/esusers useradd admin -r admin -p notsecure

#/usr/share/elasticsearch/bin/shield/esusers useradd -r marvel_user -p marvel_user_password marvel_user_username
#/usr/share/elasticsearch/bin/shield/esusers roles user -a marvel_user

# curl put watcher config

# curl put watcher trigger data?

echo "-- Configure Kibana with the Shield user"
export KIBANACONF=/opt/kibana/config/kibana.yml
cp $KIBANACONF ${KIBANACONF}.bck
echo elasticsearch.username: "kibana4" >> $KIBANACONF
echo elasticsearch.password: "notsecure" >> $KIBANACONF
echo shield.encryptionKey: "foo" >> $KIBANACONF
echo server.ssl.cert: /home/leedr/Desktop/server.crt >> $KIBANACONF
echo server.ssl.key: /home/leedr/Desktop/server.key >> $KIBANACONF
echo elasticsearch.ssl.ca: /home/leedr/Desktop/ca.zip >> $KIBANACONF
cp /home/leedr/Desktop/ca.zip /etc/elasticsearch/

# Start Services
for i in $PRODUCTS; do echo "-- Starting $i" & service $i start; done

# Create some more noise for packetbeat
ping -c 100 www.google.com >/dev/null &

./check.sh

# load beats-dashboards
cd ./beats-dashboards
./load.sh -url "http://localhost:9200" -user "admin:notsecure"
cd ..

./kibana/node_modules/makelogs/bin/makelogs --auth admin:notsecure

