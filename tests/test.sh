#!/bin/bash

set -x

DOCKER_COMPOSE=${DOCKER_COMPOSE:-docker-compose}

WWWX=$( $DOCKER_COMPOSE config --services | grep -F www )
WWWAPP=$( $DOCKER_COMPOSE config --services | grep -Fx wwwapp )

set -e
if test -n "$WWWAPP" ; then
	$DOCKER_COMPOSE cp src/www-mod_wsgi-gssapi.conf wwwapp:/data/www.conf
else
	$DOCKER_COMPOSE cp src/www-proxy-gssapi.conf www:/data/www.conf
fi
$DOCKER_COMPOSE exec -T $WWWX systemctl restart httpd

$DOCKER_COMPOSE exec -T client runuser -u developer -- /usr/local/bin/test-kerberos.py $( cat ipa-data/admin-password )

if test -n "$WWWAPP" ; then
	$DOCKER_COMPOSE cp src/www-mod_wsgi-saml.conf wwwapp:/data/www.conf
else
	$DOCKER_COMPOSE cp src/www-proxy-saml.conf www:/data/www.conf
fi
$DOCKER_COMPOSE exec -T $WWWX systemctl restart httpd

$DOCKER_COMPOSE exec -T client runuser -u developer -- /usr/local/bin/test-saml.py $( cat ipa-data/admin-password )

if test -n "$WWWAPP" ; then
	$DOCKER_COMPOSE cp src/www-mod_wsgi-openidc.conf wwwapp:/data/www.conf
else
	$DOCKER_COMPOSE cp src/www-proxy-openidc.conf www:/data/www.conf
fi
$DOCKER_COMPOSE exec -T $WWWX systemctl restart httpd

$DOCKER_COMPOSE exec -T client runuser -u developer -- /usr/local/bin/test-openidc.py $( cat ipa-data/admin-password )

echo OK $0.
