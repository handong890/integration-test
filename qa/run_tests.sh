#!/bin/bash
cd /vagrant

npm install
sudo npm install -g grunt

echo "Logstash logs syslog, but also logs INTO syslog!  Let's stop the logstash service now"
sudo service logstash stop

echo "Use sed to make sure we're using production default ports"
sed -i 's/5620/5601/' test/server_config.js
sed -i 's/9220/9200/' test/server_config.js

#npm run test:ui:runner

# or
grunt run:devChromeDriver:keepalive&
sleep 20
# or
#vagrant@vagrant-ubuntu-trusty-64:/vagrant/qa$ java -jar /vagrant/qa/selenium-server-standalone-2.53.0.jar  -Dwebdriver.chrome.driver=/vagrant/qa/chromedriver
# and
node_modules/intern/bin/intern-runner.js config=test/intern