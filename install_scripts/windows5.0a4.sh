
# Requires cygwin with unzip (non-default option)

# packetbeat requires WinPcap from;
# https://www.winpcap.org/install/default.htm

if [ ! `uname -s | grep MINGW64` ]; then
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
taskkill /IM:node.exe
taskkill /IM:filebeat.exe
taskkill /IM:packetbeat.exe
taskkill /IM:metricbeat.exe
taskkill /IM:winlogbeat.exe
#taskkill /IM:java.exe
wmic process where "name like '%java%'" delete
wmic process where "name like '%node%'" delete


echo Download latest packages - see https://github.com/elastic/dev/issues/671
echo If you change any links make sure you also delete the package

# ELASTICSEARCH
ls elasticsearch*.zip || wget http://download.elastic.co/elasticsearch/staging/5.0.0-alpha4-3f5b994/org/elasticsearch/distribution/zip/elasticsearch/5.0.0-alpha4/elasticsearch-5.0.0-alpha4.zip  || exit 1

# KIBANA
ls kibana*.zip || wget https://download.elastic.co/kibana/staging/5.0.0-alpha4-c22c5da/kibana/kibana-5.0.0-alpha4-windows.zip || exit 1

# LOGSTASH
ls logstash*.zip || wget https://download.elastic.co/logstash/logstash/logstash-5.0.0-alpha4.zip || exit 1

# FILEBEAT
ls filebeat*.zip || wget https://download.elastic.co/beats/filebeat/filebeat-5.0.0-alpha4-windows-x86_64.zip || exit 1

# PACKETBEAT
ls packetbeat*.zip || wget https://download.elastic.co/beats/packetbeat/packetbeat-5.0.0-alpha4-windows-x86_64.zip || exit 1

# METRICBEAT
ls metricbeat*.zip || wget https://download.elastic.co/beats/metricbeat/metricbeat-5.0.0-alpha4-windows-x86_64.zip || exit 1

# WINLOGBEAT
ls winlogbeat*.zip || wget https://download.elastic.co/beats/winlogbeat/winlogbeat-5.0.0-alpha4-windows-x86_64.zip || exit 1


#./install_packages.sh || exit 1

INSTALL_DIR=/d/5.0.0-a4
# kill all processes first?
rm -rf $INSTALL_DIR
mkdir $INSTALL_DIR
for i in $PRODUCTS; do unzip -q ${i}*.zip -d $INSTALL_DIR; done
#./unzip_packages.sh
sleep 10

for i in $PRODUCTS; do mv $INSTALL_DIR/${i}* $INSTALL_DIR/${i}; done

# find a better way to truncate these names, during unzip, or ?
#for i in `ls $INSTALL_DIR`; do mv $INSTALL_DIR/$i $INSTALL_DIR/`echo $i | sed 's/-5.0.0-alpha4-windows\///'`; done
#for i in `ls $INSTALL_DIR`; do mv $INSTALL_DIR/$i $INSTALL_DIR/`echo $i | sed 's/-5.0.0-alpha4\///'`; done



echo Configure beats authenication
BEATS="metricbeat packetbeat filebeat winlogbeat"
for beat in $BEATS; do (
  cp $INSTALL_DIR/$beat/$beat.yml $INSTALL_DIR/$beat/$beat.short.yml
  cp $INSTALL_DIR/$beat/$beat.full.yml $INSTALL_DIR/$beat/$beat.yml || exit 1
  sed -i "s/#username:.*/username: \"$ELASTICUSER\"/" $INSTALL_DIR/$beat/$beat.yml
  sed -i "s/#password:.*/password: \"$ELASTICPWD\"/"  $INSTALL_DIR/$beat/$beat.yml
); done

# optional, don't get too many Windows events
echo ignore_older: 168h >> $INSTALL_DIR/winlogbeat/winlogbeat.yml

echo Install Elasticsearch X-Pack
# notice the forcing of .bat below
ES_JAVA_OPTS="-Des.plugins.staging=3f5b994" $INSTALL_DIR/elasticsearch/bin/elasticsearch-plugin.bat install -b x-pack || exit 1

echo cluster.routing.allocation.disk.watermark.low: 97% >> $INSTALL_DIR/elasticsearch/config/elasticsearch.yml
echo cluster.routing.allocation.disk.watermark.high: 98% >> $INSTALL_DIR/elasticsearch/config/elasticsearch.yml

start /MIN $INSTALL_DIR/elasticsearch/bin/elasticsearch


echo Fix Kibana server.host to 127.0.0.100
sed -i 's/# server.host: "0.0.0.0"/server.host: "127.0.0.1"/' $INSTALL_DIR/kibana/config/kibana.yml

echo Install Kibana UI Plugins
# notice the forcing of .bat below
time $INSTALL_DIR/kibana/bin/kibana-plugin.bat install timelion || exit 1

pushd $INSTALL_DIR/kibana
#    $INSTALL_DIR/kibana/bin/kibana-plugin.bat install x-pack
time $INSTALL_DIR/kibana/bin/kibana-plugin.bat install https://download.elasticsearch.org/elasticsearch/staging/5.0.0-alpha4-3f5b994/kibana/x-pack-5.0.0-alpha4.zip || exit 1
popd



# Create kibana user role
#cat kibanaRole.txt >> /etc/elasticsearch/x-pack/roles.yml || exit 1



#echo "-- Configure Shield users/roles for Kibana"
#/usr/share/elasticsearch/bin/x-pack/users useradd $KIBANAFILEUSER -r kibanaUser -p $KIBANAFILEPWD || exit 1
# create user for logstash to connect to Elasticsearch (used in logstash.conf
#/usr/share/elasticsearch/bin/x-pack/users useradd $LOGSTASHUSER -r logstash -p $LOGSTASHPWD || exit 1
# let logstash process read syslog
#setfacl -m u:logstash:r /var/log/syslog || exit 1
#cp logstash.conf /etc/logstash/conf.d/ || exit 1

/c/Windows/PFRO.log
# 6/14/2016 19:14:22 - PFRO Error: \??\C:\Program Files (x86)\Mozilla Firefox\tobedeleted\moz7CC1.tmp, |delete operation|, 0xc000003a
# 6/14/2016 19:14:22 - PFRO Error: \??\C:\Program Files (x86)\Mozilla Firefox\tobedeleted\, |delete operation|, 0xc0000034
# 6/14/2016 19:14:22 - PFRO Error: \??\C:\Users\Lee\AppData\Local\Temp\~nsu.tmp\Au_.exe, |delete operation|, 0xc000003a
# 6/14/2016 19:14:22 - PFRO Error: \??\C:\Users\Lee\AppData\Local\Temp\~nsu.tmp, |delete operation|, 0xc0000034
# 6/14/2016 19:14:22 - 21 Successful PFRO operations

# 6/22/2016 8:5:21 - PFRO Error: \??\C:\WINDOWS\system32\spool\V4Dirs\EA7DCC0F-6505-42B7-B0FE-6A21FA3BBC03\94766af2.gpd, |delete operation|, 0xc0000034
# 6/22/2016 8:5:21 - 20 Successful PFRO operations

# 6/28/2016 9:57:40 - PFRO Error: \??\C:\WINDOWS\system32\spool\DRIVERS\x64\3\New\PrintConfig.dll, \??\C:\WINDOWS\system32\spool\DRIVERS\x64\3\PrintConfig.dll, 0xc000003a
# 6/28/2016 9:57:40 - PFRO Error: \??\C:\WINDOWS\system32\spool\DRIVERS\W32X86\3\New\PrintConfig.dll, \??\C:\WINDOWS\system32\spool\DRIVERS\W32X86\3\PrintConfig.dll, 0xc000003a
# 6/28/2016 9:57:40 - 5 Successful PFRO operations


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


#./start_services.sh || exit 1

# make some packet data
#ping -c 100 www.google.com >/dev/null &


#./check.sh

#./create_kibana_user.sh


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


pushd $INSTALL_DIR/filebeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD
popd

pushd $INSTALL_DIR/packetbeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD
popd

pushd $INSTALL_DIR/metricbeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD
popd

pushd $INSTALL_DIR/winlogbeat/kibana/
./import_dashboards.sh -u $ELASTICUSER:$ELASTICPWD
popd


# (this prompts to "allow" on Windows)
start /MIN $INSTALL_DIR/kibana/bin/kibana
start /MIN $INSTALL_DIR/logstash/bin/logstash.bat
start /MIN $INSTALL_DIR/filebeat/filebeat.exe
start /MIN $INSTALL_DIR/metricbeat/metricbeat.exe
start /MIN $INSTALL_DIR/packetbeat/packetbeat.exe
start /MIN $INSTALL_DIR/winlogbeat/winlogbeat.exe
# filebeat and packetbeat = 0

makelogs --auth elastic:changeme


