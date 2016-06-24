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

. ./setenv.sh

#./cleanup.sh

echo Download latest packages - see https://github.com/elastic/dev/issues/665

# ELASTICSEARCH
ls elasticsearch*.deb || wget http://download.elastic.co/elasticsearch/staging/5.0.0-alpha4-0cae9ad/org/elasticsearch/distribution/deb/elasticsearch/5.0.0-alpha4/elasticsearch-5.0.0-alpha4.deb || exit 1

# KIBANA
ls kibana*.deb || wget https://download.elastic.co/kibana/staging/5.0.0-alpha4-c6f5963/kibana/kibana-5.0.0-alpha4-amd64.deb || exit 1
#cp ../kibana/target/kibana_5.0.0-snapshot_amd64.deb ./

# LOGSTASH
ls logstash*.deb || wget https://download.elastic.co/logstash/logstash/logstash-5.0.0-alpha4.deb || exit 1

# FILEBEAT
ls filebeat*.deb || wget https://download.elastic.co/beats/filebeat/filebeat-5.0.0-alpha4-SNAPSHOT-amd64.deb || exit 1

# PACKETBEAT
ls packetbeat*.deb || wget https://download.elastic.co/beats/packetbeat/packetbeat-5.0.0-alpha4-SNAPSHOT-amd64.deb || exit 1

# METRICBEAT
ls metricbeat*.deb || wget https://download.elastic.co/beats/metricbeat/metricbeat-5.0.0-alpha4-SNAPSHOT-amd64.deb || exit 1

./install_packages.sh || exit 1

# Install Platinum License?

echo Configure beats authenication
./configure_beats.sh || exit 1

echo Install Elasticsearch X-Pack
#/usr/share/elasticsearch/bin/elasticsearch-plugin install -b x-pack
time ES_JAVA_OPTS="-Des.plugins.staging=b0da471" /usr/share/elasticsearch/bin/elasticsearch-plugin install -b x-pack || exit 1

echo Install Kibana UI Plugins
time /usr/share/kibana/bin/kibana-plugin install timelion || exit 1
#/usr/share/kibana/bin/kibana-plugin install x-pack
time /usr/share/kibana/bin/kibana-plugin install https://download.elasticsearch.org/elasticsearch/staging/5.0.0-alpha4-0cae9ad/kibana/x-pack-5.0.0-alpha4.zip || exit 1

# fix an issue in kibana if you install plugins as root before you've started kibana the first time
# https://github.com/elastic/kibana/issues/6730
#chown kibana:kibana /usr/share/kibana/optimize/.babelcache.json || exit 1
# https://github.com/elastic/x-plugins/issues/2201
#chown -R kibana:kibana /usr/share/kibana/node_modules || exit 1
#chown -R kibana:kibana /usr/share/kibana/installedPlugins || exit 1

# Create kibana user role
#cat kibanaRole.txt >> /etc/elasticsearch/x-pack/roles.yml || exit 1



echo "-- Configure Shield users/roles for Kibana"
#/usr/share/elasticsearch/bin/x-pack/users useradd $KIBANAFILEUSER -r kibanaUser -p $KIBANAFILEPWD || exit 1
# create user for logstash to connect to Elasticsearch (used in logstash.conf
/usr/share/elasticsearch/bin/x-pack/users useradd $LOGSTASHUSER -r logstash -p $LOGSTASHPWD || exit 1
# let logstash process read syslog
setfacl -m u:logstash:r /var/log/syslog || exit 1
cp logstash.conf /etc/logstash/conf.d/ || exit 1

# curl put watcher config

# curl put watcher trigger data?

ls server.crt || wget https://raw.githubusercontent.com/elastic/kibana/master/test/dev_certs/server.crt || exit 1
ls server.key || wget https://raw.githubusercontent.com/elastic/kibana/master/test/dev_certs/server.key || exit 1
ls ca.zip || zip ca.zip server.* || exit 1
echo "-- Configure Kibana with the Shield user"
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



