#!/bin/bash
#cd "$(dirname "$0")"
QADIR=/vagrant/qa/
cd $QADIR

#if [ "$(id -u)" != "0" ]; then
#   echo "This script must be run as root" 1>&2
#   exit 1
#fi
date
echo sleep 60
sleep 60
date


if [ `grep DISTRIB_ID /etc/*-release | cut -d= -f2` != 'Ubuntu' ]; then
  echo "This script was written for Ubuntu (apt-get, dpkg, etc)"
  exit 1
fi

sleep 30

java_version=$(java -version 2>&1 | grep version | sed 's|.* version "\(.*\..*\)\..*_.*"|\1|')
ubuntu_version=$(grep VERSION_ID /etc/*-release)
if [[ $java_version < 1.8 ]]; then
  echo "Install Java 8"
  sudo add-apt-repository -y ppa:webupd8team/java
  sudo apt-get update
  echo "oracle-java8-installer shared/accepted-oracle-license-v1-1 select true" | sudo /usr/bin/debconf-set-selections
  sudo apt-get install -y oracle-java8-installer
  #sudo apt-get update
  #sudo apt-get install -y openjdk-8-jre-headless
  #sudo apt-get install -f
fi

java -version
# node 4.4.7
# curl -sL https://deb.nodesource.com/setup_4.x | sudo -E bash -
# sudo apt-get install -y nodejs

# Chrome browser
#wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | sudo apt-key add -
#sudo sh -c 'echo "deb http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list'
#sudo apt-get install -y git google-chrome-stable

# sudo apt-get install -y git

# install chrome browser
# sudo apt-get install -y libxss1 libappindicator1 libindicator7
# wget -q https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
# sudo dpkg -i google-chrome*.deb


#sudo startx

. ./setenv.sh

VERSION=5.0.0-alpha5
SNAPSHOT=-SNAPSHOT
BASEURL=snapshots.elastic.co
PACKAGE=deb
PLATFORM=-amd64
#./cleanup.sh


ls packetbeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE} || wget http://${BASEURL}/download/beats/packetbeat/packetbeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE}
ls filebeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE}   || wget http://${BASEURL}/download/beats/filebeat/filebeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE}
ls metricbeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE} || wget http://${BASEURL}/download/beats/metricbeat/metricbeat-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE}
ls kibana-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE}     || wget http://${BASEURL}/download/kibana/kibana-${VERSION}${SNAPSHOT}${PLATFORM}.${PACKAGE}
# http://snapshots.elastic.co/download/kibana/kibana-5.0.0-alpha5-SNAPSHOT-amd64.deb

ls logstash-${VERSION}${SNAPSHOT}.${PACKAGE}      || wget http://${BASEURL}/download/logstash/logstash-${VERSION}${SNAPSHOT}.${PACKAGE}
ls elasticsearch-${VERSION}${SNAPSHOT}.${PACKAGE} || wget http://${BASEURL}/download/elasticsearch/elasticsearch-${VERSION}${SNAPSHOT}.${PACKAGE}

./install_packages.sh || exit 1

# Install Platinum License?

echo Configure beats authenication
./configure_beats.sh || exit 1

echo Install Elasticsearch X-Pack
ls x-pack-${VERSION}${SNAPSHOT}.zip || wget http://${BASEURL}/download/elasticsearch/plugins/x-pack/x-pack-${VERSION}${SNAPSHOT}.zip
time sudo /usr/share/elasticsearch/bin/elasticsearch-plugin install -b file:///${QADIR}/x-pack-${VERSION}${SNAPSHOT}.zip

echo Install Kibana UI Plugins
time sudo /usr/share/kibana/bin/kibana-plugin install https://${BASEURL}/download/kibana/plugins/x-pack/x-pack-${VERSION}${SNAPSHOT}.zip

echo "-- Configure Shield users/roles for Kibana"
#/usr/share/elasticsearch/bin/x-pack/users useradd $KIBANAFILEUSER -r kibanaUser -p $KIBANAFILEPWD || exit 1
# create user for logstash to connect to Elasticsearch (used in logstash.conf
/usr/share/elasticsearch/bin/x-pack/users useradd $LOGSTASHUSER -r logstash -p $LOGSTASHPWD || exit 1
# let logstash process read syslog
sudo setfacl -m u:logstash:r /var/log/syslog || exit 1
sudo cp logstash.conf /etc/logstash/conf.d/ || exit 1

# curl put watcher config

# curl put watcher trigger data?

# Set network.host for Elasticsearch so we can access it outside the vagrant machine
echo "network.host: 0.0.0.0" >> /etc/elasticsearch/elasticsearch.yml
# Now that we set host, we have to make it more production like
echo "discovery.zen.minimum_master_nodes: 0" >> /etc/elasticsearch/elasticsearch.yml

# and also set jvm min heap size
sed -i 's/-Xms256m/-Xms2g/' /etc/elasticsearch/jvm.options



./start_services.sh || exit 1

# make some packet data
ping -c 100 www.google.com >/dev/null &


./check.sh

./create_kibana_user.sh


pushd /usr/share/filebeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD &>/dev/null
popd

pushd /usr/share/packetbeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD &>/dev/null
popd

pushd /usr/share/metricbeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD &>/dev/null
popd
