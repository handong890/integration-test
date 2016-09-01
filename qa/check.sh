#!/bin/bash
if [ "$(id -u)" != "0" ]; then
   echo -e "\n\nERROR: This script must be run as root\n\n"
   exit 1
fi

if [ `grep DISTRIB_ID /etc/*-release | cut -d= -f2` != 'Ubuntu' ]; then
  echo -e "\n\nERROR: This script was written for Ubuntu (apt-get, dpkg, etc)\n\n"
  exit 1
fi

if [ -z "$PRODUCTS" ]; then . ./setenv.sh; fi


echo -e "\n `date`-----------------Package Information----------------------------------"
dpkg --list $PRODUCTS

echo -e "\n `date`-----------------Service Status---------------------------------------"
for i in $PRODUCTS; do service $i status; done

rm index.html*
# try 10 times, 2 seconds apart
echo -e "\n `date`------------wait for Elasticserach to be up----------------------------------------"
for i in `seq 1 20`; do echo "wget es index" && sleep 4 && wget -q --http-user=$ELASTICUSER --http-password=$ELASTICPWD http://localhost:9200 && break; done
cat index.html

echo -e "\n `date`----------- Wait for elasticsearch and kibana plugin status to be green ----------------"
for i in `seq 1 30`; do echo "${i} `date` grep kibana log for 'green'" && sleep 4 && grep '"plugin:elasticsearch@.*","info"],"pid":.*,"state":"green"' /var/log/kibana/kibana.stdout && break; done
for i in `seq 1 30`; do echo "${i} `date` grep kibana log for 'green'" && sleep 4 && grep '"plugin:kibana@.*","info"],"pid":.*,"state":"green"' /var/log/kibana/kibana.stdout && break; done
#for i in `seq 1 20`; do echo "grep kibana log for 'green'" && sleep 4 &&  journalctl -u kibana.service --since "5 minutes ago"| grep "plugin:elasticsearch.*green" && break; done


echo -e "\n `date`----------- Status of each kibana plugin ------------------------"
for plugin in kibana console xpack_main elasticsearch graph security reporting monitoring; do (
  echo -e "`grep "plugin:$plugin" /var/log/kibana/kibana.stdout | tail -n1 | sed 's|.*plugin:\(.*\)","info".*"state":"\([^"]*\).*|\2|'` ${plugin}"
)
done

#journalctl --since "2016-03-30"
#journalctl -u kibana.service
#echo -e "\n----------------------------------------------------------------------"
#/usr/share/elasticsearch/bin/xpack/esusers useradd admin -r admin -p notsecure

echo -e "\n `date`-----------------Shield File Users-----------------------------------------"
/usr/share/elasticsearch/bin/x-pack/users list
echo -e "\n `date`-----------------Shield Native Users-----------------------------------------"
curl -s -XGET http://$ELASTICUSER:$ELASTICPWD@127.0.0.1:9200/_xpack/security/user?pretty | grep username
echo -e "\n `date`-----------------Shield Native Roles-----------------------------------------"
curl -s -XGET http://$ELASTICUSER:$ELASTICPWD@127.0.0.1:9200/_xpack/security/role?pretty | grep ".*\".*{" | grep -v metadata | sed 's/: {//'

echo -e "\n `date`-- http://elastic:changeme@localhost:9200/_cat/indices"
curl -s http://elastic:changeme@localhost:9200/_cat/indices
