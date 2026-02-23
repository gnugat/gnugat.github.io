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

> **Note**: Updated on 2026-02-23.

For a Docker-based Symfony project, without [Make](https://www.gnu.org/software/make/),
typing commands like running tests can quickly become cumbersome:

```console
docker compose exec app php vendor/bin/phpunit --testdox
```

**Make** allows you to define a list of "rules" that provide:

* simple commands (eg `make phpunit`)
* environment abstraction (eg `make console env=prod`)
* built-in documentation (run `make` to list available rules)
* combining multiple rules into a single one
  (eg `make app-qa` is equivalent to `make composer-dump; make cs-check; make phpstan; make rector-check; make phpunit`)

With Make, the previous example becomes:

```console
make phpunit arg=--testdox
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
## Build the Docker images and start the services
make docker-init

## Check the services logs
make docker-compose arg='logs --tail=0 --follow'

## Stop the services
make docker-down

## Open interactive shell in container
make docker-bash

# 🐘 Project related rules
## Install composer dependencies
make composer-install

## Run the Symfony console
make console arg='cache:clear'

### To change the environment
make console env=prod arg='cache:clear'

# 🛂 Quality Assurance related rules
## Run composer-dump, phpstan, php-cs-fixer (check), rector (check) and phpunit
make app-qa

## To just run phpstan
make phpstan-analyze

## To just run php-cs-fixer check
make cs-check

## To just run phpunit
make phpunit

### To display technical specifications:
make phpunit arg='--testdox'

### To just run Integration tests:
make phpunit arg='./tests/Integration'

### To just run Unit tests:
make phpunit arg='./tests/Unit'

# Run php-cs-fixer fix (with Swiss Knife for namespaces)
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

# Docker containers
PHP_SERVICE = app

# Executables
COMPOSER = docker compose exec $(PHP_SERVICE) composer
CONSOLE = docker compose exec -e APP_ENV=$(env) $(PHP_SERVICE) php bin/console
PHPUNIT = docker compose exec $(PHP_SERVICE) php vendor/bin/phpunit
PHP_CS_FIXER = docker compose exec $(PHP_SERVICE) php vendor/bin/php-cs-fixer
PHPSTAN = docker compose exec $(PHP_SERVICE) php vendor/bin/phpstan --memory-limit=256M
RECTOR = docker compose exec $(PHP_SERVICE) php vendor/bin/rector
SWISS_KNIFE = docker compose exec $(PHP_SERVICE) php vendor/bin/swiss-knife

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
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' \
		| sed -e 's/\[32m##/[33m/'

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
docker: ## Runs Docker (arg, eg `arg='compose logs --tail=0 --follow'`)
	@docker $(arg)

docker-compose: ## Runs Docker Compose (arg, eg `arg='logs --tail=0 --follow'`)
	@docker compose $(arg)

docker-init: ## Builds the Docker images and starts the services in detached mode (no logs)
	@docker compose build --pull
	@docker compose up --detach

docker-down: ## Stops the services
	@docker compose down --remove-orphans

docker-bash: ## Opens a (bash) shell in the container
	@docker compose exec $(PHP_SERVICE) bash

## —— PHP 🐘 ———————————————————————————————————————————————————————————————————
composer: ## Runs Composer (arg, eg `arg='outdated'`)
	@$(COMPOSER) $(arg)

composer-install: ## Install dependencies (arg, eg `arg='--no-dev'`)
	@$(COMPOSER) install --optimize-autoloader $(arg)

composer-update: ## Updates dependencies (arg, eg `arg='--no-dev'`)
	@$(COMPOSER) update --optimize-autoloader $(arg)

composer-dump: ## Dumps autoloader (arg, eg `arg='--classmap-authoritative'`)
	@$(COMPOSER) dump-autoload --optimize --strict-psr --strict-ambiguous $(arg)

console: ## Runs bin/console (arg, eg `arg='cache:clear'`) (env, eg `env=prod`)
	@$(CONSOLE) $(arg)

cs-check: ## Checks CS with PHP-CS-Fixer (arg, eg `arg='./src'`)
	@$(PHP_CS_FIXER) check --verbose $(arg)

cs-fix: ## Fixes CS with Swiss Knife and PHP-CS-Fixer
	@$(SWISS_KNIFE) namespace-to-psr-4 src --namespace-root 'App\\'
	@$(SWISS_KNIFE) namespace-to-psr-4 tests --namespace-root 'App\\Tests\\'
	@$(PHP_CS_FIXER) fix --verbose $(arg)

phpstan: ## Runs phpstan (arg, eg `arg='clear-result-cache'`)
	@$(PHPSTAN) $(arg)

phpstan-analyze: ## Static Analysis with phpstan (arg, eg `arg='./src/'`)
	@$(PHPSTAN) analyze $(arg)

swiss-knife: ## Automated refactorings with Swiss Knife (arg, eg `arg='namespace-to-psr-4 src --namespace-root \'App\\\''`)
	@$(SWISS_KNIFE) $(arg)

phpunit: ## Runs the tests with PHPUnit (arg, eg `arg='./tests/Unit'`)
	@docker compose exec $(PHP_SERVICE) sh bin/sfcc-if-stale.sh test
	@$(PHPUNIT) $(arg)

rector-fix: ## Automated refactorings with Rector (arg, eg `arg='--clear-cache'`)
	@$(RECTOR) $(arg)

rector-check: ## Refactoring checks with Rector
	@$(RECTOR) process --dry-run

## —— App 📱 ———————————————————————————————————————————————————————————————————
app-init: ## First install / resetting (Docker build, up, etc)
	@echo ''
	@echo '  // Stopping docker services...'
	@$(MAKE) docker-down
	@echo ''
	@echo '  // Starting docker services...'
	@$(MAKE) docker-init
	@echo ''
	@echo '  // Installing Composer dependencies...'
	@$(MAKE) composer-install
	@echo ''
	@echo '  [OK] App initialized'

app-clear: ## Clears the Symfony cache (env, eg `env='prod'`)
	@$(CONSOLE) cache:clear

app-qa: ## Runs full QA pipeline (composer-dump, cs-check, phpstan, rector-check, phpunit)
	@echo ''
	@echo '  // Running composer dump...'
	@$(MAKE) composer-dump
	@echo ''
	@echo '  // Running PHP CS Fixer...'
	@$(MAKE) cs-check
	@echo ''
	@echo '  // Running PHPStan...'
	@$(MAKE) phpstan
	@echo ''
	@echo '  // Running Rector...'
	@$(MAKE) rector-check
	@echo ''
	@echo '  // Running PHPUnit...'
	@$(MAKE) phpunit
	@echo ''
	@echo '  [OK] QA done'
```

#### bin/sfcc-if-stale.sh

The `phpunit` rule calls a script that clears the Symfony cache only when stale,
since unlike `dev`, the `test` environment doesn't auto-invalidate on source changes:

```bash
#!/usr/bin/env bash
# File: /apps/qa/bin/sfcc-if-stale.sh
# ──────────────────────────────────────────────────────────────────────────────
# Symfony cache clear, but only if it's stale.
#
# Unlike dev, test and prod environments don't auto-invalidate cache when source
# files change. Changes to services, routes, Twig templates, Doctrine mappings,
# or environment variables all require a cache clear.
#
# This script detects stale cache by comparing modification times of src/,
# config/, and .env* files against the cache directory.
#
# Usage:
#
# ```shell
# bin/clear-cache-if-stale.sh
# bin/clear-cache-if-stale.sh prod
# ```
#
# Arguments:
#
# 1. `env`: Symfony environment, defaults to `test`
# ──────────────────────────────────────────────────────────────────────────────

_CLEAR_CACHE_ENV=${1:-test}
_CLEAR_CACHE_DIR="var/cache/${_CLEAR_CACHE_ENV}"

if [ ! -d "${_CLEAR_CACHE_DIR}" ]; then
    echo "  // Symfony cache directory does not exist, clearing..."
    php bin/console cache:clear --env="${_CLEAR_CACHE_ENV}"
    exit 0
fi

if [ -n "$(find src config .env* -newer "${_CLEAR_CACHE_DIR}" -print -quit 2>/dev/null)" ]; then
    echo "  // Symfony cache stale, clearing cache..."
    php bin/console cache:clear --env="${_CLEAR_CACHE_ENV}"
    exit 0
fi

echo "  // Symfony cache is up to date"
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
COMPOSER = $(PHP_CONT) composer
CONSOLE = $(DOCKER_RUN) -e APP_ENV=$(env) $(PHP_SERVICE) php bin/console
PHPUNIT = $(PHP_CONT) php vendor/bin/phpunit
PHP_CS_FIXER = $(PHP_CONT) php vendor/bin/php-cs-fixer
PHPSTAN = $(PHP_CONT) php vendor/bin/phpstan --memory-limit=256M
RECTOR = $(PHP_CONT) php vendor/bin/rector
SWISS_KNIFE = $(PHP_CONT) php vendor/bin/swiss-knife

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
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' \
		| sed -e 's/\[32m##/[33m/'

## —— Docker 🐳 ————————————————————————————————————————————————————————————————
docker-init: ## Builds the Docker image
	@docker build -t $(PHP_SERVICE) .

docker-bash: ## Opens a (bash) shell in the container
	@$(DOCKER_RUN) $(PHP_SERVICE) bash

## —— PHP 🐘 ———————————————————————————————————————————————————————————————————
composer: ## Runs Composer (arg, eg `arg='outdated'`)
	@$(COMPOSER) $(arg)

composer-install: ## Install dependencies (arg, eg `arg='--no-dev'`)
	@$(COMPOSER) install --optimize-autoloader $(arg)

composer-update: ## Updates dependencies (arg, eg `arg='--no-dev'`)
	@$(COMPOSER) update --optimize-autoloader $(arg)

composer-dump: ## Dumps autoloader (arg, eg `arg='--classmap-authoritative'`)
	@$(COMPOSER) dump-autoload --optimize --strict-psr --strict-ambiguous $(arg)

console: ## Runs bin/console (arg, eg `arg='cache:clear'`) (env, eg `env=prod`)
	@$(CONSOLE) $(arg)

cs-check: ## Checks CS with PHP-CS-Fixer (arg, eg `arg='./src'`)
	@$(PHP_CS_FIXER) check --verbose $(arg)

cs-fix: ## Fixes CS with Swiss Knife and PHP-CS-Fixer
	@$(SWISS_KNIFE) namespace-to-psr-4 src --namespace-root 'App\\'
	@$(SWISS_KNIFE) namespace-to-psr-4 tests --namespace-root 'App\\Tests\\'
	@$(PHP_CS_FIXER) fix --verbose $(arg)

phpstan: ## Runs phpstan (arg, eg `arg='clear-result-cache'`)
	@$(PHPSTAN) $(arg)

phpstan-analyze: ## Static Analysis with phpstan (arg, eg `arg='./src/'`)
	@$(PHPSTAN) analyze $(arg)

swiss-knife: ## Automated refactorings with Swiss Knife (arg, eg `arg='namespace-to-psr-4 src --namespace-root \'App\\\''`)
	@$(SWISS_KNIFE) $(arg)

phpunit: ## Runs the tests with PHPUnit (arg, eg `arg='./tests/Unit'`)
	@$(PHPUNIT) $(arg)

rector-fix: ## Automated refactorings with Rector (arg, eg `arg='--clear-cache'`)
	@$(RECTOR) $(arg)

rector-check: ## Refactoring checks with Rector
	@$(RECTOR) process --dry-run

## —— App 📱 ———————————————————————————————————————————————————————————————————
app-init: ## First install
	@echo ''
	@echo '  // Building docker image...'
	@$(MAKE) docker-init
	@echo ''
	@echo '  // Installing Composer dependencies...'
	@$(MAKE) composer-install
	@echo ''
	@echo '  [OK] App initialized'

app-qa: ## Runs full QA pipeline (composer-dump, cs-check, phpstan, rector-check, phpunit)
	@echo ''
	@echo '  // Running composer dump...'
	@$(MAKE) composer-dump
	@echo ''
	@echo '  // Running PHP CS Fixer...'
	@$(MAKE) cs-check
	@echo ''
	@echo '  // Running PHPStan...'
	@$(MAKE) phpstan
	@echo ''
	@echo '  // Running Rector...'
	@$(MAKE) rector-check
	@echo ''
	@echo '  // Running PHPUnit...'
	@$(MAKE) phpunit
	@echo ''
	@echo '  [OK] QA done'
```

### Native PHP version

For pure PHP projects without Symfony,
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
PHPSTAN = php vendor/bin/phpstan --memory-limit=256M
RECTOR = php vendor/bin/rector
SWISS_KNIFE = php vendor/bin/swiss-knife

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
	@grep -E '(^[a-zA-Z0-9\./_-]+:.*?##.*$$)|(^##)' $(MAKEFILE_LIST) \
		| awk 'BEGIN {FS = ":.*?## "}{printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}' \
		| sed -e 's/\[32m##/[33m/'

## —— PHP 🐘 ———————————————————————————————————————————————————————————————————
composer: ## Runs Composer (arg, eg `arg='outdated'`)
	@$(COMPOSER) $(arg)

composer-install: ## Install dependencies (arg, eg `arg='--no-dev'`)
	@$(COMPOSER) install --optimize-autoloader $(arg)

composer-update: ## Updates dependencies (arg, eg `arg='--no-dev'`)
	@$(COMPOSER) update --optimize-autoloader $(arg)

composer-dump: ## Dumps autoloader (arg, eg `arg='--classmap-authoritative'`)
	@$(COMPOSER) dump-autoload --optimize --strict-psr --strict-ambiguous $(arg)

php: ## Runs PHP (arg, eg `arg='script.php'`) (env, eg `env=prod`)
	@APP_ENV=$(env) $(PHP) $(arg)

cs-check: ## Checks CS with PHP-CS-Fixer (arg, eg `arg='./src'`)
	@$(PHP_CS_FIXER) check --verbose $(arg)

cs-fix: ## Fixes CS with Swiss Knife and PHP-CS-Fixer
	@$(SWISS_KNIFE) namespace-to-psr-4 src --namespace-root 'App\\'
	@$(SWISS_KNIFE) namespace-to-psr-4 tests --namespace-root 'App\\Tests\\'
	@$(PHP_CS_FIXER) fix --verbose $(arg)

phpstan: ## Runs phpstan (arg, eg `arg='clear-result-cache'`)
	@$(PHPSTAN) $(arg)

phpstan-analyze: ## Static Analysis with phpstan (arg, eg `arg='./src/'`)
	@$(PHPSTAN) analyze $(arg)

swiss-knife: ## Automated refactorings with Swiss Knife (arg, eg `arg='namespace-to-psr-4 src --namespace-root \'App\\\''`)
	@$(SWISS_KNIFE) $(arg)

phpunit: ## Runs the tests with PHPUnit (arg, eg `arg='./tests/Unit'`)
	@$(PHPUNIT) $(arg)

rector-fix: ## Automated refactorings with Rector (arg, eg `arg='--clear-cache'`)
	@$(RECTOR) $(arg)

rector-check: ## Refactoring checks with Rector
	@$(RECTOR) process --dry-run

## —— App 📱 ———————————————————————————————————————————————————————————————————
app-init: ## First install
	@echo ''
	@echo '  // Installing Composer dependencies...'
	@$(MAKE) composer-install
	@echo ''
	@echo '  [OK] App initialized'

app-qa: ## Runs full QA pipeline (composer-dump, cs-check, phpstan, rector-check, phpunit)
	@echo ''
	@echo '  // Running composer dump...'
	@$(MAKE) composer-dump
	@echo ''
	@echo '  // Running PHP CS Fixer...'
	@$(MAKE) cs-check
	@echo ''
	@echo '  // Running PHPStan...'
	@$(MAKE) phpstan
	@echo ''
	@echo '  // Running Rector...'
	@$(MAKE) rector-check
	@echo ''
	@echo '  // Running PHPUnit...'
	@$(MAKE) phpunit
	@echo ''
	@echo '  [OK] QA done'
```

## Conclusion

With this, you can streamline your development workflow across projects
and focus on writing code instead of remembering complex Docker commands.

> **Note**: I took massive inspiration from Kevin Dunglas'
> [Symfony Docker Makefile](https://github.com/dunglas/symfony-docker).
