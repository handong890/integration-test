#!/bin/bash
if [ -z "$NATIVEKIBANAUSER" ]; then . ./setenv.sh; fi

echo "-- Create kibanaUser ${NATIVEKIBANAUSER}/changeme"
curl -s -POST http://${ELASTICUSER}:${ELASTICPWD}@localhost:9200/_xpack/security/user/$NATIVEKIBANAUSER -d '{
  "password" : "changeme",
  "roles" : [ "kibanaUser" ],
  "full_name" : "Tony Stark",
  "email" : "tony@starkcorp.co",
  "metadata" : {
    "intelligence" : 7
  }
}'
