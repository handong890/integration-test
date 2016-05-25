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

echo Download latest packages - see https://github.com/elastic/dev/issues/665

# ELASTICSEARCH
ls elasticsearch*.deb || wget http://download.elastic.co/elasticsearch/staging/5.0.0-alpha3-b3a8c54/org/elasticsearch/distribution/deb/elasticsearch/5.0.0-alpha3/elasticsearch-5.0.0-alpha3.deb || exit 1

# KIBANA
ls kibana*.deb || wget https://download.elastic.co/kibana/staging/5.0.0-aa9a450/kibana/kibana_5.0.0-alpha3_amd64.deb || exit 1

# LOGSTASH
ls logstash*.deb || wget https://download.elastic.co/logstash/logstash/logstash-5.0.0-alpha2.snapshot2_all.deb || exit 1

# FILEBEAT
ls filebeat*.deb || wget https://download.elastic.co/beats/filebeat/filebeat-5.0.0-alpha3-SNAPSHOT-amd64.deb || exit 1

# TOPBEAT
ls topbeat*.deb || wget https://download.elastic.co/beats/topbeat/topbeat-5.0.0-alpha3-SNAPSHOT-amd64.deb || exit 1

# PACKETBEAT
ls packetbeat*.deb || wget https://download.elastic.co/beats/packetbeat/packetbeat-5.0.0-alpha3-SNAPSHOT-amd64.deb || exit 1

# Install packages
for i in $PRODUCTS; do echo "-- Installing $i*.deb" & dpkg -i ./$i*.deb || exit 1; done

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
ES_JAVA_OPTS="-Des.plugins.staging=true" /usr/share/elasticsearch/bin/elasticsearch-plugin install -b x-pack || exit 1

# Install Kibana UI Plugins
/opt/kibana/bin/kibana-plugin install timelion || exit 1
#/opt/kibana/bin/kibana-plugin install x-pack
/opt/kibana/bin/kibana-plugin install https://download.elasticsearch.org/elasticsearch/staging/5.0.0-alpha3-b3a8c54/kibana/x-pack-5.0.0-alpha3.zip || exit 1

# fix an issue in kibana if you install plugins as root before you've started kibana the first time
# https://github.com/elastic/kibana/issues/6730
chown kibana:kibana /opt/kibana/optimize/.babelcache.json || exit 1
# https://github.com/elastic/x-plugins/issues/2201
chown -R kibana:kibana /opt/kibana/node_modules || exit 1
chown -R kibana:kibana /opt/kibana/installedPlugins || exit 1

# Create kibana user role
cat kibanaRole.txt >> /etc/elasticsearch/x-pack/roles.yml || exit 1



echo "-- Configure Shield users/roles for Kibana"
/usr/share/elasticsearch/bin/x-pack/users useradd $KIBANAFILEUSER -r kibanaUser -p $KIBANAFILEPWD || exit 1
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
export KIBANACONF=/opt/kibana/config/kibana.yml
cp $KIBANACONF ${KIBANACONF}.bck
#echo xpack.security.kibana.username: kibana  >> $KIBANACONF  # NOT ALLOWED
#echo xpack.security.kibana.password: $KIBANASERVERPWD >> $KIBANACONF
echo elasticsearch.password: changeme >> KIBANACONF
echo xpack.security.encryptionKey: "foo" >> $KIBANACONF
echo shield.encryptionKey: "foo" >> $KIBANACONF
cp ./server.* /opt/kibana/ || exit 1
cp ./ca.zip /opt/kibana/ || exit 1
cp ./server.* /etc/elasticsearch/ || exit 1
cp ./ca.zip /etc/elasticsearch/ || exit 1
echo server.ssl.cert: /opt/kibana/server.crt >> $KIBANACONF
echo server.ssl.key: /opt/kibana/server.key >> $KIBANACONF
echo elasticsearch.ssl.ca: /opt/kibana/ca.zip >> $KIBANACONF
#cp /home/leedr/Desktop/ca.zip /etc/elasticsearch/



# Start Services
#for i in $PRODUCTS; do echo "-- Starting $i" & service $i start; done
# xpack issue 2200, we need to start Elasticsearch FIRST and after it's started we can start Kibana
# otherwise Kibana doesn't get the license info and has to be restarted

service elasticsearch start || exit 1
rm index.html*
# try 10 times, 2 seconds apart
echo -e "\n-----------------Elasticserach----------------------------------------"
for i in `seq 1 20`; do echo "wget es index" && sleep 2 && wget -q --http-user=elastic --http-password=changeme http://localhost:9200 && break; done
cat index.html
service kibana start || exit 1
service logstash start || exit 1
service topbeat start || exit 1
service filebeat start || exit 1
service packetbeat start || exit 1



ping -c 100 www.google.com >/dev/null &


./check.sh

curl -POST http://elastic:changeme@localhost:9200/_xpack/security/user/$NATIVEKIBANAUSER -d '{ 
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



