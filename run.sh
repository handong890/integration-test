#!/bin/bash
rm qa/*.deb*
rm qa/*.rpm*
rm qa/x-pack*.zip*

echo 5.0.0-beta1 > ./qa/version
# 5.x branch = 5.0.0-alpha6 - this is what is checked in and working
# 5.0 branch = 5.0.0-beta1 - logstash issue
# master branch = 6.0.0-alpha1 - kibana and plugins require 5.0.x https://github.com/elastic/kibana/pull/8185 and https://github.com/elastic/x-plugins/pull/3389
#VERSION=5.0.0-alpha6
#VERSION=5.0.0-beta1
#VERSION=6.0.0-alpha1

echo "--- Start npm install in the background while the VM comes up"
time npm install &

time vagrant destroy -f || exit 1
time vagrant up || exit 1

# this wait makes sure the npm install finished
wait
# We can run the UI tests headless, but not on Windows
if [ .$OS. == .Windows_NT. ]; then
  time npm run test:ui:runner
else
  time xvfb-run npm run test:ui:runner
fi
