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

XPLUGINS="license marvel-agent shield watcher graph"


# Download latest packages

# ELASTICSEARCH
#wget http://download.elastic.co/elasticsearch/staging/5.0.0-alpha1-bf98a44/org/elasticsearch/distribution/deb/elasticsearch/5.0.0-alpha1/elasticsearch-5.0.0-alpha1.deb
#http://s3-eu-west-1.amazonaws.com/build.eu-west-1.elastic.co/origin/master/elasticsearch-latest-SNAPSHOT.zip
wget http://download.elastic.co/elasticsearch/staging/5.0.0-alpha2-e3126df/org/elasticsearch/distribution/deb/elasticsearch/5.0.0-alpha2/elasticsearch-5.0.0-alpha2.deb

# KIBANA
#wget http://download.elasticsearch.org/kibana/kibana-snapshot/kibana_5.0.0-snapshot_amd64.deb
#wget https://download.elastic.co/kibana/kibana/kibana-5.0.0-alpha2-rc1-linux-x64.tar.gz
wget https://download.elastic.co/kibana/kibana/kibana_5.0.0-alpha2_amd64.deb

# LOGSTASH
#wget https://download.elastic.co/logstash/logstash/logstash_2.3.0~snapshot1-1_all.deb
wget https://download.elastic.co/logstash/logstash/logstash-5.0.0-alpha2.snapshot2_all.deb

# FILEBEAT
#wget https://download.elastic.co/beats/filebeat/filebeat_5.0.0-alpha1SNAPSHOT_amd64.deb
wget https://download.elastic.co/beats/filebeat/filebeat_5.0.0-alpha2SNAPSHOT_amd64.deb

# TOPBEAT
#wget https://download.elastic.co/beats/topbeat/topbeat_5.0.0-alpha1SNAPSHOT_amd64.deb
wget https://download.elastic.co/beats/topbeat/topbeat_5.0.0-alpha2SNAPSHOT_amd64.deb

# PACKETBEAT
#wget https://download.elastic.co/beats/packetbeat/packetbeat_5.0.0-alpha1SNAPSHOT_amd64.deb
wget https://download.elastic.co/beats/packetbeat/packetbeat_5.0.0-alpha2SNAPSHOT_amd64.deb

# Install packages
for i in $PRODUCTS; do echo "-- Installing $i*.deb" & dpkg -i ./$i*.deb; done

# Install Platinum License?

# Configure products
# beats need authentication for elasticsearch
sed -i 's/#username:.*/username: "elastic"/' /etc/topbeat/topbeat.yml
sed -i 's/#password:.*/password: "changeme"/' /etc/topbeat/topbeat.yml

sed -i 's/#username:.*/username: "elastic"/' /etc/filebeat/filebeat.yml
sed -i 's/#password:.*/password: "changeme"/' /etc/filebeat/filebeat.yml

sed -i 's/#username:.*/username: "elastic"/' /etc/packetbeat/packetbeat.yml
sed -i 's/#password:.*/password: "changeme"/' /etc/packetbeat/packetbeat.yml


# Install X-Plugins  --------- Just XPACK ??
#wget https://dl.dropboxusercontent.com/u/8469532/xpack-5.0.0-alpha1-snapshot.zip
#/usr/share/elasticsearch/bin/elasticsearch-plugin install file:./xpack-5.0.0-alpha1-snapshot.zip
#wget http://download.elastic.co/kibana/x-pack/x-pack-5.0.0-snapshot.zip
#/usr/share/elasticsearch/bin/elasticsearch-plugin install file:./x-pack-5.0.0-snapshot.zip
/usr/share/elasticsearch/bin/elasticsearch-plugin install -b x-pack

#for i in $XPLUGINS; do echo "-- Installing $i plugin" & /usr/share/elasticsearch/bin/plugin -Des.plugins.staging=true install -b $i; done
#for i in $XPLUGINS; do echo "-- Installing $i plugin" & /usr/share/elasticsearch/bin/plugin install -b $i; done

# Install Kibana UI Plugins
#KPLUGINS="marvel shield sense timelion"
#/opt/kibana/bin/kibana plugin -i marvel -u https://download.elasticsearch.org/elasticsearch/marvel/marvel-2.3.0-SNAPSHOT.tar.gz
#/opt/kibana/bin/kibana plugin -i shield -u http://download.elastic.co/kibana/shield/shield-2.3.0-SNAPSHOT.tar.gz
#/opt/kibana/bin/kibana plugin -i graph -u https://download.elasticsearch.org/elasticsearch/graph/graphui-plugin-2.3.0-SNAPSHOT.tar.gz
#/opt/kibana/bin/kibana plugin -i timelion -u https://download.elasticsearch.org/kibana/timelion/timelion-5.0.0-0.1.271.zip
## /opt/kibana/bin/kibana plugin -i elasticsearch/marvel
#/opt/kibana/bin/kibana plugin -i elastic/sense
#/opt/kibana/bin/kibana plugin -i elastic/timelion
/opt/kibana/bin/kibana-plugin install timelion
/opt/kibana/bin/kibana-plugin install x-pack


# fix an issue in kibana if you install plugins as root before you've started kibana the first time
#chown kibana:kibana /opt/kibana/optimize/.babelcache.json
# T O   D O - resolve this issue
chown -R kibana:kibana /opt/kibana

# Create kibana user role
cat kibanaRole.txt >> /etc/elasticsearch/x-pack/roles.yml



echo "-- Configure Shield users/roles for Kibana and Marvel"
#/usr/share/elasticsearch/bin/xpack/esusers useradd kibana4 -r kibana4_server -p notsecure
/usr/share/elasticsearch/bin/x-pack/users useradd user -r kibanaUser -p notsecure

#POST /_shield/user/ironman
#{
#  "password" : "j@rV1s",
#  "roles" : [ "admin", "other_role1" ],
#  "full_name" : "Tony Stark",
#  "email" : "tony@starkcorp.co",
#  "metadata" : {
#    "intelligence" : 7
#  }
#}


#/usr/share/elasticsearch/bin/shield/esusers useradd -r marvel_user -p marvel_user_password marvel_user_username
#/usr/share/elasticsearch/bin/shield/esusers roles user -a marvel_user

# curl put watcher config

# curl put watcher trigger data?

echo "-- Configure Kibana with the Shield user"
export KIBANACONF=/opt/kibana/config/kibana.yml
cp $KIBANACONF ${KIBANACONF}.bck
#echo elasticsearch.username: "kibana4" >> $KIBANACONF
#echo elasticsearch.password: "notsecure" >> $KIBANACONF
#echo xpack.security.kibana.username: kibana  >> $KIBANACONF  # NOT ALLOWED
echo xpack.security.kibana.password: changeme >> $KIBANACONF
echo xpack.security.encryptionKey: "foo" >> $KIBANACONF
echo shield.encryptionKey: "foo" >> $KIBANACONF
echo server.ssl.cert: /home/leedr/Desktop/server.crt >> $KIBANACONF
echo server.ssl.key: /home/leedr/Desktop/server.key >> $KIBANACONF
echo elasticsearch.ssl.ca: /home/leedr/Desktop/ca.zip >> $KIBANACONF
cp /home/leedr/Desktop/ca.zip /etc/elasticsearch/

# Start Services
for i in $PRODUCTS; do echo "-- Starting $i" & service $i start; done

ping -c 100 www.google.com >/dev/null &


./check.sh

# load beats-dashboards
#cd ./beats-dashboards
#./load.sh -url "http://localhost:9200" -user "admin:notsecure"
#cd ..


