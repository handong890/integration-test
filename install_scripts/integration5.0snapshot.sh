#!/bin/bash
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root" 1>&2
   exit 1
fi



if [ `grep DISTRIB_ID /etc/*-release | cut -d= -f2` != 'Ubuntu' ]; then
  echo "This script was written for Ubuntu (apt-get, dpkg, etc)"
  exit 1
fi

apt-add-repository ppa:webupd8team/java
apt-get update
apt-get install oracle-java8-installer

################################################ THIS IS NOT THE SCRIPT THAT RUNS!!!!!!!!!!!!
. ./setenv.sh

#VERSION=5.0.0-alpha5
#SNAPSHOT=-SNAPSHOT
#BASEURL=snapshots.elastic.co
#PACKAGE=deb

VERSION=5.0.0-alpha6
HASH=-b2c88dcc
SNAPSHOT=
BASEURL=staging.elastic.co/${VERSION}${HASH}
PACKAGE=deb
ARCH=-amd64

#./cleanup.sh

#http://staging.elastic.co/5.0.0-alpha6-b2c88dcc/download/elasticsearch/elasticsearch-5.0.0-alpha6.deb

echo Download latest packages - see https://github.com/elastic/dev/issues/665
#for PRODUCT in $PRODUCTS; do wget http://${BASEURL}/download/${PRODUCT}/${PRODUCT}-${VERSION}${SNAPSHOT}.${PACKAGE}
ls elasticsearch*.${PACKAGE} || wget http://${BASEURL}/download/elasticsearch/elasticsearch-${VERSION}${SNAPSHOT}.${PACKAGE} || exit

#http://staging.elastic.co/5.0.0-alpha6-b2c88dcc/download/logstash/logstash-5.0.0-alpha6.deb
ls logstash*.${PACKAGE} || wget http://${BASEURL}/download/logstash/logstash-${VERSION}${SNAPSHOT}.${PACKAGE} || exit


#http://staging.elastic.co/5.0.0-alpha6-b2c88dcc/download/kibana/kibana-5.0.0-alpha6-amd64.deb
ls kibana*.${PACKAGE} || wget http://${BASEURL}/download/kibana/kibana-${VERSION}${SNAPSHOT}${ARCH}.${PACKAGE} || exit


#http://staging.elastic.co/5.0.0-alpha6-b2c88dcc/download/beats/filebeat/filebeat-5.0.0-alpha6-amd64.deb
ls filebeat*.${PACKAGE} || wget http://${BASEURL}/download/beats/filebeat-${VERSION}${SNAPSHOT}${ARCH}.${PACKAGE} || exit
ls packetbeat*.${PACKAGE} || wget http://${BASEURL}/download/beats/packetbeat-${VERSION}${SNAPSHOT}${ARCH}.${PACKAGE} || exit
ls metricbeat*.${PACKAGE} || wget http://${BASEURL}/download/beats/metricbeat-${VERSION}${SNAPSHOT}${ARCH}.${PACKAGE} || exit



./install_packages.sh || exit 1

# Install Platinum License?

echo Configure beats authenication
./configure_beats.sh || exit 1

echo Install Elasticsearch X-Pack
#http://staging.elastic.co/5.0.0-alpha6-b2c88dcc/download/elasticsearch/plugins/x-pack/x-pack-5.0.0-alpha6.zip
/usr/share/elasticsearch/bin/elasticsearch-plugin install -b file:///${BASEURL}/download/elasticsearch/plugins/x-pack/x-pack-${VERSION}${SNAPSHOT}.zip

echo Install Kibana UI Plugins
#time /usr/share/kibana/bin/kibana-plugin install timelion || exit 1
#/usr/share/kibana/bin/kibana-plugin install x-pack 
#http://staging.elastic.co/5.0.0-alpha6-b2c88dcc/download/kibana/plugins/x-pack/x-pack-5.0.0-alpha6.zip
time /usr/share/kibana/bin/kibana-plugin install https://${BASEURL}/download/kibana/plugins/x-pack/x-pack-${VERSION}${SNAPSHOT}.zip



# create user for logstash to connect to Elasticsearch (used in logstash.conf
/usr/share/elasticsearch/bin/x-pack/users useradd $LOGSTASHUSER -r logstash -p $LOGSTASHPWD || exit 1
# let logstash process read syslog
#setfacl -m u:logstash:r /var/log/syslog || exit 1
cp logstash.conf /etc/logstash/conf.d/ || exit 1

# curl put watcher config

# curl put watcher trigger data?

#ls server.crt || wget https://raw.githubusercontent.com/elastic/kibana/master/test/dev_certs/server.crt || exit 1
#ls server.key || wget https://raw.githubusercontent.com/elastic/kibana/master/test/dev_certs/server.key || exit 1
#ls ca.zip || zip ca.zip server.* || exit 1
#echo "-- Configure Kibana with the Shield user"
#export KIBANACONF=/usr/share/kibana/config/kibana.yml
#cp $KIBANACONF ${KIBANACONF}.bck
#echo xpack.security.kibana.username: kibana  >> $KIBANACONF  # NOT ALLOWED
#echo xpack.security.kibana.password: $KIBANASERVERPWD >> $KIBANACONF
#echo elasticsearch.password: $KIBANASERVERPWD >> KIBANACONF
#echo xpack.security.encryptionKey: "foo" >> $KIBANACONF
#echo shield.encryptionKey: "foo" >> $KIBANACONF
#cp ./server.* /usr/share/kibana/ || exit 1
#cp ./ca.zip /usr/share/kibana/ || exit 1
#cp ./server.* /etc/elasticsearch/ || exit 1
#cp ./ca.zip /etc/elasticsearch/ || exit 1
#echo server.ssl.cert: /usr/share/kibana/server.crt >> $KIBANACONF
#echo server.ssl.key: /usr/share/kibana/server.key >> $KIBANACONF
#echo elasticsearch.ssl.ca: /usr/share/kibana/ca.zip >> $KIBANACONF


./start_services.sh || exit 1

# make some packet data
ping -c 100 www.google.com >/dev/null &


./check.sh

./create_kibana_user.sh


# {"cluster":["manage_security"],"indices":[],"run_as":[],"name":"testRole1"}{"cluster":["manage_security"],"indices":[],"run_as":[],"name":"testRole1"}
# {"cluster":["manage_security"],"indices":[{"names":["packetbeat-*"],"privileges":["all"],"fields":[]}],"run_as":[],"name":"testRole2"}

#curl -POST http://elastic:changeme@localhost:9200/_xpack/security/role/securityManagerRole -d '{
#  "cluster": ["all"],
#  "privileges": ["manage_security"],
#  "indices": [
#    {
#      "names": [ "*-*" ],
#      "privileges": ["view_index_metadata", "read"]
#    },
#    {
#      "names": [ ".kibana" ],
#      "privileges": ["manage", "read","index"]
#    }
#  ]
#}'


pushd /usr/share/filebeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD
popd

pushd /usr/share/packetbeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD
popd

pushd /usr/share/metricbeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD
popd



