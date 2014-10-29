---
layout: post
title: Symfony2 Bundle, standalone
tags:
    - technical
    - Symfony2
---

> **TL;DR**: Create an empty application in your bundle to allow people to test
> it (manually or automatically) outside of an actual application.

[Symfony2](http://symfony.com) bundles are a great way to:

* configure the application's Dependency Injection Container (DIC)
* provide it with resources (mainly templates and assets)
* register entry points (like controllers and commands)

In this article, we will see how to make sure a third party bundle actually work
by creating an embed application. We will then have a look at its practical use:

1. [Minimal Bundle](#minimal-bundle)
2. [Embed Application](#embed-application)
3. [Manual tests](#manual-tests)
    * [Running commands](#running-commands)
    * [Browsing pages](#browsing-pages)
4. [Automated tests](#automated-tests)
    * [Container tests](#container-tests)
    * [Functional CLI tests](#functional-cli-tests)
    * [Functional web tests](#functional-web-tests)
5. [Conclusion](#conclusion)

## Minimal Bundle

Creating a bundle is fairly easy as you just need to create the following class:

```php
<?php
// File: AcmeStandaloneBundle.php

namespace Acme\StandaloneBundle;

use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\HttpKernel\Bundle\Bundle;

class AcmeStandaloneBundle extends Bundle
{
}
```

It also needs a `composer.json` file, so it can be distributed all around the
world:

```json
{
    "name": "acme/standalone-bundle",
    "type": "symfony-bundle",
    "license": "MIT",
    "autoload": {
        "psr-4": {
            "Acme\\StandaloneBundle\\": ""
        }
    },
    "require": {
        "symfony/http-kernel": "~2.3"
    }
}
```

> **Note**: to release it, you would then need to create a git repository and
> to register it in [Packagist](https://packagist.org/).

## Embed Application

Now how can we make sure our bundle would work in an application? We could:

1. use an existing application
2. make the bundle's sources available in it somehow:
    * creating the bundle in the application
    * or making a symbolic link that points to the bundle
3. register it in its `app/AppKernel.php` file and have a look...

But we can do better!

We can create the smallest Symfony2 application ever **inside** our bundle:

```php
<?php
// File: Tests/app/AppKernel.php

use Symfony\Component\HttpKernel\Kernel;
use Symfony\Component\Config\Loader\LoaderInterface;

class AppKernel extends Kernel
{
    public function registerBundles()
    {
        return array(
            new Symfony\Bundle\FrameworkBundle\FrameworkBundle(),
            new Acme\StandaloneBundle\AcmeStandaloneBundle(),
        );
    }

    public function registerContainerConfiguration(LoaderInterface $loader)
    {
        $loader->load(__DIR__.'/config.yml');
    }
}
```

[FrameworkBundle](https://github.com/symfony/FrameworkBundle) requires the
following configuration parameter in order to work:

```yaml
# File: Tests/app/config.yml
framework:
    secret: "Three can keep a secret, if two of them are dead."
```

I'd also advise you to create an autoload file to make things easier:

```php
<?php
// File: Tests/app/autoload.php

$loader = require __DIR__.'/../../vendor/autoload.php';
require __DIR__.'/AppKernel.php';
```

The last step is to add the new dependency in the `composer.json` file:

```json
{
    "name": "acme/standalone-bundle",
    "type": "symfony-bundle",
    "license": "MIT",
    "autoload": {
        "psr-4": {
            "Acme\\StandaloneBundle\\": ""
        }
    },
    "require": {
        "symfony/http-kernel": "~2.3"
    },
    "require-dev": {
        "symfony/framework-bundle": "~2.3"
    }
}
```

We would also need to ignore the following directories:

```
# File: .gitignore

/Tests/app/cache
/Tests/app/logs
```

And that's it, we now have a minimalistic embed application in our bundle.
As it can now be ran on its own, it has become a **Standalone Bundle**!

Let's see the practical use.

## Manual tests

Because your bundle now doesn't need any existing applications to be used,
people will be able to test it manually and do some demonstrations with it.

### Running commands

Let's pretend we created a command in our bundle. We'd like to run it just to
make sure everything works as expected. For this we'll need to create an
embed console:

```php
<?php
// File: Tests/app/console.php

set_time_limit(0);

require_once __DIR__.'/autoload.php';

use Symfony\Bundle\FrameworkBundle\Console\Application;

$kernel = new AppKernel('dev', true);
$application = new Application($kernel);
$application->run();
```

That's it! You can now run:

    php Tests/app/console.php

### Browsing pages

Let's pretend we created a controller which returns some JSON data. We'd like to
browse it just to make sure everyting works as expected. For this, we'll need to
create an embed web app:

```php
<?php
// File: Tests/app/web.php

use Symfony\Component\HttpFoundation\Request;

require_once __DIR__.'/autoload.php';

$kernel = new AppKernel('prod', false);
$request = Request::createFromGlobals();
$response = $kernel->handle($request);
$response->send();
```

That's it! You can now run:

    php Tests/app/console.php server:run -d Tests/app

And browse your application.

> **Note**: If you use a templating engine like Twig to render HTML pages,
> or if you use the Symfony2 Form Component in your bundle, don't forget to add
> the dependencies to your `composer.json` file and to register the appropriate
> bundles to the embed `AppKernel`.

## Automated tests

Manual tests are great to get a quick idea of what your bundle does.
But an embed application is also great to write automated tests.

### Container tests

Let's pretend we created a service which is defined in the DIC. We'd like to
make sure it is properly configured (for e.g. checking if we forgot to inject a
dependency). For this, we'll need to created a simple test:

```php
<?php
// File: Tests/ServiceTest.php

namespace Acme\StandaloneBundle\Tests;

class ServiceTest extends \PHPUnit_Framework_TestCase
{
    private $container;

    protected function setUp()
    {
        $kernel = new \AppKernel('test', true);
        $kernel->boot();

        $this->container = $kernel->getContainer();
    }

    public function testServiceIsDefinedInContainer()
    {
        $service = $this->container->get('acme_standalone.service');

        $this->assertInstanceOf('Acme\StandaloneBundle\Service', $service);
    }
}
```

We need to add [PHPUnit](https://phpunit.de/) as a development dependency:

```json
{
    "name": "acme/standalone-bundle",
    "type": "symfony-bundle",
    "license": "MIT",
    "autoload": {
        "psr-4": {
            "Acme\\StandaloneBundle\\": ""
        }
    },
    "require": {
        "symfony/http-kernel": "~2.3"
    },
    "require-dev": {
        "symfony/framework-bundle": "~2.3"
        "phpunit/phpunit": "~4.3"
    }
}
```

Finally we need to configure PHPUnit to use our autoload:

```xml
<?xml version="1.0" encoding="UTF-8"?>

<!-- http://phpunit.de/manual/4.3/en/appendixes.configuration.html -->
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="http://schema.phpunit.de/4.3/phpunit.xsd"
    backupGlobals="false"
    colors="true"
    bootstrap="./Tests/app/autoload.php"
>
    <testsuites>
        <testsuite name="Test Suite">
            <directory>./Tests/</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

That's it! You can now run:

    ./vendor/bin/phpunit

> **Note**: You can of course use any testing framework of your choice.

### Functional CLI tests

Let's pretend we created a command. We'd like to run it automatically and check
its exit code to make sure it works. For this, we'll need to created a simple
test:

```php
<?php
// File: Tests/ServiceTest.php

namespace Acme\StandaloneBundle\Tests\Command;

use Symfony\Bundle\FrameworkBundle\Console\Application;
use Symfony\Component\Console\Input\ArrayInput;
use Symfony\Component\Console\Output\NullOutput;

class DemoCommandTest extends \PHPUnit_Framework_TestCase
{
    private $application;

    protected function setUp()
    {
        $kernel = new AppKernel('dev', true);
        $this->application = new Application($kernel);
    }

    public function testItRunsSuccessfully()
    {
        $output = new NullOutput();
        $input = new ArrayInput(
            'command_name' => 'acme:demo',
            'argument' => 'value',
            '--option' => 'value',
        );
        $exitCode = $this->application->run($input, $output);

        $this->assertSame(0, $exitCode);
    }
}
```

And that's it!

### Functional web tests

Let's pretend we created a controller which returns some JSON data. We'd like to
browse it automatically and check its status code to make sure it works. For
this, we'll need to created a simple test:

```php
<?php
// File: Tests/ServiceTest.php

namespace Acme\StandaloneBundle\Tests\Controller;

use Symfony\Bundle\FrameworkBundle\Console\Application;
use Symfony\Component\Console\Input\ArrayInput;
use Symfony\Component\Console\Output\NullOutput;

class DemoControllerTest extends \PHPUnit_Framework_TestCase
{
    private $client;

    protected function setUp()
    {
        $kernel = new AppKernel('test', true);
        $kernel->boot();

        $this->client = $kernel->getContainer()->get('test.client');
    }

    public function testItRunsSuccessfully()
    {
        $headers = array('CONTENT_TYPE' => 'application/json');
        $content = array('parameter' => 'value');
        $response = $this->client->request(
            'POST',
            '/demo',
            array(),
            array(),
            $headers,
            $content
        );

        $this->assertTrue($response->isSuccessful());
    }
}
```

The `test.client` service is only available when the `test` configuration
parameter is set.

```yaml
# File: Tests/app/config.yml
framework:
    secret: "Three can keep a secret, if two of them are dead."
    test: ~
```

And that's it!

> **Note**: When creating APIs, you might want to test the precise status code.

## Conclusion

Creating an embed application in a third party bundle is fairly easy and brings
many advantages as it enables demonstrations and simple automated tests.

I hope you enjoyed this article, if you have any questions or comments, please
[let me know](https://twitter.com/epiloic).
