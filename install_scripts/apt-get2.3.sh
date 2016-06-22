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



wget -qO - https://packages.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
grep "packages.elastic.co/kibana/4.5"    /etc/apt/sources.list || echo "deb http://packages.elastic.co/kibana/4.5/debian stable main"        | sudo tee -a /etc/apt/sources.list
grep "packages.elastic.co/elasticsearch" /etc/apt/sources.list || echo "deb http://packages.elastic.co/elasticsearch/2.x/debian stable main" | sudo tee -a /etc/apt/sources.list
grep "packages.elastic.co/logstash"      /etc/apt/sources.list || echo "deb http://packages.elastic.co/logstash/2.3/debian stable main"      | sudo tee -a /etc/apt/sources.list
grep "packages.elastic.co/beats"         /etc/apt/sources.list || echo "deb http://packages.elastic.co/beats/apt stable main"                | sudo tee -a /etc/apt/sources.list

apt-get update

for i in $PRODUCTS; do apt-get install $i; done
# right after we release a version we should test like this;
# but after the next version comes out, we may need to test with something like this;
#apt-get install elasticsearch-2.3.0
#apt-get install kibana-4.5.0


# Install Platinum License?

# Configure products
# beats need authentication for elasticsearch
sed -i 's/#username:.*/username: "admin"/' /etc/topbeat/topbeat.yml
sed -i 's/#password:.*/password: "notsecure"/' /etc/topbeat/topbeat.yml

sed -i 's/#username:.*/username: "admin"/' /etc/filebeat/filebeat.yml
sed -i 's/#password:.*/password: "notsecure"/' /etc/filebeat/filebeat.yml

sed -i 's/#username:.*/username: "admin"/' /etc/packetbeat/packetbeat.yml
sed -i 's/#password:.*/password: "notsecure"/' /etc/packetbeat/packetbeat.yml


# Install Elasticsearch X-Plugin 
for i in $XPLUGINS; do echo "-- Installing $i plugin" & /usr/share/elasticsearch/bin/plugin install -b $i; done

# Install Kibana UI Plugins
KPLUGINS="elasticsearch/marvel elasticsearch/graph kibana/shield elastic/sense elastic/timelion"
for i in $KPLUGINS; do /opt/kibana/bin/kibana plugin -i $i; done

# fix an issue in kibana if you install plugins as root before you've started kibana the first time
chown kibana:kibana /opt/kibana/optimize/.babelcache.json

# Create kibana user role
cat kibanaRole.txt >> /etc/elasticsearch/shield/roles.yml



echo "-- Configure Shield users/roles for Kibana and Marvel"
/usr/share/elasticsearch/bin/shield/esusers useradd kibana4 -r kibana4_server -p notsecure
/usr/share/elasticsearch/bin/shield/esusers useradd user -r kibanaUser -p notsecure
/usr/share/elasticsearch/bin/shield/esusers useradd admin -r admin -p notsecure

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
pushd ../beats-dashboards
./load.sh -url "http://localhost:9200" -user "admin:notsecure"
popd

./kibana/node_modules/makelogs/bin/makelogs --auth admin:notsecure

