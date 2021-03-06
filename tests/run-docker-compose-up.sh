#!/bin/bash

set -e

if test -n "$COMPOSE" ; then
	docker-compose --file $COMPOSE up &
else
	docker-compose up &
fi

while ! docker ps | grep webauthinfra_www ; do
	sleep 5
done
docker ps | grep webauthinfra_www | awk '{ print $NF }' | while read i ; do
	while true ; do
		sleep 10
		echo -n "test | Waiting for $i to initialize ... " >&2
		if docker exec $i systemctl is-active ipsilon-client-configure.service | tee /dev/stderr | grep -q '^active' ; then
			break
		fi
	done
done

while ! docker ps | grep webauthinfra_client ; do
	sleep 5
done
docker ps | grep webauthinfra_client | awk '{ print $NF }' | while read i ; do
	while true ; do
		sleep 10
		echo -n "test | Waiting for $i to initialize ... " >&2
		if docker exec $i systemctl is-active setup-authorized-keys.service | tee /dev/stderr | grep -q '^active' ; then
			break
		fi
	done
done

echo OK $0.
