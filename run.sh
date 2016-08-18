#!/bin/bash

rm qa/*.deb
time npm install
time vagrant destroy -f
time vagrant up

# We can run the UI tests headless, but not on Windows
if [ .$OS. == .Windows_NT. ]; then
  time npm run test:ui:runner
else
  time xvfb-run npm run test:ui:runner
fi
