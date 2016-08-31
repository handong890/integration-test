#!/bin/bash
rm qa/*.deb
rm qa/x-pack*.zip

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
