#!/bin/bash
QADIR=/vagrant/qa/
cd $QADIR

date

# or `lsb_release -i | cut -f 2-` == Ubuntu  (need to test on CentOS)
if [ `grep DISTRIB_ID /etc/*-release | cut -d= -f2` == 'Ubuntu' ]; then
  PACKAGE=deb
  echo "Running on Ubuntu"
  # set install command to be dpkg
else
  echo "This script was written for Ubuntu (apt-get, dpkg, etc)"
  exit 1
fi

MACHINE_TYPE=`uname -m`
if [ ${MACHINE_TYPE} == 'x86_64' ]; then
  PLATFORM=-amd64
  echo "Running on 64-bit (x86_64 / amd64)"
else
  PLATFORM=-i386
  echo "Running on 32-bit (i386)"

fi

java_version=$(java -version 2>&1 | grep version | sed 's|.* version "\(.*\..*\)\..*_.*"|\1|')
ubuntu_version=$(grep VERSION_ID /etc/*-release)
if [[ $java_version < 1.8 ]]; then
  echo "Install Java 8, please wait"
  sudo add-apt-repository -y ppa:webupd8team/java &> /dev/null
  sudo apt-get -qq update &> /dev/null
  echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo /usr/bin/debconf-set-selections &> /dev/null
  sudo apt-get -qq install -y oracle-java8-installer &> /dev/null
fi

java_version=$(java -version 2>&1 | grep version | sed 's|.* version "\(.*\..*\)\..*_.*"|\1|')
echo "Java version = $java_version"
if [[ $java_version < 1.8 ]]; then
  exit 1
fi

echo "-- install libfontconfig libfreetype6 so Reporting can work on a headless server"
sudo apt-get -qq install -y  libfontconfig libfreetype6

. ./setenv.sh

VERSION=5.0.0-alpha6
SNAPSHOT=-SNAPSHOT
BASEURL=snapshots.elastic.co

#VERSION=5.0.0-alpha6
#HASH=b2c88dcc
#SNAPSHOT=
#BASEURL=staging.elastic.co/${VERSION}-${HASH}

#./cleanup.sh

echo "-- Get the packages"
echo http://${BASEURL}/download/beats/packetbeat/packetbeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE}
ls packetbeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE} || wget -q http://${BASEURL}/download/beats/packetbeat/packetbeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE} || exit 1
ls filebeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE}   || wget -q http://${BASEURL}/download/beats/filebeat/filebeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE} || exit 1
ls metricbeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE} || wget -q http://${BASEURL}/download/beats/metricbeat/metricbeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE} || exit 1
ls kibana-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE}     || wget -q http://${BASEURL}/download/kibana/kibana-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE} || exit 1

ls logstash-${VERSION}${SNAPSHOT}.${PACKAGE}      || wget -q http://${BASEURL}/download/logstash/logstash-${VERSION}${SNAPSHOT}.${PACKAGE} || exit 1
ls elasticsearch-${VERSION}${SNAPSHOT}.${PACKAGE} || wget -q http://${BASEURL}/download/elasticsearch/elasticsearch-${VERSION}${SNAPSHOT}.${PACKAGE} || exit 1

echo "-- Install packages"
./install_packages.sh || exit 1

# Install Platinum License?

echo "-- Configure beats authenication"
./configure_beats.sh || exit 1

echo "-- Install Elasticsearch X-Pack"
#                                                                 download/elasticsearch-plugins/x-pack/x-pack-5.0.0-alpha6-SNAPSHOT.zip
if [ .$HASH. == .. ]; then
  echo "Getting http://${BASEURL}/download/elasticsearch-plugins/x-pack/x-pack-${VERSION}${SNAPSHOT}.zip"
  ls x-pack-${VERSION}${SNAPSHOT}.zip || wget -q http://${BASEURL}/download/elasticsearch-plugins/x-pack/x-pack-${VERSION}${SNAPSHOT}.zip || exit 1
  echo "time sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install -b file:///${QADIR}/x-pack-${VERSION}${SNAPSHOT}.zip"
  time sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install -b file:///${QADIR}/x-pack-${VERSION}${SNAPSHOT}.zip
else
  echo "Staging install using ES_JAVA_OPTS=\"-Des.plugins.staging=$HASH\""
  #wget http://staging.elastic.co/5.0.0-alpha6-b2c88dcc/download/elasticsearch-plugins/x-pack/x-pack-5.0.0-alpha6.zip
  #                             bin/elasticsearch-plugin install https://staging.elastic.co/5.0.0-alpha6-b2c88dcc/download/elasticsearch-plugins/x-pack/x-pack-5.0.0-alpha6.zip
  #  ES_JAVA_OPTS="-Des.plugins.staging=$HASH" sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install -b file:///${QADIR}/x-pack-${VERSION}${SNAPSHOT}.zip  > /dev/null
  sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install -b http://staging.elastic.co/5.0.0-alpha6-b2c88dcc/download/elasticsearch-plugins/x-pack/x-pack-5.0.0-alpha6.zip || exit 1
  #  sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install -b http://${BASEURL}/download/elasticsearch-plugins/x-pack/x-pack-${VERSION}${SNAPSHOT}.zip || exit 1
  #https://artifacts.elastic.co/download/elasticsearch-plugins/x-pack/x-pack-5.0.0-alpha6.zip
fi

echo "-- Install Kibana UI Plugins https://${BASEURL}/download/kibana/plugins/x-pack/x-pack-${VERSION}${SNAPSHOT}.zip"
#wget https://staging.elastic.co/5.0.0-alpha6-b2c88dcc/download/kibana-plugins/x-pack/x-pack-5.0.0-alpha6.zip
time sudo /usr/share/kibana/bin/kibana-plugin install https://${BASEURL}/download/kibana-plugins/x-pack/x-pack-${VERSION}${SNAPSHOT}.zip | grep -v "^\.$"

#echo "-- Configure Shield users/roles for Kibana"
#/usr/share/elasticsearch/bin/x-pack/users useradd $KIBANAFILEUSER -r kibanaUser -p $KIBANAFILEPWD || exit 1
# create user for logstash to connect to Elasticsearch (used in logstash.conf)
#/usr/share/elasticsearch/bin/x-pack/users useradd $LOGSTASHUSER -r logstash -p $LOGSTASHPWD || exit 1

echo "-- let logstash process read syslog"
#sudo setfacl -m u:logstash:r /var/log/syslog || exit 1 (this VM is not mounted with acls)
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

echo "-- Set network.host for Kibana so we can access it outside the vagrant machine"
echo "server.host: 0.0.0.0" >> /etc/kibana/kibana.yml

echo "-- Start services"
./start_services.sh || exit 1

# make some packet data
ping -c 100 www.google.com >/dev/null &

echo "-- Wait for Elasticsearch and Kibana to be ready"
./check.sh

echo "-- Create a Kibana user (iron man)"
./create_kibana_user.sh >/dev/null

echo "-- Load Beats index patterns, saves searches, visualizations, and dashboards"
pushd /usr/share/filebeat/scripts/
./import_dashboards -user $ELASTICUSER -pass $ELASTICPWD -url http://${BASEURL}/beats/dashboards/beats-dashboards-${VERSION}.zip
popd
