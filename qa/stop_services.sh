#!/bin/bash
# Start Services
if [ -z "$PRODUCTS" ]; then . ./setenv.sh; fi

for i in $PRODUCTS; do echo "-- Stopping $i" & service $i stop; done

