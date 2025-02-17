#!/bin/bash

set -e
DOCKER_COMPOSE=${DOCKER_COMPOSE:-docker-compose}

$DOCKER_COMPOSE up -d
$DOCKER_COMPOSE logs -f &

WWWX=$( $DOCKER_COMPOSE config --services | grep www )
while true ; do
	sleep 10
	echo -n "test | Waiting for $WWWX to initialize ... " >&2
	if $DOCKER_COMPOSE exec -T $WWWX $i systemctl is-active ipsilon-client-configure.service | tee /dev/stderr | grep -q '^active' ; then
		break
	fi
done

while true ; do
	sleep 10
	echo -n "test | Waiting for client to initialize ... " >&2
	if $DOCKER_COMPOSE exec -T client $i systemctl is-active setup-authorized-keys.service | tee /dev/stderr | grep -q '^active' ; then
		break
	fi
done

echo OK $0.
