---
layout: post
title: My Symfony Makefile
tags:
    - php
    - symfony
    - makefile
    - devops
    - introducing-tool
    - reference
---

Command your codebase with the crown of steel: [Make](https://www.gnu.org/software/make/),
the eternal overlord of task runners.

For a Docker-based Symfony project, typing mundane commands like running tests
can quickly become cumbersome:

```console
docker compose exec app symfony php vendor/bin/phpunit --testdoc
```

**Make** allows you to define a list of "rules" that provide:

* simple commands (eg `make test`)
* environment abstraction (eg `make console env=prod`)
* built-in documentation (run `make` to list available rules)
* combining multiple rules into a single one
  (eg `make qa` is equivalent to `make cs-check; make static-analysis; make test`)

With Make, the previous example becomes:

```console
make test arg=--testdox
```

* [Makefile](#makefile)
    * [Usage](#usage)
    * [Docker Compose version](#docker-compose-version)
    * [Docker version](#docker-version)
    * [Native PHP version](#native-php-version)

## Makefile

In this article, I'm sharing the Makefiles I use for my Symfony / PHP projects.

### Usage

Here are the rules I usually define:

```console
# 🐳 Docker related rules
## Build the Docker image
make build

## Start the services (eg database, message queue, etc)
make up

## Check the services logs
make logs

## Stop the services
make down

## Open interactive shell in container
make bash

# 🐘 Project related rules
## Install composer dependencies
make composer arg='install --optimize-autoloader'

## Run the Symfony console
make console arg='cache:clear'

### To change the environment
make console env=prod arg='cache:clear'

# 🛂 Quality Assurance related rules
## Run phpstan, php-cs-fixer (check) and phpunit
make qa

## To just run phpstan
make static-analysis

## To just run php-cs-fixer check
make cs-check

## To just run phpunit
make test

### To display technical specifications:
make test arg='--testdox'

### To just run Integration tests:
make test arg='./tests/Integration'

### To just run Unit tests:
make test arg='./tests/Unit'

# Run php-cs-fixer fix
make cs-fix

# Discover everything you can do
make
```

### Docker Compose version

Here's the `Makefile` I use in Docker-based Symfony projects, which use a database
(with Docker Compose):

```Makefile
# Parameters (optional)
# * `arg`: arbitrary arguments to pass to rules (default: none)
# * `env`: used to set `APP_ENV` (default: `test`)
arg ?=
env ?= test

# Executables (local)
DOCKER_RUN = docker run -it -v "$(PWD)":/app --user $(shell id -u):$(shell id -g)

# Docker containers
PHP_SERVICE = app
PHP_CONT = $(DOCKER_RUN) $(PHP_SERVICE)

# Executables
PHP = docker compose exec $(PHP_SERVICE) symfony php
COMPOSER = docker compose exec $(PHP_SERVICE) symfony composer
CONSOLE = docker compose exec -e APP_ENV=$(env) $(PHP_SERVICE) symfony console
PHINX = docker compose exec -e APP_ENV=$(env) $(PHP_SERVICE) symfony php vendor/bin/phinx
PHPUNIT = docker compose exec $(PHP_SERVICE) symfony php vendor/bin/phpunit
PHP_CS_FIXER = docker compose exec $(PHP_SERVICE) symfony php vendor/bin/php-cs-fixer
PHPSTAN = docker compose exec $(PHP_SERVICE) symfony php vendor/bin/phpstan

# Misc
.DEFAULT_GOAL = help
.PHONY: *

## —— 🎵 🐳 The Symfony Docker Makefile 🐳 🎵 ——————————————————————————————————
## Based on https://github.com/dunglas/symfony-docker
## (arg) denotes the possibility to pass "arg=" parameter to the target
##     this allows to add command and options, example: make composer arg='dump --optimize'
## (env) denotes the possibility to pass "env=" parameter to the target
##     this allows to set APP_ENV environment variable (default: test), example: make console env='prod' arg='cache:warmup'
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
build: ## Builds the Docker images
	@docker compose build --pull

up: ## Starts Docker Compose services, in detached mode (no logs)
	@docker compose up --detach

logs: ## Show live logs
	@docker compose logs --tail=0 --follow

down: ## Stops Docker Compose services
	@docker compose down --remove-orphans

bash: ## Connect to the container via bash so up and down arrows go to previous commands
	@docker compose exec $(PHP_SERVICE) bash

## —— PHP 🐘 ———————————————————————————————————————————————————————————————————
composer: ## Runs Composer (arg, eg `arg='install --optimize-autoloader'`)
	@$(COMPOSER) $(arg)

console: ## Runs bin/console (arg, eg `arg='cache:clear'`) (env, eg `env=prod`)
	@$(CONSOLE) $(arg)

phinx: ## Runs Phinx (arg, eg `arg='create MyMigration'`)
	@$(PHINX) $(arg)

migrate: ## Runs DB migrations (arg, eg `arg='--environment prod'`; env, eg env=prod)
	@$(PHINX) migrate --environment=$(env) $(arg)

## —— Quality 🛂 ———————————————————————————————————————————————————————————————
db-reset: ## Resets test database (drop, create, migrate, fixtures)
	@$(CONSOLE) doctrine:database:drop --force --if-exists
	@$(CONSOLE) doctrine:database:create --if-not-exists
	@$(PHINX) migrate --environment=$(env)
	@$(PHINX) seed:run --environment=$(env)

test: ## Runs the tests with PHPUnit (arg, eg `arg='./tests/Unit'`)
	@$(PHPUNIT) $(arg)

static-analysis: ## Static Analysis with phpstan (arg, eg `arg='./src/'`)
	@$(PHPSTAN) analyze $(arg)

cs-check: ## Checks CS with PHP-CS-Fixer (arg, eg `arg='./src'`)
	@$(PHP_CS_FIXER) check --verbose $(arg)

qa: ## Equivalent to cs-check && static-analysis && test
	@$(MAKE) cs-check
	@$(MAKE) static-analysis
	@$(MAKE) test

cs-fix: ## Fixes CS with PHP-CS-Fixer (arg, eg `arg='./src'`)
	@$(PHP_CS_FIXER) fix --verbose $(arg)
```

### Docker version

If your project doesn't have a database (or services),
and therefore relies on Docker directly (without Docker Compose),
here's what it could look like:

```Makefile
# Parameters (optional)
# * `arg`: arbitrary arguments to pass to rules (default: none)
# * `env`: used to set `APP_ENV` (default: `test`)
arg ?=
env ?= test

# Executables (local)
DOCKER_RUN = docker run -it -v "$(PWD)":/app --user $(shell id -u):$(shell id -g)

# Docker containers
PHP_SERVICE = app
PHP_CONT = $(DOCKER_RUN) $(PHP_SERVICE)

# Executables
PHP = $(PHP_CONT) symfony php
COMPOSER = $(PHP_CONT) symfony composer
CONSOLE = $(DOCKER_RUN) -e APP_ENV=$(env) $(PHP_SERVICE) symfony console
PHPUNIT = $(PHP_CONT) symfony php vendor/bin/phpunit
PHP_CS_FIXER = $(PHP_CONT) symfony php vendor/bin/php-cs-fixer
PHPSTAN = $(PHP_CONT) symfony php vendor/bin/phpstan

# Misc
.DEFAULT_GOAL = help
.PHONY: *

## —— 🎵 🐳 The Symfony Docker Makefile 🐳 🎵 ——————————————————————————————————
## Based on https://github.com/dunglas/symfony-docker
## (arg) denotes the possibility to pass "arg=" parameter to the target
##     this allows to add command and options, example: make composer arg='dump --optimize'
## (env) denotes the possibility to pass "env=" parameter to the target
##     this allows to set APP_ENV environment variable (default: test), example: make console env='prod' arg='cache:warmup'
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
build: ## Builds the Docker image
	@docker build -t $(PHP_SERVICE) .

bash: ## Connect to the container via bash so up and down arrows go to previous commands
	@$(DOCKER_RUN) $(PHP_SERVICE) bash

## —— PHP 🐘 ———————————————————————————————————————————————————————————————————
composer: ## Runs Composer (arg, eg `arg='install --optimize-autoloader'`)
	@$(COMPOSER) $(arg)

console: ## Runs bin/console (arg, eg `arg='cache:clear'`) (env, eg `env=prod`)
	@$(CONSOLE) $(arg)

## —— Quality 🛂 ———————————————————————————————————————————————————————————————
test: ## Runs the tests with PHPUnit (arg, eg `arg='./tests/Unit'`)
	@$(PHPUNIT) $(arg)

static-analysis: ## Static Analysis with phpstan (arg, eg `arg='./src/'`)
	@$(PHPSTAN) analyze $(arg)

cs-check: ## Checks CS with PHP-CS-Fixer (arg, eg `arg='./src'`)
	@$(PHP_CS_FIXER) check --verbose $(arg)

qa: ## Equivalent to cs-check && static-analysis && test
	@$(MAKE) cs-check
	@$(MAKE) static-analysis
	@$(MAKE) test

cs-fix: ## Fixes CS with PHP-CS-Fixer (arg, eg `arg='./src'`)
	@$(PHP_CS_FIXER) fix --verbose $(arg)
```

### Native PHP version

For pure PHP projects without Symfony CLI (or Symfony console),
that don't run in Docker Containers, the `Makefile` can look like this:

```Makefile
# Parameters (optional)
# * `arg`: arbitrary arguments to pass to rules (default: none)
# * `env`: used to set `APP_ENV` (default: `test`)
arg ?=
env ?= test

# Executables
PHP = php
COMPOSER = composer
PHPUNIT = php vendor/bin/phpunit
PHP_CS_FIXER = php vendor/bin/php-cs-fixer
PHPSTAN = php vendor/bin/phpstan

# Misc
.DEFAULT_GOAL = help
.PHONY: *

## —— 🎵 🐘 The Pure PHP Makefile 🐘 🎵 ——————————————————————————————————————
## Based on https://github.com/dunglas/symfony-docker
## (arg) denotes the possibility to pass "arg=" parameter to the target
##     this allows to add command and options, example: make composer arg='dump --optimize'
## (env) denotes the possibility to pass "env=" parameter to the target
##     this allows to set APP_ENV environment variable (default: test), example: make php env='prod' arg='script.php'
help: ## Outputs this help screen
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' | sed -e 's/\[32m##/[33m/'

## —— PHP 🐘 ———————————————————————————————————————————————————————————————————
composer: ## Runs Composer (arg, eg `arg='install --optimize-autoloader'`)
	@$(COMPOSER) $(arg)

php: ## Runs PHP (arg, eg `arg='script.php'`) (env, eg `env=prod`)
	@APP_ENV=$(env) $(PHP) $(arg)

## —— Quality 🛂 ———————————————————————————————————————————————————————————————
test: ## Runs the tests with PHPUnit (arg, eg `arg='./tests/Unit'`)
	@$(PHPUNIT) $(arg)

static-analysis: ## Static Analysis with phpstan (arg, eg `arg='./src/'`)
	@$(PHPSTAN) analyze $(arg)

cs-check: ## Checks CS with PHP-CS-Fixer (arg, eg `arg='./src'`)
	@$(PHP_CS_FIXER) check --verbose $(arg)

qa: ## Equivalent to cs-check && static-analysis && test
	@$(MAKE) cs-check
	@$(MAKE) static-analysis
	@$(MAKE) test

cs-fix: ## Fixes CS with PHP-CS-Fixer (arg, eg `arg='./src'`)
	@$(PHP_CS_FIXER) fix --verbose $(arg)
```

## Conclusion

With this, you can streamline your development workflow across projects
and focus on writing code instead of remembering complex Docker commands.

> **Note**: I took massive inspiration from Kevin Dunglas'
> [Symfony Docker Makefile](https://github.com/dunglas/symfony-docker).
