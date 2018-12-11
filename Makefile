
docker-compose.yml.www-with-app:
	 cp docker-compose.yml docker-compose.yml.www-with-app
	 patch docker-compose.yml.www-with-app < docker-compose.yml.www-with-app.patch

build: $(COMPOSE)
	if test -n "$(COMPOSE)" ; then docker-compose --file "$(COMPOSE)" build ; fi
	if test -z "$(COMPOSE)" ; then docker-compose build ; fi

run:
	tests/run-docker-compose-up.sh $(COMPOSE)

test:
	tests/test.sh

