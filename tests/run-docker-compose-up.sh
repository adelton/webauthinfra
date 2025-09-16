#!/bin/bash

set -e
DOCKER_COMPOSE=${DOCKER_COMPOSE:-docker-compose}

$DOCKER_COMPOSE up -d
$DOCKER_COMPOSE logs -f &
set +e

RESULT=true
$DOCKER_COMPOSE config --services | grep -vF app | while read s ; do
	while ! $DOCKER_COMPOSE ps $s > /dev/null ; do
		sleep 5
	done
	STATUS=offline
	while true ; do
		STATUS=$( $DOCKER_COMPOSE exec -T $s systemctl is-system-running --wait < /dev/null )
		IRESULT=$?
		if [ "$STATUS" != offline ] ; then break ; fi
		sleep 5
	done
	echo "$s: $STATUS"
	if [ $IRESULT -ne 0 ] ; then
		RESULT=false
		$DOCKER_COMPOSE exec -T $s systemctl status --failed < /dev/null
	fi
	$RESULT
done
[ $? -ne 0 ] && exit 1

echo OK $0.
