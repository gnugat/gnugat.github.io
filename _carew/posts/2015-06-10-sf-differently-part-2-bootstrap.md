---
layout: post
title: Symfony Differently - part 2: Bootstrap
tags:
    - Symfony
    - Symfony Differently
---

This is the second article of the [Symfony](https://symfony.com) Differently series,
Have a look at the first one: {{ link('posts/2015-06-03-sf-differently-part-1-introduction.md', 'Introduction') }}.

Our goal in this post is to bootstrap an application to then create a search endpoint for items.
We've decided to use Symfony for a single reason: our company Acme used it since the begining
and the API developers team has Symfony and PHP skills.

> **Note**: Most frameworks have a good community support, a strong documentation,
> similar features and many developers available on the market. We'll see the
> importance of a framework performances in the following articles, but the point
> here is that the choice should mainly rely on skills we have internally
> (and the ones we can acquire).

## Symfony Standard Edition

The first step is to use [Composer](http://getcomposer.com/):

    composer create-project symfony/framework-standard-edition items

This will create a directory structure for our project, download a set of third
party libraries and ask us to set a bunch of configuration parameters. In this
series we'll use a Postgres database, so we need to edit `app/config.yml`:

```
# ...

# Doctrine Configuration
doctrine:
    dbal:
        driver: pdo_pgsql

# ...
```

Once finished we'll save our work using Git:

```
cd items
git init
git add -A
git ci -m 'Created a standard Symfony application'
```

> **Note**: We can also ue the [Symfony Installer](http://symfony.com/doc/current/book/installation.html#installing-the-symfony-installer)
> to create new projects.

## Configuring Apache

For the same reason we chose Symfony we've decided to use Apache for our web servers
(it's the one used for all previous projects).

> **Note**: By providing Nginx trainings and recruiting devops used to it Acme
> could change our technology stack. The only rule when switching to another
> technology is to stick to it in order to avoid having too many different technologies.

We need to create a virtual host first by creating the `/etc/apache2/sites-available/items.conf`
file:

```
<VirtualHost *:80>
    ServerName items.local

    DocumentRoot /home/foobar/items/web

    ErrorLog "/home/foobar/items/app/logs/apache_errors.log"
    CustomLog "/home/foobar/items/app/logs/apache_accesses.log" common

    <Directory /home/foobar/items/web>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride all
        Require all granted
        Order allow,deny
        allow from all
    </Directory>
</VirtualHost>
```

Apache will require access to the logs and cache directories, as well as our user.
The easiest way to avoid permission issues is to change Apache's user and group
to ours in `/etc/apache2/envvars`:

```
export APACHE_RUN_USER=foobar
export APACHE_RUN_GROUP=foobar
```

We'll aslo need to add the hostname to our `/etc/hosts` file:

```
echo '127.0.0.1 items.local' | sudo tee -a /etc/hosts
```

Finally we have to enable the website and reload Apache to take the configuration into account:

```
sudo a2ensite items
sudo service apache2 reload
```

We now should be able to see the message "Homepage" when browsing http://items.local/app_dev.php/app/example

## Tests

A nice tweak to do is to move tests in a separate directory, allowing Composer to only
autoload test class in development environments. This can be done by changing `composer.json`
as follow:

```
{
    "name": "acme/items",
    "license": "private",
    "type": "project",
    "description": "Specific APIs for items",
    "autoload": {
        "psr-4": { "AppBundle\\": "src/AppBundle" }
    },
    "autoload-dev": {
        "psr-4": { "AppBundle\\Tests\\": "tests/" }
    },
    "require": {
        "php": ">=5.3.3",
        "symfony/symfony": "~2.7@beta",
        "doctrine/orm": "~2.2,>=2.2.3,<2.5",
        "doctrine/dbal": "<2.5",
        "doctrine/doctrine-bundle": "~1.4",
        "symfony/assetic-bundle": "~2.3",
        "symfony/swiftmailer-bundle": "~2.3",
        "symfony/monolog-bundle": "~2.4",
        "sensio/distribution-bundle": "~3.0,>=3.0.12",
        "sensio/framework-extra-bundle": "~3.0,>=3.0.2",
        "incenteev/composer-parameter-handler": "~2.0"
    },
    "require-dev": {
        "sensio/generator-bundle": "~2.3"
    },
    "scripts": {
        "post-install-cmd": [
            "Incenteev\\ParameterHandler\\ScriptHandler::buildParameters",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::buildBootstrap",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::clearCache",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::installAssets",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::installRequirementsFile",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::removeSymfonyStandardFiles",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::prepareDeploymentTarget"
        ],
        "post-update-cmd": [
            "Incenteev\\ParameterHandler\\ScriptHandler::buildParameters",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::buildBootstrap",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::clearCache",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::installAssets",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::installRequirementsFile",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::removeSymfonyStandardFiles",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::prepareDeploymentTarget"
        ]
    },
    "extra": {
        "symfony-app-dir": "app",
        "symfony-web-dir": "web",
        "symfony-assets-install": "relative",
        "incenteev-parameters": {
            "file": "app/config/parameters.yml"
        }
    }
}
```

Since we've decided to move vendor binaries back to `vendor/bin`, we can un-ignore
the `bin` directory by editing `.gitignore`:

```
/web/bundles/
/app/bootstrap.php.cache
/app/cache/*
/app/config/parameters.yml
/app/logs/*
!app/cache/.gitkeep
!app/logs/.gitkeep
/app/phpunit.xml
/build/
/vendor/
/composer.phar
```

To make it official, we need to run the following commands:

    rm -rf bin
    composer update

> **Note**: In production, we'll need to run `composer install --no-dev --optimize-autoloader`

Our system/functional tests will involve database queries which can make the test suite
unreliable. To fix this, we'll create a "middleware" that wraps our `AppKernel` in a
database transaction and rolls it back after each requests:

To do so, we can create the following `app/RollbackKernel.php`:

```php
<?php
// File: app/RollbackKernel.php

use Doctrine\DBAL\Connection;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpKernel\HttpKernelInterface;

class RollbackKernel implements HttpKernelInterface
{
    private $app;
    private $connection;

    public function __construct(HttpKernelInterface $app, Connection $connection)
    {
        $this->app = $app;
        $this->connection = $connection;
    }

    public static function make()
    {
        $kernel = new \AppKernel('test', false);
        $kernel->boot();
        $connection = $kernel->getContainer()->get('doctrine.dbal.default_connection');

        return new self($kernel, $connection);
    }

    public function handle(Request $request, $type = HttpKernelInterface::MASTER_REQUEST, $catch = true)
    {
        $this->connection->beginTransaction();
        $response = $this->app->handle($request, $type, $catch);
        $this->connection->rollback();

        return $response;
    }
}
```

To be able to use `RollabKernel` in our test we need to make it available by
creating the following `app/bootstrap_test.php`:

```php
<?php
// File: app/bootstrap_test.php

require __DIR__.'/bootstrap.php.cache';
require __DIR__.'/AppKernel.php';
require __DIR__.'/RollBackKernel.php';
```

Then we can configure PHPUnit to use it by editing `app/phpunit.xml.dist`:

```
<?xml version="1.0" encoding="UTF-8"?>

<!-- http://phpunit.de/manual/current/en/appendixes.configuration.html -->
<phpunit backupGlobals="false" colors="true" syntaxCheck="false" bootstrap="bootstrap_test.php">
    <testsuites>
        <testsuite name="Functional Tests">
            <directory>../tests</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

Finally we'll install [phpspec](http://phpspec.net/) with [SpecGen](http://memio.github.io/spec-gen)
for our unit tests:

    composer require --dev phpunit/phpunit:~4.6 phpspec/phpspec:~2.2 memio/spec-gen:~0.3
    echo 'extensions:' > phpspec.yml
    echo '  - Memio\SpecGen\MemioSpecGenExtension' >> phpspec.yml

And now we're ready to test our application! Let's save our work:

    git add -A
    git commit -m 'Prepared application for tests'

## Scripts

There's 3 common tasks we'll be doing as developers with our application:

* build it for our development environment
* test it locally or in a Continuous Integration environment
* deploy it to production

In order to automate those in a simple way, we've decided to create 3 scripts:
`bin/build.sh`, `bin/deploy.sh` and `bin/test.sh`, but for this series we'll only
take care of `build` and `test`.

The build steps should reinitialize the database and Symfony's cache, for this
we'll need Doctrine Fixtures and Doctrine Migrations:

    composer require doctrine/doctrine-fixtures-bundle:~2.2
    composer require doctrine/migrations:~1.0@alpha
    composer require doctrine/doctrine-migrations-bundle:~1.0

Then we have to register them in `app/AppKernel.php`:

```php
<?php

use Symfony\Component\HttpKernel\Kernel;
use Symfony\Component\Config\Loader\LoaderInterface;

class AppKernel extends Kernel
{
    public function registerBundles()
    {
        $bundles = array(
            new Symfony\Bundle\FrameworkBundle\FrameworkBundle(),
            new Symfony\Bundle\SecurityBundle\SecurityBundle(),
            new Symfony\Bundle\TwigBundle\TwigBundle(),
            new Symfony\Bundle\MonologBundle\MonologBundle(),
            new Symfony\Bundle\SwiftmailerBundle\SwiftmailerBundle(),
            new Symfony\Bundle\AsseticBundle\AsseticBundle(),
            new Doctrine\Bundle\DoctrineBundle\DoctrineBundle(),
            new Sensio\Bundle\FrameworkExtraBundle\SensioFrameworkExtraBundle(),
            new AppBundle\AppBundle(),
        );

        if (in_array($this->getEnvironment(), array('dev', 'test'))) {
            $bundles[] = new Doctrine\Bundle\FixturesBundle\DoctrineFixturesBundle();
            $bundles[] = new Doctrine\Bundle\MigrationsBundle\DoctrineMigrationsBundle();
            $bundles[] = new Symfony\Bundle\DebugBundle\DebugBundle();
            $bundles[] = new Symfony\Bundle\WebProfilerBundle\WebProfilerBundle();
            $bundles[] = new Sensio\Bundle\DistributionBundle\SensioDistributionBundle();
            $bundles[] = new Sensio\Bundle\GeneratorBundle\SensioGeneratorBundle();
        }

        return $bundles;
    }

    public function registerContainerConfiguration(LoaderInterface $loader)
    {
        $loader->load($this->getRootDir().'/config/config_'.$this->getEnvironment().'.yml');
    }
}
```

Now we can write the following `bin/build.sh` script:

```
#!/usr/bin/env sh

echo ''
echo '// Building development environment'


rm -rf app/cache/* app/logs/*

composer --quiet --no-interaction install --optimize-autoloader > /dev/null

php app/console --quiet doctrine:database:drop --force > /dev/null 2>&1
php app/console --quiet doctrine:database:create
php app/console --no-interaction --quiet doctrine:migrations:migrate
php app/console --no-interaction --quiet doctrine:fixtures:load --fixtures=src

echo ''
echo ' [OK] Development environment built'
echo ''
```

The test steps should be similar, in addition they will run the test suites and
check for coding standards. We can install PHP CS Fixer for this:

    composer require --dev fabpot/php-cs-fixer:~1.6

Here's the `bin/test.sh` script:

```
#!/usr/bin/env sh

echo ''
echo '// Building test environment'

rm -rf app/cache/test app/logs/*test.log

composer --quiet --no-interaction install --optimize-autoloader  > /dev/null
php app/console --env=test --quiet cache:clear


php app/console --env=test --no-debug --quiet doctrine:database:drop --force > /dev/null 2>&1
php app/console --env=test --no-debug --quiet doctrine:database:create
php app/console --env=test --no-debug --no-interaction --quiet doctrine:migrations:migrate
php app/console --env=test --no-debug --no-interaction --quiet doctrine:fixtures:load --fixtures=src

echo ''
echo ' [OK] Test environment built'
echo ''

vendor/bin/phpunit -c app && vendor/bin/phpspec --no-interaction run --format=dot && vendor/bin/php-cs-fixer fix --dry-run --config=sf23 .
```

With this we can start the tickets assigned to us, we can commit the changes:

    chmod +x bin/*.sh
    git add -A
    git commit -m 'Created build and test scripts'

## Conclusion

Acme's technology stack is composed of Apache2, PostgreSQL, Symfony, PHPUnit and phpspec.
In order to ake sure that anyone in the team or any new comers can maintain this new
application in the future, we've chosen to stay consistent with the rest.

In the next article, we'll create the search items endpoint in a pragmatic way.
