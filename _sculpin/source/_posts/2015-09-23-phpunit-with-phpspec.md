---
layout: post
title: PHPUnit with phpspec
tags:
    - introducing library
    - phpspec
    - phpunit
    - TDD
---

[PHPUnit](https://phpunit.de/) is a port of [jUnit](http://junit.org/), its name
might be deceptive: it allows you to write any type of tests (unit, but also functional,
system, integration, end to end, acceptance, etc).

[phpspec](http://www.phpspec.net) was at first a port of [rspec](http://rspec.info/),
it can be considered as a unit test framework that enforces practices it considers best.

> **Note**: [read more about phpspec](/2015/08/03/phpspec.html).

In this article, we'll see how to use both tools together in a same project.

## Fortune: our example

We're going to build part of a [fortune](https://en.wikipedia.org/wiki/Fortune_%28Unix%29)
application for our example, more precisely we're going to build a CLI allowing us to save quotes.

To do so, we'll bootstrap a symfony application using the [Empty Edition](https://github.com/gnugat/symfony-empty-edition):

    composer create-project gnugat/symfony-empty-edition fortune
    cd fortune

We'll need to install our test frameworks:

    composer require --dev phpunit/phpunit
    composer require --dev phpspec/phpspec

Finally we'll configure PHPUnit:

```xml
<?xml version="1.0" encoding="UTF-8"?>

<!-- phpunit.xml.dist -->
<!-- http://phpunit.de/manual/current/en/appendixes.configuration.html -->
<phpunit backupGlobals="false" colors="true" syntaxCheck="false" bootstrap="app/bootstrap.php">
    <testsuites>
        <testsuite name="System Tests">
            <directory>tests</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

## The command

Our first step will be to write a **system test** describing the command:

```php
<?php
// tests/Command/SaveQuoteCommandTest.php

namespace AppBundle\Tests\Command;

use AppKernel;
use PHPUnit_Framework_TestCase;
use Symfony\Bundle\FrameworkBundle\Console\Application;
use Symfony\Component\Console\Tester\ApplicationTester;

class SaveQuoteCommandTest extends PHPUnit_Framework_TestCase
{
    const EXIT_SUCCESS = 0;

    private $app;

    protected function setUp()
    {
        $kernel = new AppKernel('test', false);
        $application = new Application($kernel);
        $application->setAutoExit(false);
        $this->app = new ApplicationTester($application);
    }

    /**
     * @test
     */
    public function it_saves_a_new_quote()
    {
        $exitCode = $this->app->run(array(
            'quote:save',
            'quote' => 'Nobody expects the spanish inquisition',
        ));

        self::assertSame(self::EXIT_SUCCESS, $exitCode, $this->app->getDisplay());
    }
}
```

> **Note**: Testing only the exit code is called "Smoke Testing" and is a very
> efficient way to check if the application is broken.
> Testing the output would be tedious and would make our test fragile as it might change often.

Let's run it:

    vendor/bin/phpunit

The tests fails because the command doesn't exist. Let's fix that:

```php
<?php
// src/AppBundle/Command/SaveQuoteCommand.php

namespace AppBundle\Command;

use Symfony\Bundle\FrameworkBundle\Command\ContainerAwareCommand;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Output\OutputInterface;

class SaveQuoteCommand extends ContainerAwareCommand
{
    protected function configure()
    {
        $this->setName('quote:save');
        $this->addArgument('quote', InputArgument::REQUIRED);
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $output->writeln('');
        $output->writeln('// Saving quote');

        $this->getContainer()->get('app.save_new_quote')->save(
            $input->getArgument('quote')
        );

        $output->writeln('');
        $output->writeln(' [OK] Quote saved');
        $output->writeln('');
    }
}
```

Then run the test again:

    vendor/bin/phpunit

It now fails for a different reason: the service used doesn't exist.

## The service

The second step is to write the unit test for the service. With phpspec we can
first bootstrap it:

    vendor/bin/phpspec describe 'AppBundle\Service\SaveNewQuote'

Then we need to edit it:

```php
<?php
// spec/AppBundle/Service/SaveNewQuoteSpec.php

namespace spec\AppBundle\Service;

use PhpSpec\ObjectBehavior;
use Symfony\Component\Filesystem\Filesystem;

class SaveNewQuoteSpec extends ObjectBehavior
{
    const FILENAME = '/tmp/quotes.txt';
    const QUOTE = 'Nobody expects the spanish inquisition!';

    function let(Filesystem $filesystem)
    {
        $this->beConstructedWith($filesystem, self::FILENAME);
    }

    function it_saves_new_quote(Filesystem $filesystem)
    {
        $filesystem->dumpFile(self::FILENAME, self::QUOTE)->shouldBeCalled();

        $this->save(self::QUOTE);
    }
}
```

Time to run the suite:

    vendor/bin/phpspec run

phpspec will detect that the tested class doesn't exist and will bootstrap it for us,
so we just have to edit it:

```php
<?php
// src/AppBundle/Service/SaveNewQuote.php

namespace AppBundle\Service;

use Symfony\Component\Filesystem\Filesystem;

class SaveNewQuote
{
    private $filesystem;
    private $filename;

    public function __construct(Filesystem $filesystem, $filename)
    {
        $this->filesystem = $filesystem;
        $this->filename = $filename;
    }

    public function save($quote)
    {
        $this->filesystem->dumpFile($this->filename, $quote);
    }
}
```

Again, we're going to run our unit test:

    vendor/bin/phpspec run

It's finally green! Our final step will be to define our service in the Dependency Injection
Container:

```
# app/config/config.yml

imports:
    - { resource: parameters.yml }
    - { resource: importer.php }

framework:
    secret: "%secret%"

services:
    app.save_new_quote:
        class: AppBundle\Service\SaveNewQuote
        arguments:
            - "@filesystem"
            - "%kernel.root_dir%/cache/quotes"
```

To make sure everything is fine, let's clear the cache and run the test:

    rm -rf app/cache/*
    vendor/bin/phpunit

It's [Super Green](https://www.youtube.com/watch?v=lFeLDc2CzOs)!

## Conclusion

As we can see, PHPUnit and phpspec can work perfectly well together.

Of course we could write our unit test in a similar manner with PHPUnit:

```
<?php
// tests/Service/SaveNewQuoteTest.php

namespace AppBundle\Tests\Service;

use AppBundle\Service\SaveNewQuote;
use PHPUnit_Framework_TestCase;

class SaveNewQuoteTest extends PHPUnit_Framework_TestCase
{
    const FILENAME = '/tmp/quotes.txt';
    const QUOTE = 'Nobody expects the spanish inquisition!';

    private $filesystem;
    private $saveNewQuote;

    protected function setUp()
    {
        $this->filesystem = $this->prophesize('Symfony\Component\Filesystem\Filesystem');
        $this->saveNewQuote = new SaveNewQuote($this->filesystem->reveal(), self::FILENAME);
    }

    /**
     * @test
     * @group unit
     */
    public function it_saves_new_quote()
    {
        $this->filesystem->dumpFile(self::FILENAME, self::QUOTE)->shouldBeCalled();

        $this->saveNewQuote->save(self::QUOTE);
    }
}
```

And run it separately:

    vendor/bin/phpunit --group=unit

But then we would lose all the advantages of phpspec:

* it adds less overhead (this same test runs in ~20ms with phpspec, and ~80ms with PHPUnit)
* it tells you when it thinks you're doing something wrong (typically by making it harder/impossible for you to do it)
* it bootstraps things for you if you follow the TDD workflow (test first, then code)

> **Reference**: <a class="button button-reference" href="/2015/08/03/phpspec.html">see the phpspec reference article</a>
