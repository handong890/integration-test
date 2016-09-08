#!/bin/bash
# Start Services
if [ -z "$PRODUCTS" ]; then . ./setenv.sh; fi

for product in $PRODUCTS; do (
  case $product in
    logstash)
      if service $product status | grep "waiting"
        then (
          echo "-- Service $product start"
          service $product start
        )
      fi
      ;;
    *)
    if service $product status | grep "is not running"
      then (
        echo "-- Service $product start"
        service $product start
      )
    fi
    ;;
  esac
);
done
