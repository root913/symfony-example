DOCKER_ENV_FILE=/.dockerenv
IN_DOCKER=1
BOLD := $(shell tput -Txterm bold)
RED := $(shell tput -Txterm setaf 1)
GREEN := $(shell tput -Txterm setaf 2)
YELLOW := $(shell tput -Txterm setaf 3)
RESET := $(shell tput -Txterm sgr0)

ifeq ($(shell test -e $(DOCKER_ENV_FILE) && echo -n yes),yes)
IN_DOCKER=1
else
IN_DOCKER=0
endif

default: help

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":[^:]*?## "}; {printf "\033[38;5;69m%-30s\033[38;5;38m %s\033[0m\n", $$1, $$2}'

setup: ## Setup project
	$(info --> Setup project)
ifeq ($(IN_DOCKER),1)
	@echo "${BOLD}${RED}Can run only in host machine!${RESET}"
	@exit 1
else
	chmod +x ./.tools/docker.sh
	./.tools/docker.sh
endif

dump: ## Generate database dump file
	$(info --> Generate database dump file)
ifeq ($(IN_DOCKER),1)
	@echo "${BOLD}${RED}Can run only in host machine!${RESET}"
	@exit 1
else
	chmod +x ./.tools/dump.sh
	./.tools/dump.sh
endif

build-dev: ## Build assets
	$(info --> Build assets)
ifeq ($(IN_DOCKER),1)
	yarn build:dev
else
	docker-compose exec php-fpm yarn build:dev
endif

build: build-dev

build-prod:
	$(info --> Build assets)
ifeq ($(IN_DOCKER),1)
	yarn build:prod
else
	docker-compose exec php-fpm yarn build:prod
endif

build-watch: ## Build and watch assets
	$(info --> Build and watch assets)
ifeq ($(IN_DOCKER),1)
	yarn build:watch
else
	docker-compose exec php-fpm yarn build:watch
endif

lint: ## ESLINT
	$(info --> ESLINT)
ifeq ($(IN_DOCKER),1)
	yarn lint
else
	docker-compose exec php-fpm yarn lint
endif

lint-fix: ## Fix ESLINT errors
	$(info --> Fix ESLINT errors)
ifeq ($(IN_DOCKER),1)
	yarn lint:fix
else
	docker-compose exec php-fpm yarn lint:fix
endif

php-cs-fixer: ## PHP-CS lint
	$(info --> PHP-CS lint)
ifeq ($(IN_DOCKER),1)
	vendor/bin/php-cs-fixer fix --using-cache=no --verbose
else
	docker-compose exec php-fpm php vendor/bin/php-cs-fixer fix --using-cache=no --verbose
endif

php-cs-fixer-dry: ## Fix PHP-CS errors
	$(info --> Fix PHP-CS errors)
ifeq ($(IN_DOCKER),1)
	vendor/bin/php-cs-fixer fix --dry-run --using-cache=no --verbose
else
	docker-compose exec php-fpm php vendor/bin/php-cs-fixer fix --dry-run --using-cache=no --verbose
endif

cache-clear: ## Clear all cache
	$(info --> Clear all cache)
ifeq ($(IN_DOCKER),1)
	bin/console cache:clear
else
	docker-compose exec php-fpm bash -c "bin/console cache:clear"
endif
