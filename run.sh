#!/bin/bash

# rm qa/*.deb

echo "--- Start npm install in the background while the VM comes up"
time npm install &

time vagrant destroy -f || exit
time vagrant up || exit

# this wait makes sure the npm install finished
wait
# We can run the UI tests headless, but not on Windows
if [ .$OS. == .Windows_NT. ]; then
  time npm run test:ui:runner
else
  time xvfb-run npm run test:ui:runner
fi
