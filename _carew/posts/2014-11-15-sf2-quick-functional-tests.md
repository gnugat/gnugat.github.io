---
layout: post
title: Symfony2 - Quick functional tests
tags:
    - Symfony2
    - technical
    - tests
---

> **TL;DR**: Only check the status and exit code, don't use the given `TestCase`.

Provided that your controllers and commands are thin and they rely on services
which are heavily unit tested, only checking the status and exit code in your
functional test should be entirely sufficient.

> **Note**: Checking at least the status and exit code is recommended by
> [Symfony's Official Best Practices](http://symfony.com/doc/current/best_practices/tests.html#functional-tests).

In this article, we will see how easy and quick it is to write them.

## Making the Kernel available

If you're familiar with [Symfony2](http://symfony.com), you might use one of
the given `KernelTestCase` to write your tests with [PHPUnit](http://phpunit.de).

The whole purpose of this file is to create an instance of the application's
Kernel, by guessing its localization. The problem with this approach is that it
ties you to the PHPUnit test framework. If you have a look at its code, you'll
also find it a bit complicated.

> **Note**: `WebTestCase` also makes available a [crawler](http://symfony.com/doc/current/book/testing.html#functional-tests),
> which we don't need as we only intend on checking the status code, not the body.

Let's take an easier way: we will create a bootstrap file which requires the
kernel's file:

```php
<?php
// File: app/bootstrap.php

require __DIR__.'/bootstrap.php.cache';
require __DIR__.'/AppKernel.php';
```

Now all you need to do for your tests is to use this file. For example with
PHPUnit:

```xml
<?xml version="1.0" encoding="UTF-8"?>

<!-- File: app/phpunit.xml.dist -->
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="http://schema.phpunit.de/4.3/phpunit.xsd"
    backupGlobals="false"
    colors="true"
    bootstrap="./bootstrap.php"
>
    <testsuites>
        <testsuite name="Test Suite">
            <directory>./src/AppBundle/Tests</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

## Testing commands

Now let's say we're testing the famous [AcmeDemoBundle](https://github.com/sensiolabs/SensioDistributionBundle/tree/master/Resources/skeleton/acme-demo-bundle/Acme/DemoBundle),
and its [hello world command](https://github.com/sensiolabs/SensioDistributionBundle/blob/master/Resources/skeleton/acme-demo-bundle/Acme/DemoBundle/Command/HelloWorldCommand.php):

```php
<?php

namespace Acme\DemoBundle\Tests\Command;

use Symfony\Bundle\FrameworkBundle\Console\Application;
use Symfony\Component\Console\Output\NullOutput;
use Symfony\Component\Console\Input\ArrayInput;

class HelloWorldCommandTest extends \PHPUnit_Framework_TestCase
{
    private $app;
    private $output;

    protected function setUp()
    {
        $kernel = new \AppKernel('test', false);
        $this->app = new Application($kernel);
        $this->app->setAutoExit(false);
        $this->output = new NullOutput();
    }

    public function testItRunsSuccessfully()
    {
        $input = new ArrayInput(array(
            'commandName' => 'acme:hello',
            'name' => 'Igor',
        ));

        $exitCode = $this->app->run($input, $this->output);

        $this->assertSame(0, $exitCode);
    }
}
```

As you can see our test is neatly structured in 3 parts: input definition, the
actual call and finally the check.

> **Note**: the `setAutoExit` method will ensure that the application doesn't
> call PHP's `exit`. The `NullOutput` ensures that nothing is displayed.

## Testing controllers

Once again let's test AcmeDemoBundle, this time the [demo controller](https://github.com/sensiolabs/SensioDistributionBundle/blob/master/Resources/skeleton/acme-demo-bundle/Acme/DemoBundle/Controller/DemoController.php):

```php
<?php

namespace Acme\DemoBundle\Tests\Controller;

use Symfony\Component\HttpFoundation\Request;

class DemoControllerTest extends \PHPUnit_Framework_TestCase
{
    private $app;

    protected function setUp()
    {
        $this->app = new \AppKernel('test', false);
        $this->app->boot();
    }

    public function testHomepage()
    {
        $request = new Request::create('/', 'GET');

        $response = $this->app->handle($request);

        $this->assertTrue($response->isSuccessful());
    }

    public function testItSaysHello()
    {
        $request = new Request('/hello/igor', 'GET');

        $response = $this->app->handle($request);

        $this->assertTrue($response->isSuccessful());
    }

    public function testItSendsEmail()
    {
        $request = new Request('/contact', 'POST', array(
            'email' => 'igor@example.com',
            'content' => 'Hello',
        ));

        $response = $this->app->handle($request);

        $this->assertTrue($response->isSuccessful());
    }
}
```

> **Note**: The `boot` method makes the container available.

## Conclusion

We stripped Symfony2 to its bare minimum and as a result we are now able to
write functional tests without any effort.

I hope you enjoyed this article, please feel free to
[tweet me](https://twitter.com/epiloic) for any comment and question.
