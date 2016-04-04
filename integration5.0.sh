#!/bin/bash
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi

if [ `grep DISTRIB_ID /etc/*-release | cut -d= -f2` != 'Ubuntu' ]; then
  echo "This script was written for Ubuntu (apt-get, dpkg, etc)"
  exit 1
fi
version=$(java -version 2>&1 | grep java | sed 's|java version "\(.*\..*\)\..*_.*"|\1|')
if [[ $version < 1.8 ]]; then
  echo "Elasticsearch 5.0 requires java 8."
  exit 1
fi

#./cleanup.sh

PRODUCTS="packetbeat topbeat filebeat elasticsearch kibana logstash"

#XPLUGINS="license marvel-agent shield watcher graph"
XPLUGINS="x-pack"

# Download latest packages

# ELASTICSEARCH
#wget http://download.elastic.co/elasticsearch/staging/5.0.0-alpha1-bf98a44/org/elasticsearch/distribution/deb/elasticsearch/5.0.0-alpha1/elasticsearch-5.0.0-alpha1.deb
#http://s3-eu-west-1.amazonaws.com/build.eu-west-1.elastic.co/origin/master/elasticsearch-latest-SNAPSHOT.zip
#wget http://download.elastic.co/elasticsearch/staging/5.0.0-alpha1-f27399d/org/elasticsearch/distribution/deb/elasticsearch/5.0.0-alpha1/elasticsearch-5.0.0-alpha1.deb
wget http://download.elastic.co/elasticsearch/staging/5.0.0-alpha1-7d4ed5b/org/elasticsearch/distribution/deb/elasticsearch/5.0.0-alpha1/elasticsearch-5.0.0-alpha1.deb

# KIBANA
wget http://download.elasticsearch.org/kibana/kibana-snapshot/kibana_5.0.0-snapshot_amd64.deb

# LOGSTASH
##wget https://download.elastic.co/logstash/logstash/logstash_2.3.0~snapshot1-1_all.deb
wget https://download.elastic.co/logstash/logstash/logstash_5.0.0~alpha1~snapshot1-1_all.deb

# FILEBEAT
wget https://download.elastic.co/beats/filebeat/filebeat_5.0.0-alpha1SNAPSHOT_amd64.deb

# TOPBEAT
wget https://download.elastic.co/beats/topbeat/topbeat_5.0.0-alpha1SNAPSHOT_amd64.deb

# PACKETBEAT
wget https://download.elastic.co/beats/packetbeat/packetbeat_5.0.0-alpha1SNAPSHOT_amd64.deb


# Install packages
for i in $PRODUCTS; do echo "-- Installing $i*.deb" & dpkg -i ./$i*.deb; done

# Install Platinum License?

# Configure products
# beats need authentication for elasticsearch
#sed -i 's/#username:.*/username: "admin"/' /etc/topbeat/topbeat.yml
#sed -i 's/#password:.*/password: "notsecure"/' /etc/topbeat/topbeat.yml

#sed -i 's/#username:.*/username: "admin"/' /etc/filebeat/filebeat.yml
#sed -i 's/#password:.*/password: "notsecure"/' /etc/filebeat/filebeat.yml

#sed -i 's/#username:.*/username: "admin"/' /etc/packetbeat/packetbeat.yml
#sed -i 's/#password:.*/password: "notsecure"/' /etc/packetbeat/packetbeat.yml


# Install X-Plugins  --------- Just XPACK ??
#wget https://dl.dropboxusercontent.com/u/8469532/xpack-5.0.0-alpha1-snapshot.zip
#/usr/share/elasticsearch/bin/elasticsearch-plugin install file:./xpack-5.0.0-alpha1-snapshot.zip
/usr/share/elasticsearch/bin/elasticsearch-plugin install -b -Des.plugins.staging=true x-pack

#/usr/share/elasticsearch/bin/elasticsearch-plugin -Des.plugins.staging=true install -b x-pack

# Install Kibana UI Plugins
KPLUGINS="marvel shield sense timelion"
#/opt/kibana/bin/kibana-plugin install marvel -u https://download.elasticsearch.org/elasticsearch/marvel/marvel-2.3.0-SNAPSHOT.tar.gz
#/opt/kibana/bin/kibana-plugin install shield -u http://download.elastic.co/kibana/shield/shield-2.3.0-SNAPSHOT.tar.gz
#/opt/kibana/bin/kibana-plugin install graph -u https://download.elasticsearch.org/elasticsearch/graph/graphui-plugin-2.3.0-SNAPSHOT.tar.gz

## /opt/kibana/bin/kibana-plugin install elasticsearch/marvel
#/opt/kibana/bin/kibana-plugin install elastic/sense
#/opt/kibana/bin/kibana-plugin install elastic/timelion
/opt/kibana/bin/kibana-plugin install https://download.elasticsearch.org/kibana/timelion/timelion-5.0.0-0.1.259.zip
/opt/kibana/bin/kibana-plugin install http://download.elasticsearch.org/kibana/kibana/xpack-5.0.0-alpha1.zip
# fix an issue in kibana if you install plugins as root before you've started kibana the first time
chown kibana:kibana /opt/kibana/optimize/.babelcache.json

# Create kibana user role
cat kibanaRole.txt >> /etc/elasticsearch/x-pack/roles.yml


echo "-- Configure Shield users/roles for Kibana and Marvel"
/usr/share/elasticsearch/bin/x-pack/users list
/usr/share/elasticsearch/bin/x-pack/users useradd kibana4 -r kibana4_server -p notsecure
/usr/share/elasticsearch/bin/x-pack/users useradd user -r kibana -p notsecure
/usr/share/elasticsearch/bin/x-pack/users useradd admin -r admin -p notsecure

#/usr/share/elasticsearch/bin/shield/esusers useradd -r marvel_user -p marvel_user_password marvel_user_username
#/usr/share/elasticsearch/bin/shield/esusers roles user -a marvel_user

# curl put watcher config

# curl put watcher trigger data?

echo "-- Configure Kibana with the Shield user"
export KIBANACONF=/opt/kibana/config/kibana.yml
cp $KIBANACONF ${KIBANACONF}.bck
echo elasticsearch.username: "kibana4" >> $KIBANACONF
echo elasticsearch.password: "notsecure" >> $KIBANACONF
echo xpack.security.encryptionKey: "foo" >> $KIBANACONF
echo server.ssl.cert: /home/leedr/Desktop/server.crt >> $KIBANACONF
echo server.ssl.key: /home/leedr/Desktop/server.key >> $KIBANACONF
echo elasticsearch.ssl.ca: /home/leedr/Desktop/ca.zip >> $KIBANACONF
cp /home/leedr/Desktop/ca.zip /etc/elasticsearch/

# Start Services
for i in $PRODUCTS; do echo "-- Starting $i" & service $i start; done

ping -c 100 www.google.com >/dev/null &


./check5.0.sh

# load beats-dashboards
pushd ../beats-dashboards
git pull
./load.sh -url "http://localhost:9200" -user "admin:notsecure"
popd

npm install -g makelogs@3.0.0-beta4
makelogs --auth admin:notsecure 


