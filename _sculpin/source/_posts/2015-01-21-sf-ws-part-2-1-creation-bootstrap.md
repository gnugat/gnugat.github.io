---
layout: post
title: Symfony / Web Services - part 2.1: Creation bootstrap
tags:
    - Symfony
    - Symfony / Web Services series
---

This is the second article of the series on managing Web Services in a
[Symfony](https://symfony.com) environment. Have a look at the first one:
[1. Introduction](/2015/01/14/sf-ws-part-1-introduction.html).

In this post we'll create an empty application and prepare it:

* [Installing the standard edition](#installing-the-standard-edition)
* [Twitching for tests](#twitching-for-tests)
* [Patching for JSON submit](#patching-for-json-submit)
* [Setting up the authentication](#setting-up-the-authentication)
* [Conclusion](#conclusion)

## Installing the standard edition

First of all, we need to create an empty Symfony application:

    composer create-project symfony/framework-standard-edition ws

> **Note**: Take the time to configure a MySQL database, we'll need it later.

Next we'll configure an Apache's virtual host (should be in `/etc/apache2/sites-available/ws.conf`):

```
<VirtualHost *:80>
    ServerName ws.local

    DocumentRoot /home/foobar/ws/web

    ErrorLog "/home/foobar/ws/app/logs/apache_errors.log"
    CustomLog "/home/foobar/ws/app/logs/apache_accesses.log" common

    <Directory /home/foobar/ws/web>
        Options Indexes FollowSymLinks MultiViews
        AllowOverride None
        Require all granted
        Order allow,deny
        allow from all
    </Directory>
</VirtualHost>
```

Apache will require access to the logs and cache directories, as well as your
user. The easiest way to do so is to change Apache's user and group to yours in
`/etc/apache2/envvars`:

```
export APACHE_RUN_USER=foobar
export APACHE_RUN_GROUP=foobar
```

In order for this to work we'll update our `/etc/hosts` file:

    echo '127.0.0.1 ws.local' | sudo tee -a /etc/hosts

And finally we'll restart the web server:

    sudo service apache2 restart

We should be able to see "Homepage" when browsing http://ws.local/app_dev.php/app/example

Let's commit our work:

    git init
    git add -A
    git ci -m 'Created a standard Symfony application'

## Twitching for tests

As explained in [this article](/2014/11/15/sf2-quick-functional-tests.html),
we'll twitch the standard edition a little bit in order to make tests more explicit.

First we create a bootstraping file:

```php
<?php
// File: app/bootstrap.php

require __DIR__.'/bootstrap.php.cache';
require __DIR__.'/AppKernel.php';
```

Then we configure PHPUnit to use it:

```xml
<?xml version="1.0" encoding="UTF-8"?>

<!-- http://phpunit.de/manual/4.1/en/appendixes.configuration.html -->
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="http://schema.phpunit.de/4.1/phpunit.xsd"
         backupGlobals="false"
         colors="true"
         bootstrap="bootstrap.php"
>
    <testsuites>
        <testsuite name="Project Test Suite">
            <directory>../tests</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

We've decided to put our tests in a separate `tests` directory, allowing us to
decalre an autoload mapping specific for development. To fully optimize our
autoloading, we'll also define our `src/AppBundle` folder as a path for the
`AppBundle` namespace, using PSR-4:

```
{
    "name": "symfony/framework-standard-edition",
    "license": "MIT",
    "type": "project",
    "description": "The \"Symfony Standard Edition\" distribution",
    "autoload": {
        "psr-4": { "AppBundle\\": "src/AppBundle" }
    },
    "autoload-dev": {
        "psr-4": { "AppBundle\\Tests\\": "tests" }
    },
    "require": {
        "php": ">=5.3.3",
        "symfony/symfony": "2.6.*",
        "doctrine/orm": "~2.2,>=2.2.3",
        "doctrine/doctrine-bundle": "~1.2",
        "twig/extensions": "~1.0",
        "symfony/assetic-bundle": "~2.3",
        "symfony/swiftmailer-bundle": "~2.3",
        "symfony/monolog-bundle": "~2.4",
        "sensio/distribution-bundle": "~3.0.12",
        "sensio/framework-extra-bundle": "~3.0",
        "incenteev/composer-parameter-handler": "~2.0"
    },
    "require-dev": {
        "sensio/generator-bundle": "~2.3"
    },
    "scripts": {
        "post-root-package-install": [
            "SymfonyStandard\\Composer::hookRootPackageInstall"
        ],
        "post-install-cmd": [
            "Incenteev\\ParameterHandler\\ScriptHandler::buildParameters",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::buildBootstrap",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::clearCache",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::installAssets",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::installRequirementsFile",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::removeSymfonyStandardFiles"
        ],
        "post-update-cmd": [
            "Incenteev\\ParameterHandler\\ScriptHandler::buildParameters",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::buildBootstrap",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::clearCache",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::installAssets",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::installRequirementsFile",
            "Sensio\\Bundle\\DistributionBundle\\Composer\\ScriptHandler::removeSymfonyStandardFiles"
        ]
    },
    "config": {
        "bin-dir": "bin"
    },
    "extra": {
        "symfony-app-dir": "app",
        "symfony-web-dir": "web",
        "symfony-assets-install": "relative",
        "incenteev-parameters": {
            "file": "app/config/parameters.yml"
        },
        "branch-alias": {
            "dev-master": "2.6-dev"
        }
    }
}
```

To make it official, we need to run the following command:

    composer dump-autoload

We'll also install [phpspec](http://phpspec.net):

    composer require phpspec/phpspec:~2.1

With this our tests will be awesome! Time to commit:

    git add -A
    git commit -m 'Configured tests'

## Patching for JSON submit

Symfony provides the posted data in the `Request`'s `request` attribute, except
if the content type is `application/json`, as it will be our case. To fix this
behavior we'll follow the steps described in [this article](/2014/09/03/master-sf2-part-5-events.html).

Let's start by the creation of an event listener:

```php
<?php
// File: src/AppBundle/EventListener/SubmitJsonListener.php

namespace AppBundle\EventListener;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpKernel\Event\GetResponseEvent;

/**
 * PHP does not populate $_POST with the data submitted via a JSON Request,
 * causing an empty $request->request.
 *
 * This listener fixes this.
 */
class SubmitJsonListener
{
    /**
     * @param GetResponseEvent $event
     */
    public function onKernelRequest(GetResponseEvent $event)
    {
        $request = $event->getRequest();
        $hasBeenSubmited = in_array($request->getMethod(), array('POST', 'PUT'), true);
        $isJson = ('application/json' === $request->headers->get('Content-Type'));
        if (!$hasBeenSubmited || !$isJson) {
            return;
        }
        $data = json_decode($request->getContent(), true);
        if (JSON_ERROR_NONE !== json_last_error()) {
            $event->setResponse(new JsonResponse(array('error' => 'Invalid or malformed JSON'), 400));
        }
        $request->request->add($data ?: array());
    }
}
```

Finally we'll register it in the Dependency Injection Container:

```
# File: app/config/services.yml
services:
    app.submit_json_listener:
        class: AppBundle\EventListener\SubmitJsonListener
        tags:
            - { name: kernel.event_listener, event: kernel.request, method: onKernelRequest }
```

## Setting up the authentication

HTTP basic authentication can be configured through the `app/config/security.yml`
file, as described in [the official documentation](http://symfony.com/doc/current/book/security.html).

In the end we should have something like this:

```
# app/config/security.yml
security:
    encoders:
        Symfony\Component\Security\Core\User\User: plaintext

    providers:
        in_memory:
            memory:
                users:
                    spanish_inquisition:
                        password: 'NobodyExpectsIt!'
                        roles:
                            - ROLE_USER

    firewalls:
        dev:
            pattern: ^/(_(profiler|wdt)|css|images|js)/
            security: false

        default:
            anonymous: ~
            http_basic: ~
            stateless: true

    access_control:
        - { path: /.*, roles: ROLE_USER }
```

Now to comply with our description we need to customize the error. We can do so
using another event listener:

```php
<?php
// File: src/AppBundle/EventListener/ForbiddenExceptionListener.php

namespace AppBundle\EventListener;

use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpKernel\Event\GetResponseForExceptionEvent;
use Symfony\Component\Security\Core\Exception\AccessDeniedException;

/**
 * PHP does not populate $_POST with the data submitted via a JSON Request,
 * causing an empty $request->request.
 *
 * This listener fixes this.
 */
class ForbiddenExceptionListener
{
    /**
     * @param GetResponseForExceptionEvent $event
     */
    public function onKernelException(GetResponseForExceptionEvent $event)
    {
        $exception = $event->getException();
        if (!$exception instanceof AccessDeniedException) {
            return;
        }
        $error = 'The credentials are either missing or incorrect';
        $event->setResponse(new JsonResponse(array('error' => $error), 403));
    }
}
```

And to register it:

```
# File: app/config/services.yml
services:
    app.submit_json_listener:
        class: AppBundle\EventListener\SubmitJsonListener
        tags:
            - { name: kernel.event_listener, event: kernel.request, method: onKernelRequest }

    app.forbidden_exception_listener:
        class: AppBundle\EventListener\ForbiddenExceptionListener
        tags:
            - { name: kernel.event_listener, event: kernel.exception, method: onKernelException, priority: 10 }
```

> **Note**: the Symfony Security event listener has a priority set to 0.
> In order for our listener to be executed, we need to set a higher one, like 10.

As you can see by browsing http://ws.local/app_dev.php/app/example, we now need
to provide the `spanish_inquisition` with the `NobodyExpectsIt!` password to
access the page.

This is enough for today, we'll commit our work:

    git add -A
    git commit -m 'Created custom event listeners'

## Conclusion

Our application is now ready!

In the [next article](/2015/01/28/sf-ws-part-2-2-creation-pragmatic.html
we'll create the first endpoint, the creation of profiles, using a pragmatic approach.
