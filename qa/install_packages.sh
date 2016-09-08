echo Install packages
if [ -z "$PRODUCTS" ]; then . ./setenv.sh; fi
for i in $PRODUCTS; do (
  sudo dpkg -l $i &> /dev/null || (echo -e "\n\nInstalling $i*.deb\n" && sudo dpkg -i --force-overwrite ./$i*.deb || exit 1)
); done
