#!/bin/bash

set -e
DOCKER_COMPOSE=${DOCKER_COMPOSE:-docker-compose}

$DOCKER_COMPOSE up -d
if [[ "$DOCKER_COMPOSE" =~ podman-compose ]] ; then
	LOGS_OPTS=-n
fi
$DOCKER_COMPOSE logs $LOGS_OPTS -f &
set +e

RESULT=true
$DOCKER_COMPOSE config --services | grep -vF app | while read s ; do
	while ! if [[ "$DOCKER_COMPOSE" =~ podman-compose ]] ; then
		$DOCKER_COMPOSE ps --format json | jq -r --arg service $s '.[].Labels["com.docker.compose.service"] | select(. == $service)'
		else $DOCKER_COMPOSE ps $s ; fi | grep -q . ; do
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
