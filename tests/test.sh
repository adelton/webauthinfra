#!/bin/bash

set -e
set -x

WWW=$( docker ps | grep webauthinfra_www | awk '{ print $NF }' )
WWWAPP=$( docker ps | grep webauthinfra_wwwapp | awk '{ print $NF }' )
CLIENT=$( docker ps | grep webauthinfra_client | awk '{ print $NF }' )

if test -n "$WWWAPP" ; then
	docker cp src/www-mod_wsgi-gssapi.conf $WWWAPP:/data/www.conf
else
	docker cp src/www-proxy-gssapi.conf $WWW:/data/www.conf
fi
docker exec -ti $WWW systemctl restart httpd

# docker cp src/test-kerberos.py $CLIENT:/usr/local/bin/
docker exec $CLIENT runuser -u developer -- /usr/local/bin/test-kerberos.py $( cat ipa-data/admin-password )

if test -n "$WWWAPP" ; then
	docker cp src/www-mod_wsgi-saml.conf $WWWAPP:/data/www.conf
else
	docker cp src/www-proxy-saml.conf $WWW:/data/www.conf
fi
docker exec -ti $WWW systemctl restart httpd

# docker cp src/test-saml.py $CLIENT:/usr/local/bin/
docker exec $CLIENT runuser -u developer -- /usr/local/bin/test-saml.py $( cat ipa-data/admin-password )

if test -n "$WWWAPP" ; then
	docker cp src/www-mod_wsgi-openidc.conf $WWWAPP:/data/www.conf
else
	docker cp src/www-proxy-openidc.conf $WWW:/data/www.conf
fi
docker exec -ti $WWW systemctl restart httpd

# docker cp src/test-openidc.py $CLIENT:/usr/local/bin/
docker exec $CLIENT runuser -u developer -- /usr/local/bin/test-openidc.py $( cat ipa-data/admin-password )

echo OK $0.
