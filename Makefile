
ifndef DOCKER_COMPOSE
	DOCKER_COMPOSE := $(shell command -v docker-compose 2> /dev/null)
endif
ifndef DOCKER_COMPOSE
	DOCKER_COMPOSE := docker compose
endif

ifdef COMPOSE
	DOCKER_COMPOSE := $(DOCKER_COMPOSE) --file $(COMPOSE)
endif

all: build run test stop

docker-compose.yml.www-with-app:
	 cp docker-compose.yml docker-compose.yml.www-with-app
	 patch docker-compose.yml.www-with-app < docker-compose.yml.www-with-app.patch

build: $(COMPOSE)
	$(DOCKER_COMPOSE) build

run:
	DOCKER_COMPOSE="$(DOCKER_COMPOSE)" tests/run-docker-compose-up.sh

test:
	tests/test.sh

stop: $(COMPOSE)
	$(DOCKER_COMPOSE) down

.PHONY: build run test stop

