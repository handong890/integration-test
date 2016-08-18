#!/bin/bash
QADIR=/vagrant/qa/
cd $QADIR

date

if [ `grep DISTRIB_ID /etc/*-release | cut -d= -f2` != 'Ubuntu' ]; then
  echo "This script was written for Ubuntu (apt-get, dpkg, etc)"
  exit 1
fi

java_version=$(java -version 2>&1 | grep version | sed 's|.* version "\(.*\..*\)\..*_.*"|\1|')
ubuntu_version=$(grep VERSION_ID /etc/*-release)
if [[ $java_version < 1.8 ]]; then
  echo "Install Java 8"
  sudo add-apt-repository -y ppa:webupd8team/java
  sudo apt-get -qq update
  echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo /usr/bin/debconf-set-selections
  sudo apt-get -qq install -y oracle-java8-installer
fi

java_version=$(java -version 2>&1 | grep version | sed 's|.* version "\(.*\..*\)\..*_.*"|\1|')
echo "Java version = $java_version"
if [[ $java_version < 1.8 ]]; then
  exit 1
fi

. ./setenv.sh

VERSION=5.0.0-alpha5
SNAPSHOT=-SNAPSHOT
BASEURL=snapshots.elastic.co
PACKAGE=deb
PLATFORM=-amd64
#./cleanup.sh

echo "-- Get the packages"
ls packetbeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE} || wget -q http://${BASEURL}/download/beats/packetbeat/packetbeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE}
ls filebeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE}   || wget -q http://${BASEURL}/download/beats/filebeat/filebeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE}
ls metricbeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE} || wget -q http://${BASEURL}/download/beats/metricbeat/metricbeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE}
ls kibana-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE}     || wget -q http://${BASEURL}/download/kibana/kibana-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE}

ls logstash-${VERSION}${SNAPSHOT}.${PACKAGE}      || wget -q http://${BASEURL}/download/logstash/logstash-${VERSION}${SNAPSHOT}.${PACKAGE}
ls elasticsearch-${VERSION}${SNAPSHOT}.${PACKAGE} || wget -q http://${BASEURL}/download/elasticsearch/elasticsearch-${VERSION}${SNAPSHOT}.${PACKAGE}

echo "-- Install packages"
./install_packages.sh || exit 1

# Install Platinum License?

echo "-- Configure beats authenication"
./configure_beats.sh || exit 1

echo "-- Install Elasticsearch X-Pack"
ls x-pack-${VERSION}${SNAPSHOT}.zip || wget -q http://${BASEURL}/download/elasticsearch/plugins/x-pack/x-pack-${VERSION}${SNAPSHOT}.zip
time sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install -b file:///${QADIR}/x-pack-${VERSION}${SNAPSHOT}.zip

echo "-- Install Kibana UI Plugins"
time sudo /usr/share/kibana/bin/kibana-plugin install https://${BASEURL}/download/kibana/plugins/x-pack/x-pack-${VERSION}${SNAPSHOT}.zip

echo "-- Configure Shield users/roles for Kibana"
#/usr/share/elasticsearch/bin/x-pack/users useradd $KIBANAFILEUSER -r kibanaUser -p $KIBANAFILEPWD || exit 1
# create user for logstash to connect to Elasticsearch (used in logstash.conf
/usr/share/elasticsearch/bin/x-pack/users useradd $LOGSTASHUSER -r logstash -p $LOGSTASHPWD || exit 1

echo "-- let logstash process read syslog"
#sudo setfacl -m u:logstash:r /var/log/syslog || exit 1 (not mounted with acls)
sudo chmod o+r /var/log/syslog
sudo cp logstash.conf /etc/logstash/conf.d/ || exit 1

# curl put watcher config

# curl put watcher trigger data?

echo "-- Set network.host for Elasticsearch so we can access it outside the vagrant machine"
echo "network.host: 0.0.0.0" >> /etc/elasticsearch/elasticsearch.yml
# Now that we set host, we have to make it more production like
echo "discovery.zen.minimum_master_nodes: 0" >> /etc/elasticsearch/elasticsearch.yml

echo "-- set jvm min heap size"
sed -i 's/-Xms256m/-Xms2g/' /etc/elasticsearch/jvm.options


echo "-- Start services"
./start_services.sh || exit 1

# make some packet data
ping -c 100 www.google.com >/dev/null &

echo "-- Wait for Elasticsearch and Kibana to be ready"
./check.sh

echo "-- Create a Kibana user (iron man)"
./create_kibana_user.sh

echo "-- Load Beats index patterns, saves searches, visualizations, and dashboards"
pushd /usr/share/filebeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD &>/dev/null
popd

pushd /usr/share/packetbeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD &>/dev/null
popd

pushd /usr/share/metricbeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD &>/dev/null
popd
