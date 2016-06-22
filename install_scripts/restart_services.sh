# Start Services
if [ -z "$PRODUCTS" ]; then . ./setenv.sh; fi

for i in $PRODUCTS; do echo "-- restarting $i" & service $i restart; done

