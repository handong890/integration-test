#!/bin/bash
if [ -z "$NATIVEKIBANAUSER" ]; then . ./setenv.sh; fi

echo "-- Create Logstash role"

curl -s -POST http://${ELASTICUSER}:${ELASTICPWD}@localhost:9200/_xpack/security/role/logstash -d '{
  "cluster": ["manage_index_templates"],
  "indices": [
    {
      "names": [ "logstash-*" ],
      "privileges": ["write","delete","create_index"]
    }
  ]
}'

echo "-- Create Logstash user"
curl -s -POST http://${ELASTICUSER}:${ELASTICPWD}@localhost:9200/_xpack/security/user/${LOGSTASHUSER} -d '{
  "password" : "changeme",
  "roles" : [ "logstash" ],
  "full_name" : "loggy",
  "email" : "loggy@test.co"
}'
