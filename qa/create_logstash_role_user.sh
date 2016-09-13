#!/bin/bash
if [ -z "$NATIVEKIBANAUSER" ]; then . ./setenv.sh; fi

echo "-- Create Logstash role"

curl -s -POST http://${ELASTICUSER}:${ELASTICPWD}@localhost:9200/_xpack/security/role/logstash_writer -d '{
  "cluster": ["manage_index_templates","monitor"],
  "indices": [
    {
      "names": [ "logstash-*" ],
      "privileges": ["write","delete","create_index"]
    }
  ]
}'

echo "-- Create logstash_internal user"
curl -s -POST http://${ELASTICUSER}:${ELASTICPWD}@localhost:9200/_xpack/security/user/logstash_internal -d '{
  "password" : "changeme",
  "roles" : [ "logstash_writer" ],
  "full_name" : "logstash_internal",
  "email" : "logstash_internal@test.co"
}'
