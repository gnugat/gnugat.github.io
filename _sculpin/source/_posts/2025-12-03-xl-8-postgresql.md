---
layout: post
title: "eXtreme Legacy 8: From MySQL to PostgreSQL"
tags:
    - extreme-legacy
---

> 🤘 The Legacy Executioner casts MySQL into the void of deprecated technologies,
> summoning PostgreSQL from the northern lands
> to claim dominion over schemas with its superior type system and extension arsenal! 🔥

In this series, we're dealing with BisouLand, an eXtreme Legacy application
(2005 LAMP spaghetti code base). So far, we have:

1. [🐋 got it to run in a local container](/2025/09/10/xl-1-dockerizing-2005-lamp-app.html)
2. [💨 written Smoke Tests](/2025/09/17/xl-2-smoke-tests.html)
3. [🎯 written End to End Tests](/2025/09/24/xl-3-end-to-end-tests.html)
4. [🧹 created and applied Coding Standards](/2025/10/01/xl-4-coding-standards.html)
5. [⛃ migrated to PDO](/2025/10/22/xl-5-pdo.html)
6. [🐘 upgraded PHP 5 to PHP 8](/2025/11/19/xl-6-php-8.html)
6. [🏡 applied automated refactorings using Rector](/2025/11/26/xl-7-rector.html)

This means we can run it locally (http://localhost:43000/),
and have some level of automated tests.

But it's still using the **M** in LAMP: MySQL.

Let's migrate to PostgreSQL instead,
which provides native support for some interesting types
(BOOLEAN, UUID and JSONB):

* [Docker](#docker)
* [SQL Syntax](#sql-syntax)
* [Boolean](#boolean)
* [Timestamp](#timestamp)
* [UUID](#uuid)
* [Vanity Benchmark](#vanity-benchmark)
* [Database Reset](#database-reset)
* [Conclusion](#conclusion)

## Docker

Let's start by changing the `pdo_mysql` PHP extension to `pdo_pgsql` in `Dockerfile`:

```
# syntax=docker/dockerfile:1

###
# PHP Dev Container
# Utility Tools: Apache, PHP-FPM, bash, Composer
###
FROM php:8.5-fpm-alpine AS php_dev_container

# Composer environment variables:
# * default user is superuser (root), so allow them
# * put cache directory in a readable/writable location
# _Note_: When running `composer` in container, use `--no-cache` option
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_CACHE_DIR=/tmp/.composer/cache

# Install dependencies:
# * apache: for the webserver
# * bash: for shell access and scripting
# * postgresql: for PDO's SQL queries
# * libzip-dev: for composer packages that use ZIP archives
# _Note (Alpine)_: `--no-cache` includes `--update` and keeps image size minimal
#
# Then install PHP extensions
#
# _Note (Hadolint)_: No version locking, since Alpine only ever provides one version
# hadolint ignore=DL3018
RUN apk add --update --no-cache \
        apache2 \
        apache2-proxy \
        apache2-ssl \
        bash \
        libzip-dev \
        postgresql-dev \
    && sed -i 's/^#LoadModule rewrite_module/LoadModule rewrite_module/' /etc/apache2/httpd.conf \
    && docker-php-ext-install \
        pdo_pgsql

# Copy Composer binary from composer image
# _Note (Hadolint)_: False positive as `COPY` works with images too
# See: https://github.com/hadolint/hadolint/issues/197#issuecomment-1016595425
# hadolint ignore=DL3022
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /apps/monolith

# Caching `composer install`, as long as composer.{json,lock} don't change.
COPY composer.json composer.lock ./
RUN composer install \
    --no-cache \
    --no-interaction \
    --no-plugins \
    --no-scripts \
    --optimize-autoloader \
    && chmod -R o+rX vendor/

# Copy Apache configuration
COPY apache-site.conf /etc/apache2/conf.d/bisouland.conf

# Copy the remaining application files (excluding those listed in .dockerignore)
COPY . .

# Configure Apache proxy modules for PHP-FPM
RUN sed -i 's|^#LoadModule proxy_module|LoadModule proxy_module|' /etc/apache2/httpd.conf \
    && sed -i 's|^#LoadModule proxy_fcgi_module|LoadModule proxy_fcgi_module|' /etc/apache2/httpd.conf

# Create startup script to run both PHP-FPM and Apache
RUN echo '#!/bin/sh' > /start.sh \
    && echo 'php-fpm -D' >> /start.sh \
    && echo 'exec httpd -D FOREGROUND' >> /start.sh \
    && chmod +x /start.sh

EXPOSE 80

CMD ["/start.sh"]
```

Next, we change the image from `mysql` to `postgresql` in `compose.yaml`:

```yaml
name: bisouland-monolith

services:
  web:
    build: .
    ports:
      - "43000:80"
    volumes:
      - .:/apps/monolith
      - vendor:/apps/monolith/vendor
    depends_on:
      - db
    environment:
      DATABASE_HOST: ${DATABASE_HOST}
      DATABASE_PORT: ${DATABASE_PORT}
      DATABASE_USER: ${DATABASE_USER}
      DATABASE_PASSWORD: ${DATABASE_PASSWORD}
      DATABASE_NAME: ${DATABASE_NAME}
    restart: unless-stopped

  db:
    image: postgres:17
    platform: linux/amd64
    environment:
      POSTGRES_PASSWORD: ${DATABASE_PASSWORD}
      POSTGRES_DB: ${DATABASE_NAME}
      POSTGRES_USER: ${DATABASE_USER}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "127.0.0.1:43001:5432"
    restart: unless-stopped

volumes:
  postgres_data:
  vendor:
```

The `.env` file remains unchanged (we just remove the `MYSQL_ROOT_PASSWORD` envvar):

```bash
# Database
DATABASE_HOST=db
DATABASE_PORT=5432
DATABASE_USER=bisouland
DATABASE_PASSWORD=bisouland_pass
DATABASE_NAME=bisouland
```

## Different SQL

MySQL and PostgreSQL vary in their SQL types and syntax,
so a first pass needs to be done to convert the SQL queries,
following this table:

| PostgreSQL                           | MySQL                            |
|--------------------------------------|----------------------------------|
| **Data Types**                                                          |
| `SERIAL PRIMARY KEY`                 | `INT PRIMARY KEY AUTO_INCREMENT` |
| `INTEGER`                            | `INT`                            |
| `SMALLINT`                           | `TINYINT(1)`                     |
| **SQL Syntax**                                                          |
| `LIMIT 5 OFFSET 0`                   | `LIMIT 0, 5`                     |
| `ON CONFLICT (id) DO UPDATE`         | `ON DUPLICATE KEY UPDATE`        |
| `extract(epoch from now())::integer` | `UNIX_TIMESTAMP()`               |

For example in `evo.php`:

```diff
  // On passe à une nouvelle construction si disponible.
- $stmt = $pdo->prepare('SELECT id, duree, type, cout FROM liste WHERE auteur = :auteur AND classe = :classe ORDER BY id LIMIT 0,1');
+ $stmt = $pdo->prepare('SELECT id, duree, type, cout FROM liste WHERE auteur = :auteur AND classe = :classe ORDER BY id LIMIT 1 OFFSET 0');
  $stmt->execute(['auteur' => $id, 'classe' => $classeCancel]);
```

And in `schema.sql`:

```diff
  -- Messages table
  -- Field order MUST match INSERT statements in fctIndex.php::AdminMP()
  CREATE TABLE IF NOT EXISTS messages (
-     id INT PRIMARY KEY AUTO_INCREMENT,  -- Auto-increment
-     posteur INT NOT NULL,               -- Matches $source/$expediteur from INSERT
-     destin INT NOT NULL,                -- Matches $cible from INSERT
+     id SERIAL PRIMARY KEY,              -- Auto-increment
+     posteur INTEGER NOT NULL,           -- Matches $source/$expediteur from INSERT
+     destin INTEGER NOT NULL,            -- Matches $cible from INSERT
      message TEXT NOT NULL,              -- Matches $message from INSERT
-     timestamp INT NOT NULL,             -- Matches $timer/time() from INSERT
-     statut TINYINT(1) DEFAULT 0,        -- Matches '0'/$lu from INSERT
+     timestamp INTEGER NOT NULL,         -- Matches $timer/time() from INSERT
+     statut SMALLINT DEFAULT 0,          -- Matches '0'/$lu from INSERT
      titre VARCHAR(100) NOT NULL         -- Matches $titre/$objet from INSERT
  );
```

But PostgreSQL is much more interesting than that.

## Boolean

Some of the MySQL `TINYINT` actually were boolean, and as it turns out,
PostgreSQL does have a `BOOLEAN` type:

```diff
  -- Messages table
  -- Field order MUST match INSERT statements in fctIndex.php::AdminMP()
  CREATE TABLE IF NOT EXISTS messages (
      id SERIAL PRIMARY KEY,              -- Auto-increment
      posteur INTEGER NOT NULL,           -- Matches $source/$expediteur from INSERT
      destin INTEGER NOT NULL,            -- Matches $cible from INSERT
      message TEXT NOT NULL,              -- Matches $message from INSERT
      timestamp INTEGER NOT NULL,         -- Matches $timer/time() from INSERT
-     statut SMALLINT DEFAULT 0,          -- Matches '0'/$lu from INSERT
+     statut BOOLEAN DEFAULT FALSE,       -- (FALSE=unread, TRUE=read)
      titre VARCHAR(100) NOT NULL         -- Matches $titre/$objet from INSERT
  );
```

Which means we get a PHP `bool` upon selecting these:

```diff
- <td><?php if (0 == $donnees['statut']) {
+ <td><?php if (false === $donnees['statut']) {
      echo '<a class="bulle" style="cursor: default;" onclick="return false;" href=""><img src="images/newmess.png" alt="Message non lu" title="" /><span>Message >
  }?></td>
```

But there is a catch:
when constructing a query, PDO will not convert PHP bool to PostgreSQL BOOLEAN!

We have to do the PHP bool to PHP string conversion ourselves:

```php
<?php

namespace Bl\Infrastructure\Pg;

class CastToPgBoolean
{
    /**
     * PostgreSQL's BOOLEAN fields are strings with for values:
     * - `true`, `t`, `TRUE`
     * - `false`, `f`, `FALSE`
     */
    public function from(bool $value): string
    {
        return $value ? 'TRUE' : 'FALSE';
    }
}
```

And do that before calling PDO:

```diff
  $stmt = $pdo->prepare(
      'INSERT INTO membres (pseudo, mdp, confirmation, timestamp, lastconnect, amour)'
      .' VALUES (:pseudo, :mdp, :confirmation, :timestamp, :lastconnect, :amour)',
  );
- $stmt->execute(['pseudo' => $pseudo, 'mdp' => $hmdp, 'confirmation' => 1, 'timestamp' => time(), 'lastconnect' => time(), 'amour' => 300]);
+ $stmt->execute(['pseudo' => $pseudo, 'mdp' => $hmdp, 'confirmation' => $castToPgBoolean->from(true), 'amour' => 300]);
```

If we are not binding parameters, but instead using plain SQL queries, then we can use `TRUE` and `FALSE` as follow:

```diff
  // On supprime les unités.
- $stmt = $pdo->prepare('UPDATE membres SET smack = :smack, baiser = :baiser, pelle = :pelle, bloque = 0 WHERE id = :id');
+ $stmt = $pdo->prepare('UPDATE membres SET smack = :smack, baiser = :baiser, pelle = :pelle, bloque = FALSE WHERE id = :id');
  $stmt->execute(['smack' => $AttSmack, 'baiser' => $AttBaiser, 'pelle' => $AttPelle, 'id' => $idAuteur]);
```

## Timestamp

In BisouLand, time and intervals are an essential component of the game:
when blowing a kiss, these kisses will take some time to travel to the target,
and then as much time to come back.

In 2005 eXtreme Legacy fashion, time was handled as a UNIX timestamp,
the number of seconds since January the 1st 1970.

Since PostgreSQL has a `TIMESTAMPTZ`, which is an actual ISO 8601 date string,
with timezone information, we can take the opportunity to modernise the code:

```diff
  -- Attack log table
  -- Logs completed attacks for rate limiting, INSERT in attaque.php:16, checked in action.php:74
  CREATE TABLE IF NOT EXISTS logatt (
      id SERIAL PRIMARY KEY,              -- Log entry ID
      auteur INTEGER NOT NULL,            -- Attacker user ID, checked for rate limiting
      cible INTEGER NOT NULL,             -- Target user ID
-     timestamp INTEGER NOT NULL          -- Attack completion time, used for 12-hour limit check
+     timestamp TIMESTAMPTZ NOT NULL      -- Attack completion time, used for 12-hour limit check
  );
```

We take the opportunity to use PostgreSQL `CURRENT_TIMESTAMP` function when possible,
and even do INTERVAL calculations:

```diff
- $stmt = $pdo->prepare('SELECT COUNT(*) AS nb_att FROM logatt WHERE auteur = :auteur AND cible = :cible AND timestamp >= :timestamp');
- $stmt->execute(['auteur' => $id, 'cible' => $cible, 'timestamp' => time() - 43200]);
+ $stmt = $pdo->prepare("SELECT COUNT(*) AS nb_att FROM logatt WHERE auteur = :auteur AND cible = :cible AND timestamp >= CURRENT_TIMESTAMP - INTERVAL '12 hours'");
+ $stmt->execute(['auteur' => $id, 'cible' => $cible]);
```

I gotta admit, I'm not ready yet to convert all the UNIX timestamp in the code to `DateTime` objects,
so we'll have to convert them from PHP int to PHP string in ISO 8601 format:

```php
<?php

namespace Bl\Infrastructure\Pg;

class CastToPgTimestamptz
{
    /**
     * PostgreSQL's TIMESTAMPTZ fields are strings in (sort of) ISO 8601 date format:
     * - '2025-11-20T16:45:03.336548+00:00' (fully ISO 8601 compliant)
     * - '2025-11-20 16:45:03+00'
     * - '2025-11-20 16:45:03+00:00'
     * - '2025-11-20 16:45:03.336548+00'
     * - '2025-11-20 16:45:03.336548+00:00'
     */
    public function fromUnixTimestamp(int $unixTimestamp): string
    {
        return new \DateTimeImmutable("@{$unixTimestamp}")->format('Y-m-d\TH:i:s.uP');
    }
}
```

And:

```php
<?php

namespace Bl\Infrastructure\Pg;

class CastToUnixTimestamp
{
    /**
     * PostgreSQL's TIMESTAMPTZ fields are strings in (sort of) ISO 8601 date format:
     * - '2025-11-20T16:45:03.336548+00:00' (fully ISO 8601 compliant)
     * - '2025-11-20 16:45:03+00'
     * - '2025-11-20 16:45:03+00:00'
     * - '2025-11-20 16:45:03.336548+00'
     * - '2025-11-20 16:45:03.336548+00:00'
     */
    public function fromPgTimestamptz(string $timestamptz): int
    {
        return new \DateTimeImmutable($timestamptz)->getTimestamp();
    }
}
```

So when interracting with PDO, we do:

```diff
- $stmt = $pdo->prepare('INSERT INTO attaque VALUES (:auteur, :cible, :finaller, :finretour, 0)');
- $stmt->execute(['auteur' => $id, 'cible' => $cible, 'finaller' => time() + $duree, 'finretour' => time() + 2 * $duree]);
+ $stmt = $pdo->prepare('INSERT INTO attaque (auteur, cible, finaller, finretour, etat) VALUES (:auteur, :cible, :finaller, :finretour, 0)');
+ $stmt->execute(['auteur' => $id, 'cible' => $cible, 'finaller' => $castToPgTimestamptz->fromUnixTimestamp(time() + $duree), 'finretour' => $castToPgTimestamptz->fromUnixTimestamp(time() + 2 * $duree)]);
```

## UUID

I love UUIDs. Don't ask me why, I just do.

So it made total sense for me to add something I loved in the love game that is BisouLand:

```diff
  -- Evolution/construction queue
  -- Active construction tasks, INSERT in index.php:427, SELECT/DELETE in index.php:392-409
  CREATE TABLE IF NOT EXISTS evolution (
-     id SERIAL PRIMARY KEY,              -- Task ID for deletion when complete
+     id UUID PRIMARY KEY,                -- Task ID (UUIDv7) for deletion when complete
      timestamp TIMESTAMPTZ NOT NULL,     -- Completion time, checked against time() in index.php:392
      classe INTEGER NOT NULL,            -- Object class/category for construction
      type INTEGER NOT NULL,              -- Specific object type within class
-     auteur INTEGER NOT NULL,            -- User ID who initiated construction, from $id2
+     auteur UUID NOT NULL,               -- User ID (foreign key to membres.id) who initiated construction
      cout BIGINT NOT NULL                -- Cost of the construction task
  );
```

I've been using UUID v4 for a while, which are random generated,
but there's a new kid in town: v7, which is still random,
but storable by their creation time as the first 48 bits are a UNIX Epoch timestamp.

Of course, I want the client to generate the UUID, not the database,
and this can be done thanks to the [Symfony Uid component](https://symfony.com/doc/current/components/uid.html):

```diff
+ use Symfony\Uid\Uuid;

  // On indique que l'attaque a eu lieu.
- $stmt = $pdo->prepare('INSERT INTO logatt VALUES(:auteur, :cible, :timestamp)');
- $stmt->execute(['auteur' => $idAuteur, 'cible' => $idCible, 'timestamp' => $finaller]);
+ $stmt = $pdo->prepare('INSERT INTO logatt (id, auteur, cible, timestamp) VALUES(:id, :auteur, :cible, :timestamp)');
+ $stmt->execute(['id' => Uuid::v7(), 'auteur' => $idAuteur, 'cible' => $idCible, 'timestamp' => $finaller]);
```

Oh but hang on, how did we get a Symfony 8 feature in a 2005 LAMP app you ask?

Well it required some tricks, such as renaming `index.php` to `app.php`,
and in `index.php` create the following front controller:

```php
<?php

declare(strict_types=1);

require __DIR__.'/../vendor/autoload.php';

try {
    require __DIR__.'/../phpincludes/app.php';
} catch (Throwable $throwable) {
    http_response_code(500);
    error_log($throwable->getMessage());
    echo 'An error occurred';
}
```

With that, we can now use composer to get third party libraries, see the `composer.json`:

```json
{
    "name": "bl/monolith",
    "description": "The original BisouLand codebase",
    "type": "project",
    "license": "Apache-2.0",
    "require": {
        "php": ">=8.5",
        "ext-curl": "*",
        "symfony/uid": "^8.0@rc"
    },
    "autoload": {
        "psr-4": {
            "Bl\\": "src/"
        },
        "files": [
            "phpincludes/bd.php",
            "phpincludes/cast_to_pg_boolean.php",
            "phpincludes/cast_to_unix_timestamp.php",
            "phpincludes/cast_to_pg_timestamptz.php",
            "phpincludes/fctIndex.php"
        ]
    },
    "config": {
        "bump-after-update": true,
        "sort-packages": true
    }
}
```

## Vanity Benchmark

Surely, switching from MySQL to PostgreSQL will bring us massive performance boosts, right? Right??

Let's find out with some vanity benchmarks:

```bash
# Start fresh
cd apps/monolith
make app-init

BENCH_USER="BisouTest_bench"
BENCH_PASS="SuperSecret123"

# Sign up
curl -X POST 'http://localhost:43000/inscription.html' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "Ipseudo=${BENCH_USER}&Imdp=${BENCH_PASS}&Imdp2=${BENCH_PASS}&inscription=S%27inscrire"

# Log in
BENCH_COOKIE=$(curl -X POST 'http://localhost:43000/redirect.php' \
  -H 'Content-Type: application/x-www-form-urlencoded' \
  -d "pseudo=${BENCH_USER}&mdp=${BENCH_PASS}&connexion=Se+connecter" \
  -i -s | grep -i 'set-cookie: PHPSESSID' | sed 's/.*PHPSESSID=\([^;]*\).*/\1/' | tr -d '\r')

# Test load homepage (not signed in)
ab -l -q -k -c 50 -n 10000 http://localhost:43000/ \
    | grep -E "Complete requests|Failed requests|Exception|Requests per second|Time per request.*across"

# Test load Brain page (signed in)
ab -l -q -k -c 50 -n 10000 -C "PHPSESSID=$BENCH_COOKIE" http://localhost:43000/cerveau.html \
    | grep -E "Complete requests|Failed requests|Exception|Requests per second|Time per request.*across"
```

We execute this before the migration (I've kindly upgraded to MySQL 8),
and after the migration to PostgreSQL.

On my MacBook M4 (with Docker), the results are as follow:

* Homepage (Visitor - Not Logged In):
    * Requests per second (mean): from `1503` to `100`
    * Time per request (ms, mean, across all concurrent requests): from `0.665` to `9.943`
* Brain Page (Logged In User):
    * Requests per second (mean): from `1133` to `96`
    * Time per request (ms, mean, across all concurrent requests): from `0.883` to `10.348`

**🚨 Performance degradation: 90% slower than MySQL 🙀**

How is that possible?? My core beliefs are now completly shattered!!!!111oneoneeleven

Unless... Unless we've missed one important configuration step:

```php
<?php

function bd_connect()
{
    static $pdo = null;

    if (null === $pdo) {
        $dsn = 'pgsql:host='.DATABASE_HOST.';port='.DATABASE_PORT.';dbname='.DATABASE_NAME;
        $options = [
            PDO::ATTR_ERRMODE => PDO::ERRMODE_EXCEPTION,
            PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
            PDO::ATTR_EMULATE_PREPARES => false,
            // Don't forget to set persistent connections!
            PDO::ATTR_PERSISTENT => true,
        ];
        $pdo = new PDO($dsn, DATABASE_USER, DATABASE_PASSWORD, $options);
    }

    return $pdo;
}
```

And indeed, we had forgotten to enable persistent connections.

As it turns out, the overhead of setting a new connection with PostgreSQL is quite consequential.

Let's re-run our tests (we make sure MySQL also gets persistent connection):

* Homepage (Visitor - Not Logged In):
    * Requests per second (mean): from `1683.86` to `1905.43`
    * Time per request (ms, mean, across all concurrent requests): from `0.594` to `0.525`
* Brain Page (Logged In User):
    * Requests per second (mean): from `1309.55` to `1828.19`
    * Time per request (ms, mean, across all concurrent requests): from `0.764` to `0.547`

Phew, my mid-life crisis is postponed 😌. PostgreSQL **is** after all faster than MySQL:

* Homepage: +13.1% improvement
* Brain Page: +39.6% improvement

It's great to see that now on the logged in pages,
we get the same speed as on on the not logged in ones.

## Database Reset

With the persistent connection, it's going to be harder to drop the database,
to recreate it. We'll need to first terminate active connections.

Once the database has been dropped, created and the schema loaded,
we also need to restart PostgreSQL to clear the connection pool:

```bash
#!/usr/bin/env bash
# File: /apps/monolith/bin/db-reset.sh
# ──────────────────────────────────────────────────────────────────────────────
# Database reset:
# * drops the database
# * then recreates it
# * and finally loads the schema
#
# Intended for development and testing purposes.
# ──────────────────────────────────────────────────────────────────────────────

_BIN_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")"
_ROOT_DIR="$(realpath "${_BIN_DIR}/..")"
cd "${_ROOT_DIR}"

# ──────────────────────────────────────────────────────────────────────────────
# Loading database config through environment variables.
# `set -a` enables exportation of env vars, while `set +a` disables it.
# Passing PostgreSQL password via command line arguments is insecure,
# so using `PGPASSWORD` instead.
# ──────────────────────────────────────────────────────────────────────────────
set -a; source .env; set +a

export PGPASSWORD="${DATABASE_PASSWORD}"

# ──────────────────────────────────────────────────────────────────────────────
# Reset the database, through Docker containers.
# ──────────────────────────────────────────────────────────────────────────────
echo '  // 🔌 Terminating active connections...'
echo ''
docker compose exec -e PGPASSWORD db psql \
    -U ${DATABASE_USER} \
    -d postgres \
    -c "SELECT pg_terminate_backend(pid) FROM pg_stat_activity WHERE datname = '${DATABASE_NAME}' AND pid <> pg_backend_pid();" \
    > /dev/null 2>&1

echo '  // 🗑️ Dropping database...'
echo ''
docker compose exec -e PGPASSWORD db psql \
    -U ${DATABASE_USER} \
    -d postgres \
    -c "DROP DATABASE IF EXISTS ${DATABASE_NAME};" \
    > /dev/null 2>&1

echo '  // 🆕 Creating database...'
echo ''
docker compose exec -e PGPASSWORD db psql \
    -U ${DATABASE_USER} \
    -d postgres \
    -c "CREATE DATABASE ${DATABASE_NAME};" \
    > /dev/null 2>&1

echo '  // 📋 Loading schema.sql...'
echo ''
docker compose exec -T -e PGPASSWORD db psql \
    -U ${DATABASE_USER} \
    -d ${DATABASE_NAME} \
    > /dev/null 2>&1 \
    < schema.sql

echo '  // 🔄 Restarting web container to clear connection pool...'
echo ''
docker compose restart web > /dev/null 2>&1

echo '  [OK] Database reset'
```

## Conclusion

There are actually some other types I've taken advantage of,
like INET and ENUM. But there's not much to say about those apart from
"look, I've replaced `attaque.etat SMALLINT (0,1,2)` with
`attack_state ENUM ('going_to_target', 'coming_back', 'cancelled')`":

```diff
+ -- Blown kiss state ENUM type
+ CREATE TYPE blown_kiss_state AS ENUM ('EnRoute', 'ComingBack', 'CalledOff');
  
  -- Attack table
  -- Active attacks in progress, managed throughout attaque.php and action.php
  CREATE TABLE IF NOT EXISTS attaque (
      auteur UUID NOT NULL,               -- Attacker user ID (foreign key to membres.id), set bloque=1 during attack
      cible UUID NOT NULL,                -- Target user ID (foreign key to membres.id)
      finaller TIMESTAMPTZ NOT NULL,      -- Attack arrival timestamp (when units reach target)
      finretour TIMESTAMPTZ NOT NULL,     -- Return timestamp (when units return home)
-     etat SMALLINT NOT NULL DEFAULT 0,   -- Attack state: 0=going_to_target, 1=coming_back, 2=cancelled
+     state blown_kiss_state NOT NULL DEFAULT 'EnRoute',  -- Blown kiss state ENUM
      butin BIGINT DEFAULT 0              -- Loot gained from attack, set after battle
  );
```

I've taken the ENUM opportunity to also introduce a PHP enum:

```php
<?php

declare(strict_types=1);

namespace Bl\Domain\KissBlowing;

/**
 * Blown kiss state enum matching PostgreSQL blown_kiss_state type.
 *
 * Represents the three possible states of a blown kiss mission:
 * - EnRoute: Kiss units are traveling to the target
 * - ComingBack: Mission completed, units returning with loot
 * - CalledOff: Mission was cancelled by the player
 */
enum BlownKissState: string
{
    case EnRoute = 'EnRoute';
    case ComingBack = 'ComingBack';
    case CalledOff = 'CalledOff';
}
```

Which made some conditions easier to understand:

```diff
  // // On récupère les infos sur le joueur que l'on attaque.
- $stmt = $pdo->prepare('SELECT cible, finaller, finretour, butin, etat FROM attaque WHERE auteur = :auteur');
+ $stmt = $pdo->prepare('SELECT cible, finaller, finretour, butin, state FROM attaque WHERE auteur = :auteur');
  $stmt->execute(['auteur' => $id]);
  
  if ($donnees_info = $stmt->fetch()) {
      $stmt2 = $pdo->prepare('SELECT pseudo, nuage, position FROM membres WHERE id = :id');
      $stmt2->execute(['id' => $donnees_info['cible']]);
      $donnees_info2 = $stmt2->fetch();
      $pseudoCible = $donnees_info2['pseudo'];
      $nuageCible = $donnees_info2['nuage'];
      $positionCible = $donnees_info2['position'];
      $finAll = $castToUnixTimestamp->fromPgTimestamptz($donnees_info['finaller']);
      $finRet = $castToUnixTimestamp->fromPgTimestamptz($donnees_info['finretour']);
      $butinPris = $donnees_info['butin'];
-     $etat = $donnees_info['etat'];
+     $state = BlownKissState::from($donnees_info['state']);
  
-     if (isset($_POST['cancelAttaque']) && 0 === $etat) {  
+     if (isset($_POST['cancelAttaque']) && BlownKissState::EnRoute === $state) {
          $finRet = (2 * time() + $finRet - 2 * $finAll);
          $stmt3 = $pdo->prepare("UPDATE attaque SET state = 'CalledOff', finretour = :finretour WHERE auteur = :auteur");
          $stmt3->execute(['finretour' => $castToPgTimestamptz->fromUnixTimestamp($finRet), 'auteur' => $id]);
          AdminMP($donnees_info['cible'], 'Attaque annulée', "{$pseudo} a annulé son attaque.
                          Tu n'es plus en danger.");
-         $etat = 2; // Update local variable to reflect the change
+         $state = BlownKissState::CalledOff; // Update local variable to reflect the change
      }

-     if (0 === $etat) {  
+     if (BlownKissState::EnRoute === $state) {
  ?>
  Tu vas tenter d'embrasser <strong><?php echo $pseudoCible; ?></strong> sur le nuage <strong><?php echo $nuageCible; ?></strong>
```

So yeah. There it is.

The eXtreme Legacy (2005 LAMP) app is now migrated from MySQL to PostgreSQL.

It takes advantages of the native PostgreSQL types, such as BOOLEAN, ENUM, INET,
TIMESTAMPTZ and UUID, as well as getting a 13% performance boost in the process.

I guess it's time to stop calling it a LAMP app (how about a LAPP app?).

> ⁉️ What do you mean, "there's a big security vulnerability"?
