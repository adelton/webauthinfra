
ifndef DOCKER_COMPOSE
	DOCKER_COMPOSE := $(shell command -v docker-compose 2> /dev/null)
endif
ifndef DOCKER_COMPOSE
	DOCKER_COMPOSE := docker compose
endif

docker-compose.yml.www-with-app:
	 cp docker-compose.yml docker-compose.yml.www-with-app
	 patch docker-compose.yml.www-with-app < docker-compose.yml.www-with-app.patch

build: $(COMPOSE)
	if test -n "$(COMPOSE)" ; then $(DOCKER_COMPOSE) --file "$(COMPOSE)" build ; fi
	if test -z "$(COMPOSE)" ; then $(DOCKER_COMPOSE) build ; fi

run:
	DOCKER_COMPOSE="$(DOCKER_COMPOSE)" tests/run-docker-compose-up.sh $(COMPOSE)

test:
	tests/test.sh

