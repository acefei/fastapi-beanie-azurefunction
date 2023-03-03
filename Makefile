.PHONY: help
.DEFAULT_GOAL := help

define PRINT_HELP_PYSCRIPT
import re, sys

for line in sys.stdin:
	match = re.match(r'^([^:]+):[^#]+##([^#]+)', line)
	if match:
		target, help = match.groups()
		print("%-10s %s" % (target, help))
endef
export PRINT_HELP_PYSCRIPT

help:
	@python3 -c "$$PRINT_HELP_PYSCRIPT" < $(MAKEFILE_LIST)

start:  ## start azure function app locally
	@docker-compose up -d --build

stop:  ## stop azure function app locally
	@docker-compose stop

restart: stop
	@docker-compose up -d --build

test:  ## test api locally, please ensure start app at first
	@curl http://localhost:7071/hello/acefei

watch:  ## monitoring log
	@docker-compose logs -f azure_functions_app

state:  ## check docker state
	@docker-compose ps

debug:  ## go to container to debug
	@docker-compose exec azure_functions_app bash

init:  ## install pre-commit
	@command -v pre-commit >/dev/null 2>&1 || (pip install pre-commit --no-cache-dir && pre-commit install)

db:  ## Create a database and collection for API for MongoDB for Azure Cosmos DB using Azure CLI
	@bash create_mongodb_for_cosmosdb.sh

pre-commit: init ## run pre-commit manually
	@pre-commit autoupdate && pre-commit run --all-files | tee pre-commit.log
