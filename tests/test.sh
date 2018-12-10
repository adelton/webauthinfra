#!/bin/bash

set -e
set -x

WWW=$( docker ps | grep webauthinfra_www | awk '{ print $NF }' )
CLIENT=$( docker ps | grep webauthinfra_client | awk '{ print $NF }' )

docker cp src/www-proxy-gssapi.conf $WWW:/data/www.conf
docker exec -ti $WWW systemctl restart httpd

# docker cp src/test-kerberos.py $CLIENT:/usr/local/bin/
docker exec $CLIENT runuser -u developer -- /usr/local/bin/test-kerberos.py $( cat ipa-data/admin-password )

docker cp src/www-proxy-saml.conf $WWW:/data/www.conf
docker exec -ti $WWW systemctl restart httpd

# docker cp src/test-saml.py $CLIENT:/usr/local/bin/
docker exec $CLIENT runuser -u developer -- /usr/local/bin/test-saml.py $( cat ipa-data/admin-password )

echo OK $0.
