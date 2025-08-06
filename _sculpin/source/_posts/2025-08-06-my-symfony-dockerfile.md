---
layout: post
title: My Symfony Dockerfile
tags:
    - php
    - symfony
    - docker
    - devops
    - introducing-tool
    - reference
---

Dockerize your PHP / Symfony application, to eliminate "works on MY machine".

I'm describing here a solution that ensures consistent development environment,
to run the project locally with just a few commands, without having to worry about:

* PHP version / extensions
* database / search engine / messaging queue / services setup

* [Dockerfile](#dockerfile)
* [Dockerignore](#dockerignore)
* [Compose](#compose)
* [Going further](#going-further)
    * [SQLite](#sqlite)

## Dockerfile

The following `Dockerfile` will build an image with:

* **Alpine Linux**
    + Lightweight distribution (5-10MB compared to 100MB for Ubuntu)
    - uses _musl libc_ instead of glibc, expect incompatibility issues with some binaries
* **PHP 8.3**
    + this is needed for any PHP applications
    + change the version to your liking
* **bash**
    + not required, but I like to use bash as my shell when I connect to the container
* **Composer**
    - in production, you don't need the Composer binary in the container
    + in development, it's useful to have the same running environment for your app and Composer
* **PostgreSQL**
    + my favourite database
    + skip it or switch it to MySQL, SQLite, etc
* **Symfony CLI**
    - in production, you don't need the Symfony CLI binary in the container
    + in development, useful to start a web server

```
# syntax=docker/dockerfile:1

###
# PHP Dev Container
# Utility Tools: PHP, bash, Composer, PostgreSQL, Symfony CLI
###
FROM php:8.3-cli-alpine AS php_dev_container

# Composer environment variables:
# * default user is superuser (root), so allow them
# * put cache directory in a readable/writable location
# _Note_: When running `composer` in container, use `--no-cache` option
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_CACHE_DIR=/tmp/.composer/cache

# Install dependencies:
# * bash for shell access and scripting
# * postgresql for the database
# * zip for composer packages that use ZIP archives
# _Note (Alpine)_: `--no-cache` includes `--update` and keeps image size minimal
#
# Then install PHP extensions
#
# _Note (Hadolint)_: No version locking, since Alpine only ever provides one version
# hadolint ignore=DL3018
RUN apk add --update --no-cache \
        bash \
        libzip-dev \
        postgresql-dev \
        zip \
    && docker-php-ext-install \
        bcmath \
        zip \
        pdo_pgsql

# Copy Symfony CLI binary from image
# _Note_: Avoid using Symfony CLI installer, use Docker image instead
# See: https://github.com/symfony-cli/symfony-cli/issues/195#issuecomment-1273269735
# _Note (Hadolint)_: False positive as `COPY` works with images too
# See: https://github.com/hadolint/hadolint/issues/197#issuecomment-1016595425
# hadolint ignore=DL3022
COPY --from=ghcr.io/symfony-cli/symfony-cli:v5 /usr/local/bin/symfony /usr/local/bin/symfony

# Copy Composer binary from composer image
# _Note (Hadolint)_: False positive as `COPY` works with images too
# See: https://github.com/hadolint/hadolint/issues/197#issuecomment-1016595425
# hadolint ignore=DL3022
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /app

# Caching `composer install`, as long as composer.{json,lock} don't change.
COPY composer.json composer.lock ./
RUN composer install \
    --no-cache \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --optimize-autoloader

# Copy the remaining application files (excluding those listed in .dockerignore)
COPY . .
```

You can check the validity of your Dockerfile syntax here: [hadolint](https://hadolint.github.io/hadolint/)

Here's how to build the image, and then run the container:

> **Note**: `-v "$(PWD)":/app` mounts current directory for live code changes.

```console
docker build -t app .

# Run with interactive shell
docker run --rm -it -v "$(PWD)":/app app bash

# Run composer
docker run --rm -it -v "$(PWD)":/app app symfony composer install -o

# Run symfony's console
docker run --rm -it -v "$(PWD)":/app -e APP_ENV=prod app symfony console

# Run PHPUnit, phpstan, PHP CS Fixer
docker run --rm -it -v "$(PWD)":/app app symfony php vendor/bin/phpunit
docker run --rm -it -v "$(PWD)":/app app symfony php vendor/bin/phpstan analyze
docker run --rm -it -v "$(PWD)":/app app symfony php vendor/bin/php-cs-fixer check --verbose
docker run --rm -it -v "$(PWD)":/app app symfony php vendor/bin/php-cs-fixer fix --verbose

# Start Symfony CLI's web server
docker run --rm -it -v "$(PWD)":/app -p 8000:8000 app symfony server:start --port=8000 --host=0.0.0.0
```

## Dockerignore

When using `COPY . .` in `Dockerfile`, it's useful to limit what's going to be copied, with a `.dockerignore`:

```
## composer
vendor

## git
.git/

## friendsofphp/php-cs-fixer
.php-cs-fixer.php
.php-cs-fixer.cache

## phpstan/phpstan
phpstan.neon

## phpunit/phpunit
phpunit.xml
.phpunit.cache

## symfony/framework-bundle
.env.local
.env.local.php
.env.*.local
var/cache/
var/log/
```

## Compose

When the PHP application relies on other services,
such as a database (eg PostgreSQL), search engine (eg Elasticsearch), or message queue (eg RabbitMQ),
having a `compose.yaml` file will make the development experience much smoother
by handling services, networking, and volumes automatically:

```yaml
services:
  app:
    build: .
    # Mount current directory into container for live code changes
    volumes:
      - .:/app
    # Database should be started first
    depends_on:
      - db
    ports:
      - "8000:8000"
    command: symfony serve --no-tls --port=8000 --listen-ip=0.0.0.0

  db:
    image: postgres:${POSTGRES_VERSION:-16}-alpine
    environment:
        POSTGRES_DB: ${POSTGRES_DB:-app}
        POSTGRES_PASSWORD: ${POSTGRES_PASSWORD:-ChangeMe}
        POSTGRES_USER: ${POSTGRES_USER:-app}
    # Persist database data between container restarts
    volumes:
      - db-data:/var/lib/postgresql/data:rw
    # Port mapping to avoid conflict with locally running PostgreSQL
    ports:
      - "5433:5432"

# Define the db-data volume used above
volumes:
  db-data:
```

Now usage commands will be a bit different:

```console
# Build docker images
docker compose build --pull
# Start services (no logs)
docker compose up --detach
# Show live logs
docker compose logs --tail=0 --follow
# Stop services
docker compose down --remove-orphans

# Run with interactive shell
docker compose exec app bash

# Run composer
docker compose exec app symfony composer

# Run symfony's console
docker compose exec -e APP_ENV=prod app symfony console

# Run PHPUnit, phpstan, PHP CS Fixer
docker compose exec -e APP_ENV=prod app symfony php vendor/bin/phpunit
docker compose exec -e APP_ENV=prod app symfony php vendor/bin/phpstan analyze
docker compose exec -e APP_ENV=prod app symfony php vendor/bin/php-cs-fixer check --verbose
docker compose exec -e APP_ENV=prod app symfony php vendor/bin/php-cs-fixer fix --verbose
```

## Going further

### SQLite

To setup SQLite, you'll need to modify `Dockerfile`:

```
RUN apk add --update --no-cache \
    ...
    sqlite \
    && docker-php-ext-install \
    ...
    pdo_sqlite
```

As well as `compose.yaml`:

```yaml
services:
    app:
        ...
        volumes:
            ...
            # Mount SQLite database directory to persist data
            - sqlite-data:/app/var/data

volumes:
    ...
    sqlite-data:
```

This is assuming your SQLite database file is located in the projects' `var/data` folder.

Make sure to set up the following environment varaible in `.env`:

```
DATABASE_URL="sqlite:///%kernel.project_dir%/var/data/database.sqlite"
```

### RabbitMQ

For RabbitMQ, modify `Dockerfile`:

```
RUN apk add --update --no-cache \
    ...
    rabbitmq-c-dev \
    && docker-php-ext-install \
    ...
    sockets \
    && pecl install amqp \
    && docker-php-ext-enable amqp
```

Also `compose.yaml`:

```yaml
services:
    app:
        ...
        depends_on:
            ...
            - rabbitmq

    rabbitmq:
        image: rabbitmq:${RABBITMQ_VERSION:-3.13}-management-alpine
        environment:
            RABBITMQ_DEFAULT_USER: ${RABBITMQ_USER:-app}
            RABBITMQ_DEFAULT_PASS: ${RABBITMQ_PASSWORD:-ChangeMe}
        # Persist RabbitMQ data between container restarts
        volumes:
            - rabbitmq-data:/var/lib/rabbitmq:rw
        ports:
            # Port mapping to avoid conflict with locally running RabbitMQ
            - "5673:5672"
            # Management UI port
            - "15673:15672"

volumes:
    ...
    rabbitmq-data:
```

Again, make sure to set up the following environment varaible in `.env`:

```
RABBITMQ_URL="amqp://app:ChangeMe@rabbitmq:5672/"
```

The RabbitMQ management interface will be available at http://localhost:15673,
with the credentials defined in the environment variables.

## Maintenance

Here's a list of helpful commands to maintain the images and containers:

* `docker images`: lists images
  * `docker images --filter dangling=true`: lists untagged / unused images
* `docker container ls`: lists running containers
  * `docker container ls -a`: lists running and stopped containers
* `docker system prune`: removes dangling containers, networks and images
  *  `docker system prune --volumes`: removes dangling containers, networks, volumes and images
* `docker history <image>`: Inspects layers of an image

## Conclusion

With this, we can finally write bugs once, and run them everywhere!
