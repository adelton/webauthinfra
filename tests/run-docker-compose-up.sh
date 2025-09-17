#!/bin/bash

set -e
DOCKER_COMPOSE=${DOCKER_COMPOSE:-docker-compose}

$DOCKER_COMPOSE up -d
$DOCKER_COMPOSE logs -f &

docker ps | grep webauthinfra.www | awk '{ print $NF }' | while read i ; do
	while true ; do
		sleep 10
		echo -n "test | Waiting for $i to initialize ... " >&2
		if docker exec $i systemctl is-active ipsilon-client-configure.service | tee /dev/stderr | grep -q '^active' ; then
			break
		fi
	done
done

docker ps | grep webauthinfra.client | awk '{ print $NF }' | while read i ; do
	while true ; do
		sleep 10
		echo -n "test | Waiting for $i to initialize ... " >&2
		if docker exec $i systemctl is-active setup-authorized-keys.service | tee /dev/stderr | grep -q '^active' ; then
			break
		fi
	done
done

echo OK $0.
