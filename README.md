# integration-test
Full stack integration test repo

This will be linked to (or merged with) the Unified Release Process once it is in place.

## Phase 1
 * Ubuntu OS
 * Topbeat
 * Packetbeat
 * Filebeat
 * Logstash
 * Elasticsearch (single node)
   * X-Pack plugin
     * License plugin
     * Shield
     * Marvel plugin
     * Watcher plugin
 * Kibana
   * X-Pack plugin
     * Shield
     * Marvel
     * Sense
   * Timelion
   
## Phase 2
Upgrade scenario, or Elastic Cloud integration test?

## Setting Up Your Environment

Install vagrant

Install the version of node.js listed in the .node-version file (this can be easily automated with tools such as nvm and avn).  On Windows you can just download and install the version of node.js from https://nodejs.org/en/

`nvm install "$(cat .node-version)"`

Start the process

`./run.sh`

The bash script `run.sh` runs `npm install` and `vagrant up` then runs the tests in the local browser.  The Vagrantfile is configured to call another script on the VM which downloads the builds, and installs them.
