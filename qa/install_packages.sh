echo Install packages
if [ -z "$PRODUCTS" ]; then . ./setenv.sh; fi
for i in $PRODUCTS; do echo "-- Installing $i*.deb" & dpkg -i ./$i*.deb || exit 1; done

