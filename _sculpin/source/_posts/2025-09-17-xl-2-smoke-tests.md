---
layout: post
title: "eXtreme Legacy 2: Smoke Tests"
tags:
    - phpunit
    - extreme-legacy
---

> 🤘 The Quality Avenger emerges from the burning forges of Coding Standards,
> smelting the ores of Static Analysis into the moulds of Automated Testing. 🔥

In this series, we're dealing with BisouLand, an eXtreme Legacy application
(2005 LAMP spaghetti code base). So far, we have:

1. [🐋 got it to run in a local container](/2025/09/10/xl-1-dockerizing-2005-lamp-app.html)

This means we can access it (http://localhost:8080/) and manually check it.
Unfortunately looking at the [code](https://github.com/pyricau/bisouland/tree/4.0.1),
it's obvious we cannot launch it to production as is:

* Encoding Issues
* Broken Authentication and Session Management
* Cross-Site Scripting (XSS) Flaws
* Injection Flaws, including SQL injection
* Improper Error Handling
* Non Compliance with GDPR requirements

But how do we know we're not breaking anything when fixing these?
As things currently stand, we don't even know what features BisouLand has.

So, we're going to need to write tests, which will be today's second article focus.

* [QA app](#qa-app)
* [Smoke Tests](#smoke-tests)
* [Custom Assurance](#custom-assertions)
* [Scenarios](#scenarios)
* [Conclusion](#conclusion)

## QA app

The first plan of action is to move the current app into the `./apps/monolith`
sub-folder, and to create a new QA one in `./apps/qa`.

This approach will allow us to isolate the legacy code from any tooling we might
need to bring it up to standards.

The QA application has the following tree directory:

```
apps/qa/
├── composer.json
├── composer.lock
├── compose.yaml
├── Dockerfile
├── Makefile
├── phpstan-baseline.neon
├── phpstan.neon.dist
├── phpunit.xml.dist
├── README.md
└── tests/
```

As you can see, it has its own `Dockerfile`:

```
# syntax=docker/dockerfile:1

###
# PHP Dev Container
# Utility Tools: PHP, bash, Composer
###
FROM php:8.4-cli-alpine AS php_dev_container

# Composer environment variables:
# * default user is superuser (root), so allow them
# * put cache directory in a readable/writable location
# _Note_: When running `composer` in container, use `--no-cache` option
ENV COMPOSER_ALLOW_SUPERUSER=1 \
    COMPOSER_CACHE_DIR=/tmp/.composer/cache

# Install dependencies:
# * bash for shell access and scripting
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
        zip \
    && docker-php-ext-install \
        bcmath \
        pdo \
        pdo_mysql \
        zip

# Copy Composer binary from composer image
# _Note (Hadolint)_: False positive as `COPY` works with images too
# See: https://github.com/hadolint/hadolint/issues/197#issuecomment-1016595425
# hadolint ignore=DL3022
COPY --from=composer:2 /usr/bin/composer /usr/bin/composer

WORKDIR /apps/qa

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

And `compose.yaml`:

```yaml
name: skyswoon-qa

services:
  app:
    build: .
    command: php -S 0.0.0.0:8081
    volumes:
      # Mount current directory into container for QA tools and configs
      - .:/apps/qa
      # Mount the monolith source code for analysis
      - ../monolith:/apps/monolith
    networks:
      - default
      - skyswoon-monolith_default

networks:
  skyswoon-monolith_default:
    external: true
```

This allows us to have QA in its own container (with PHP 8.4),
but it can still communicate with the monolith container,
so we can issue curl requets or query the MySQL database.

It also allows access to the monolith source files,
so we can run toolings on them like phpstan, rector, PHP CS Fixer, etc.

## Smoke Tests

There are two kinds of tests that I hate
(this is coming from a Test Driven Development practitioner, btw!)
and one of them is Smoke Tests.

Those basically issue a curl request,
and only check the bare minimum such as the status code is `200`.

I don't like these because they are slow (remote requests),
unreliable (errors like form validation, page not found, etc will still return `200`),
and overall don't provide much value at all.

However in this specific case I still think Smoke Tests can help us,
notably to make a list of what pages the website has,
and also differentiate the ones that are public,
and the ones that should only be accessed by logged in players.

This will be valuable knowledge,
and once we have better test coverage **we can get rid of those**.

After manually navigating the website, checking the `pages.php` file,
and overall getting familiar with the app,
I've documented my findings in a data provider in the following Smoke Test,
which checks if all private pages are accessible to logged in players,
but not for logged out visitors:

```php
<?php

declare(strict_types=1);

namespace Bl\Qa\Tests\Smoke;

use Bl\Qa\Tests\Infrastructure\Scenario\GetLoggedInPlayer;
use Bl\Qa\Tests\Infrastructure\TestKernelSingleton;
use Bl\Qa\Tests\Smoke\Assertion\Assert;
use PHPUnit\Framework\Attributes\CoversNothing;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Large;
use PHPUnit\Framework\Attributes\TestDox;
use PHPUnit\Framework\TestCase;

#[CoversNothing]
#[Large]
final class PlayerPagesTest extends TestCase
{
    #[TestDox('it blocks $pageName page (`$url`) for visitors')]
    #[DataProvider('playerPagesProvider')]
    public function test_it_blocks_player_page_for_visitors(string $url, string $pageName): void
    {
        $httpClient = TestKernelSingleton::get()->httpClient();

        $response = $httpClient->request('GET', $url);

        Assert::blocksPageForLoggedOutVisitors($response);
    }

    #[TestDox('it loads $pageName page (`$url`) for logged in players')]
    #[DataProvider('playerPagesProvider')]
    public function test_it_loads_player_page_for_logged_in_players(string $url, string $pageName): void
    {
        $httpClient = TestKernelSingleton::get()->httpClient();

        $loggedInPlayer = GetLoggedInPlayer::run();

        $response = $httpClient->request('GET', $url, [
            'headers' => [
                'Cookie' => $loggedInPlayer->sessionCookie,
            ],
        ]);

        Assert::loadsPageForLoggedInPlayers($response);
    }

    /**
     * @return array<array{string, string}>
     */
    public static function playerPagesProvider(): array
    {
        return [
            ['/connected.html', 'account'],
            ['/action.html', 'blow kisses'],
            ['/cerveau.html', 'brain'],
            ['/changepass.html', 'change password'],
            ['/nuage.html', 'clouds'],
            ['/yeux.html', 'eyes'],
            ['/boite.html', 'inbox'],
            ['/bisous.html', 'kisses'],
            ['/construction.html', 'organs'],
            ['/infos.html', 'reference'],
            ['/techno.html', 'techniques'],
            ['/lire.html', 'view message'],
        ];
    }
}
```

Running this test _should_ output the following:

```console
> make test arg='--testdox --filter PlayerPages'
PHPUnit 12.3.2 by Sebastian Bergmann and contributors.

Runtime:       PHP 8.4.11
Configuration: /apps/qa/phpunit.xml.dist

........................                                          24 / 24 (100%)

Time: 00:00.606, Memory: 18.00 MB

Player Pages (Bl\Qa\Tests\Smoke\PlayerPages)
 ✔ it blocks organs page (`/construction.html`) for visitors
 ✔ it blocks account page (`/connected.html`) for visitors
 ✔ it blocks reference page (`/infos.html`) for visitors
 ✔ it blocks kisses page (`/bisous.html`) for visitors
 ✔ it blocks brain page (`/cerveau.html`) for visitors
 ✔ it blocks change·password page (`/changepass.html`) for visitors
 ✔ it blocks eyes page (`/yeux.html`) for visitors
 ✔ it blocks view·message page (`/lire.html`) for visitors
 ✔ it blocks clouds page (`/nuage.html`) for visitors
 ✔ it blocks inbox page (`/boite.html`) for visitors
 ✔ it blocks techniques page (`/techno.html`) for visitors
 ✔ it blocks blow·kisses page (`/action.html`) for visitors
 ✔ it loads view·message page (`/lire.html`) for logged in players
 ✔ it loads eyes page (`/yeux.html`) for logged in players
 ✔ it loads brain page (`/cerveau.html`) for logged in players
 ✔ it loads change·password page (`/changepass.html`) for logged in players
 ✔ it loads techniques page (`/techno.html`) for logged in players
 ✔ it loads account page (`/connected.html`) for logged in players
 ✔ it loads reference page (`/infos.html`) for logged in players
 ✔ it loads inbox page (`/boite.html`) for logged in players
 ✔ it loads kisses page (`/bisous.html`) for logged in players
 ✔ it loads organs page (`/construction.html`) for logged in players
 ✔ it loads clouds page (`/nuage.html`) for logged in players
 ✔ it loads blow·kisses page (`/action.html`) for logged in players

OK (24 tests, 24 assertions)
```

> _🔗 Check_: [PHPUnit Best Practices](/2025/07/31/phpunit-best-practices.html)

The test is structured as follow:

1. get an instance of HttpClient through TestKernelSingleton
2. optionally run some setup scenario such as `SignUpNewPlayer`, `LogInPlayer`, etc
3. send the remote request, and get the HTTP response
4. check that the HTTP Response satisfies our expectations

## Custom Assertions

To be able to see if a page is blocked for a non logged in visitor,
we cannot just rely on the HTTP Status (it will always be 200),
so we have to instead check for error messages contained in the page.

Through my search, I've discovered that various messages get displayed when a
logged out visitor tries to access a private page,
I've documented this in the following custom assertion:

```php
<?php

declare(strict_types=1);

namespace Bl\Qa\Tests\Smoke\Assertion;

use PHPUnit\Framework\Assert as PHPUnitAssert;
use Symfony\Contracts\HttpClient\ResponseInterface;

final readonly class Assert
{
    private const array NOT_LOGGED_IN_MESSAGES = [
        // Warning: side bar contains `Tu n'es pas connect&eacute;.`
        'standard' => 'es pas connecté !!',
        'variant 1 (inbox)' => 'es pas connect&eacute; !!',
        'variant 2 (kisses, organs, techniques, account)' => 'Veuillez vous connecter.',
        'variant 3 (reference)' => 'Erreur... et vouaip !! :D',
    ];

    public static function blocksPageForLoggedOutVisitors(ResponseInterface $response): void
    {
        $content = (string) $response->getContent();

        foreach (self::NOT_LOGGED_IN_MESSAGES as $message) {
            if (str_contains($content, $message)) {
                PHPUnitAssert::assertSame(200, $response->getStatusCode(), $content);

                return;
            }
        }

        PHPUnitAssert::fail('Failed asserting that Page is blocked for logged out visitors');
    }

    public static function loadsPageForLoggedInPlayers(ResponseInterface $response): void
    {
        $content = (string) $response->getContent();

        foreach (self::NOT_LOGGED_IN_MESSAGES as $message) {
            if (str_contains($content, $message)) {
                PHPUnitAssert::fail('Failed asserting that Page loads for logged in players');
            }
        }

        PHPUnitAssert::assertSame(200, $response->getStatusCode(), $content);
    }
}
```

## Scenarios

For some of our tests, we need to have a visitor to first sign up as a player,
which I've done through the following "Scenario" class:

```php
<?php

declare(strict_types=1);

namespace Bl\Qa\Tests\Infrastructure\Scenario;

use Bl\Qa\Tests\Infrastructure\TestKernelSingleton;

final readonly class SignUpNewPlayer
{
    public static function run(
        string $username = 'BisouTest',
        string $password = 'password',
        string $passwordConfirmation = 'password',
    ): Player {
        $httpClient = TestKernelSingleton::get()->httpClient();

        if ('BisouTest' === $username) {
            $username = substr('BisouTest_'.uniqid(), 0, 15);
        }

        $httpClient->request('POST', '/inscription.html', [
            'body' => [
                'Ipseudo' => $username,
                'Imdp' => $password,
                'Imdp2' => $passwordConfirmation,
                'inscription' => "S'inscrire",
            ],
            'headers' => [
                'Content-Type' => 'application/x-www-form-urlencoded',
            ],
        ]);

        return new Player($username, $password);
    }
}
```

Here we do an HTTP request that will simulate posting the HTML form,
alternatives for this would have been doing a SQL query to directly
create the player in the database, but we risk missing other insertions
that might be required.

The advantage of the current approach is that it also smoke tests the signup form.

We also need the player to be logged in:

```php
<?php

declare(strict_types=1);

namespace Bl\Qa\Tests\Infrastructure\Scenario;

use Bl\Qa\Tests\Infrastructure\TestKernelSingleton;
use Symfony\Component\HttpClient\Exception\RedirectionException;

final readonly class LogInPlayer
{
    public static function run(Player $player): string
    {
        $httpClient = TestKernelSingleton::get()->httpClient();

        try {
            $response = $httpClient->request('POST', '/redirect.php', [
                'body' => [
                    'pseudo' => $player->username,
                    'mdp' => $player->password,
                    'connexion' => 'Se connecter',
                ],
                'headers' => [
                    'Content-Type' => 'application/x-www-form-urlencoded',
                ],
                'max_redirects' => 0,
            ]);
        } catch (RedirectionException $e) { // @phpstan-ignore catch.neverThrown
            // With max_redirects=0, HttpClient throws an exception when we get a 302
            // This is expected on successful login
            $response = $e->getResponse();
        }

        $headers = $response->getHeaders(false);
        $cookies = $headers['set-cookie'] ?? $headers['Set-Cookie'] ?? [];
        foreach ($cookies as $cookie) {
            if (str_starts_with($cookie, 'PHPSESSID=')) {
                return $cookie;
            }
        }

        $content = $response->getContent(false);
        $allCookies = implode(', ', $cookies);

        throw new \RuntimeException("Login failed: PHPSESSID cookie not found. Cookies: [{$allCookies}], Content: {$content}");
    }
}
```

Similarly to the `SignUpNewPlayer` scenario,
`LogInPlayer` posts a HTTP request that simulates the log in form.

To be abe to then act as the logged in player, we need their Session Cookie string,
so we make sure to return it.

Finally the `GetLoggedInPlayer` scenario will sign up and login a player once,
and always return it to save us some overhead in the test suite:

```php
<?php

declare(strict_types=1);

namespace Bl\Qa\Tests\Infrastructure\Scenario;

final class GetLoggedInPlayer
{
    private static ?LoggedInPlayer $loggedInPlayer = null;

    public static function run(): LoggedInPlayer
    {
        if (null === self::$loggedInPlayer) {
            $player = SignUpNewPlayer::run();
            $sessionCookie = LogInPlayer::run($player);

            self::$loggedInPlayer = new LoggedInPlayer($player->username, $player->password, $sessionCookie);
        }

        return self::$loggedInPlayer;
    }
}
```

These scenarios will come in handy when we start writing other kinds of tests.

## Conclusion

> 💻 **Source code**:
>
> * [Before our changes](https://github.com/pyricau/bisouland/tree/4.0.5)
> * [After Smoke Tests](https://github.com/pyricau/bisouland/tree/4.0.6)

Now we can type:

```console
make test arg='--testdox --filter PlayerPages'
```

And get the list of all public and private pages.

> ⁉️ _What do you mean,"tests are failing"??_
