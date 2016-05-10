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

./cleanup.sh

PRODUCTS="packetbeat topbeat filebeat elasticsearch kibana logstash"
ELASTICUSER=elastic
ELASTICPWD=changeme

KIBANASERVERUSER=kibana
KIBANASERVERPWD=changeme

KIBANAFILEUSER=user
KIBANAFILEPWD=changeme

NATIVEKIBANAUSER=ironman
NATIVEKIBANAPWD=changeme

LOGSTASHUSER=loggy
LOGSTASHPWD=changeme

# Download latest packages

# ELASTICSEARCH
#wget http://download.elastic.co/elasticsearch/staging/5.0.0-alpha2-e3126df/org/elasticsearch/distribution/deb/elasticsearch/5.0.0-alpha2/elasticsearch-5.0.0-alpha2.deb
ls elasticsearch*.deb || wget `curl -v --silent -XGET https://oss.sonatype.org/content/repositories/snapshots/org/elasticsearch/distribution/deb/elasticsearch/5.0.0-SNAPSHOT/ 2>&1 | grep -G "elasticsearch.*\.deb"  | head -n1 | sed 's/.*"\(.*\)".*/\1/'`

# KIBANA
ls kibana*.deb || wget http://download.elasticsearch.org/kibana/kibana-snapshot/kibana_5.0.0-snapshot_amd64.deb

# LOGSTASH
ls logstash*.deb || wget https://s3-eu-west-1.amazonaws.com/build-eu.elasticsearch.org/logstash/5.0/nightly/JDK8/logstash-latest-SNAPSHOT.deb

# FILEBEAT
ls filebeat*.deb || wget https://beats-nightlies.s3.amazonaws.com/filebeat/filebeat_5.0.0-SNAPSHOT_amd64.deb

# TOPBEAT
ls topbeat*.deb || wget https://beats-nightlies.s3.amazonaws.com/topbeat/topbeat_5.0.0-SNAPSHOT_amd64.deb

# PACKETBEAT
ls packetbeat*.deb || wget https://beats-nightlies.s3.amazonaws.com/packetbeat/packetbeat_5.0.0-SNAPSHOT_amd64.deb

# Install packages
for i in $PRODUCTS; do echo "-- Installing $i*.deb" & dpkg -i ./$i*.deb; done

# Install Platinum License?

# Configure products
# beats need authentication for elasticsearch
sed -i "s/#username:.*/username: \"$ELASTICUSER\"/" /etc/topbeat/topbeat.yml
sed -i "s/#password:.*/password: \"$ELASTICPWD\"/" /etc/topbeat/topbeat.yml

sed -i "s/#username:.*/username: \"$ELASTICUSER\"/" /etc/filebeat/filebeat.yml
sed -i "s/#password:.*/password: \"$ELASTICPWD\"/" /etc/filebeat/filebeat.yml

sed -i "s/#username:.*/username: \"$ELASTICUSER\"/" /etc/packetbeat/packetbeat.yml
sed -i "s/#password:.*/password: \"$ELASTICPWD\"/" /etc/packetbeat/packetbeat.yml


# Install X-Plugins  --------- Just XPACK ??
#/usr/share/elasticsearch/bin/elasticsearch-plugin install -b x-pack
/usr/share/elasticsearch/bin/elasticsearch-plugin install -b https://download.elastic.co/kibana/x-pack/x-pack-5.0.0-alpha2.zip
#                                                            https://download.elasticsearch.org/kibana/x-pack/x-pack-5.0.0-snapshot.zip

# Install Kibana UI Plugins
/opt/kibana/bin/kibana-plugin install timelion
/opt/kibana/bin/kibana-plugin install x-pack


# fix an issue in kibana if you install plugins as root before you've started kibana the first time
# https://github.com/elastic/kibana/issues/6730
chown kibana:kibana /opt/kibana/optimize/.babelcache.json
# https://github.com/elastic/x-plugins/issues/2201
chown -R kibana:kibana /opt/kibana/node_modules
chown -R kibana:kibana /opt/kibana/installedPlugins

# Create kibana user role
cat kibanaRole.txt >> /etc/elasticsearch/x-pack/roles.yml



echo "-- Configure Shield users/roles for Kibana"
/usr/share/elasticsearch/bin/x-pack/users useradd $KIBANAFILEUSER -r kibanaUser -p $KIBANAFILEPWD
# create user for logstash to connect to Elasticsearch (used in logstash.conf
/usr/share/elasticsearch/bin/x-pack/users useradd $LOGSTASHUSER -r logstash -p $LOGSTASHPWD
# let logstash process read syslog
setfacl -m u:logstash:r /var/log/syslog
cp logstash.conf /etc/logstash/conf.d/

# curl put watcher config

# curl put watcher trigger data?

echo "-- Configure Kibana with the Shield user"
export KIBANACONF=/opt/kibana/config/kibana.yml
cp $KIBANACONF ${KIBANACONF}.bck
#echo xpack.security.kibana.username: kibana  >> $KIBANACONF  # NOT ALLOWED
#echo xpack.security.kibana.password: $KIBANASERVERPWD >> $KIBANACONF
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

curl -POST http://elastic:changeme@localhost:9200/_shield/user/$NATIVEKIBANAUSER -d '{ 
  "password" : "changeme",
  "roles" : [ "kibanaUser" ],
  "full_name" : "Tony Stark",
  "email" : "tony@starkcorp.co",
  "metadata" : {
    "intelligence" : 7
  }
}'

pushd /usr/share/topbeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD
popd

pushd /usr/share/filebeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD
popd

pushd /usr/share/packetbeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD
popd



