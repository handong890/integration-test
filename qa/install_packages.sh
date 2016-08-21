echo Install packages
if [ -z "$PRODUCTS" ]; then . ./setenv.sh; fi
for i in $PRODUCTS; do sudo dpkg -l $i || echo "Installing $i*.deb" & dpkg -i --force-overwrite ./$i*.deb || exit 1; done
