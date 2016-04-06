---
layout: post
title: The Ultimate Developer Guide to Symfony - CLI Example
tags:
    - symfony
    - ultimate symfony series
    - reference
---

> **Reference**: This article is intended to be as complete as possible and is
> kept up to date.

> **TL;DR**: Practice makes Better.

In this guide we've explored the main standalone libraries (also known as "Components")
provided by [Symfony](http://symfony.com) to help us build applications:

* [HTTP Kernel and HTTP Foundation](/2016/02/03/ultimate-symfony-http-kernel.html)
* [Event Dispatcher](/2016/02/10/ultimate-symfony-event-dispatcher.html)
* [Routing and YAML](/2016/02/17/ultimate-symfony-routing.html)
* [Dependency Injection](/2016/02/24/ultimate-symfony-dependency-injection.html)
* [Console](/2016/03/02/ultimate-symfony-console.html)

We've also seen how HttpKernel enabled reusable code with [Bundles](/2016/03/09/ultimate-symfony-bundle.html),
and the different ways to organize our application [tree directory](/2016/03/16/ultimate-symfony-skeleton.html).

Finally we've started to put all this knowledge in practice by creating a
"fortune" project with:

* [an endpoint that allows us to submit new fortunes](/2016/03/24/ultimate-symfony-api-example.html).
* [a page that lists all fortunes](/2016/03/30/ultimate-symfony-web-example.html).

In this article, we're going to continue the "fortune" project by creating a
command that prints the last fortune.

> **Note**: To start with the same code, use the following repository:
>
> ```
> git clone https://github.com/gnugat-examples/fortune.git
> cd fortune
> composer install -o --ignore-platform-reqs
> git checkout web-example
> git checkout -b cli-example
> ```

## Create the Command

The CLI equivalent of a web Controller is a Command. We're first going to create
a functional test:

```php
<?php
// tests/AppBundle/Command/PrintLastFortuneCommandTest.php

namespace Tests\AppBundle\Command;

use Symfony\Bundle\FrameworkBundle\Console\Application;
use Symfony\Component\Console\Tester\ApplicationTester;

class PrintLastFortuneCommandTest extends \PHPUnit_Framework_TestCase
{
    private $app;

    protected function setUp()
    {
        $kernel = new \AppKernel('test', false);
        $application = new Application($kernel);
        $application->setAutoExit(false);
        $this->app = new ApplicationTester($application);
    }

    /**
     * @test
     */
    public function it_prints_last_fortune()
    {
        $input = array(
            'print-last-fortune',
        );

        $exitCode = $this->app->run($input);

        self::assertSame(0, $exitCode, $this->app->getDisplay());
    }
}
```

Successful commands always return `0` as an exit code, which is what we're going
to check in this test. Let's run the suite:

```
vendor/bin/phpunit
```

They fail, telling us to create the actual code for the command:

```php
<?php
// src/AppBundle/Command/PrintLastFortuneCommand.php

namespace AppBundle\Command;

use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class PrintLastFortuneCommand extends Command
{
    protected function configure()
    {
        $this->setName('print-last-fortune');
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
    }
}
```

Since Symfony looks automatically for classes that extend `Command` in the
`Command` directory of each registered bundle, our command is now available:

```
vendor/bin/phpunit
```

The test suite is now green. We can run it using the console:

```
bin/console print-last-fortune
```

We should successfully get an empty line.

## Create the logic

In order to get something else than an empty line, we need to create a new use
case. It's purpose will be to convey intent (print the last fortune) and
to validate the input parameters:

```php
<?php
// tests/AppBundle/Service/PrintLastFortuneTest.php

namespace Tests\AppBundle\Service;

use AppBundle\Service\PrintLastFortune;

class PrintLastFortuneTest extends \PHPUnit_Framework_TestCase
{
    /**
     * @test
     */
    public function it_has_no_parameters()
    {
        $printLastFortune = new PrintLastFortune();
    }
}
```

Well, currently we don't have any input parameters. But if we get a new requirement
that does need input parameters, we'll be ready to validate them. For now we can
run the tests:

```
vendor/bin/phpunit
```

They fail because we need to create the actual class:

```php
<?php
// src/AppBundle/Service/PrintLastFortune.php

namespace AppBundle\Service;

class PrintLastFortune
{
}
```

This should fix the issue:

```
vendor/bin/phpunit
```

Now let's create Handler that will list all fortunes:

```php
<?php
// tests/AppBundle/Service/PrintLastFortuneHandlerTest.php

namespace Tests\AppBundle\Service;

use AppBundle\Service\FindLastFortune;
use AppBundle\Service\PrintLastFortune;
use AppBundle\Service\PrintLastFortuneHandler;

class PrintLastFortuneHandlerTest extends \PHPUnit_Framework_TestCase
{
    const CONTENT = 'Why do witches burn?';

    private $findLastFortune;
    private $printLastFortuneHandler;

    protected function setUp()
    {
        $this->findLastFortune = $this->prophesize(FindLastFortune::class);
        $this->printLastFortuneHandler = new PrintLastFortuneHandler(
            $this->findLastFortune->reveal()
        );
    }

    /**
     * @test
     */
    public function it_prints_last_fortune()
    {
        $printLastFortune = new PrintLastFortune();
        $lastFortune = array(
            'content' => self::CONTENT,
        );

        $this->findLastFortune->findLast()->willReturn($lastFortune);

        self::assertSame($lastFortune, $this->printLastFortuneHandler->handle($printLastFortune));
    }
}
```

Let's run the tests:

```
vendor/bin/phpunit
```

They're telling us to create `PrintLastFortuneHandler`:

```php
<?php
// src/AppBundle/Service/PrintLastFortuneHandler.php

namespace AppBundle\Service;

class PrintLastFortuneHandler
{
    private $findLastFortune;

    public function __construct(FindLastFortune $findLastFortune)
    {
        $this->findLastFortune = $findLastFortune;
    }

    public function handle(PrintLastFortune $printLastFortune)
    {
        return $this->findLastFortune->findLast();
    }
}
```

This should fix this specific error:

```
vendor/bin/phpunit
```

Now our tests are telling us to create `FindLastFortune`:

```php
<?php
// src/AppBundle/Service/FindLastFortune.php

namespace AppBundle\Service;

interface FindLastFortune
{
    public function findLast();
}
```

Let's see if it did the trick:

```
vendor/bin/phpunit
```

Yes it did! To sum up what we've done in this section:

* we've created a `PrintLastFortune` use case which could be validating input parameter,
  for now it's empty and only serve us to convey intention (use case: print last fortunes)
* we've create a `PrintLastFortuneHandler` class that calls services which will
  do the actual logic
* we've created a `FindLastFortune` interface, its implementations will find the
  last fortune

## Wiring

We're going to use Doctrine DBAL to actually find all fortunes from a database.
This can be done by creating an implementation of `FindLastFortune`:

```php
<?php
// src/AppBundle/Service/Bridge/DoctrineDbalFindLastFortune.php

namespace AppBundle\Service\Bridge;

use AppBundle\Service\FindLastFortune;
use Doctrine\DBAL\Driver\Connection;

class DoctrineDbalFindLastFortune implements FindLastFortune
{
    private $connection;

    public function __construct(Connection $connection)
    {
        $this->connection = $connection;
    }

    public function findLast()
    {
        $queryBuilder = $this->connection->createQueryBuilder();
        $queryBuilder->select('*');
        $queryBuilder->from('fortune');
        $queryBuilder->orderBy('id', 'DESC');
        $queryBuilder->setMaxResults(1);
        $sql = $queryBuilder->getSql();
        $parameters = $queryBuilder->getParameters();
        $statement = $this->connection->prepare($sql);
        $statement->execute($parameters);

        return $statement->fetch();
    }
}
```

This was the last class we needed to write. We can now use `PrintLastFortune`
in our command:

```php
<?php
// src/AppBundle/Command/PrintLastFortuneCommand.php

namespace AppBundle\Command;

use AppBundle\Service\PrintLastFortune;
use AppBundle\Service\PrintLastFortuneHandler;
use Symfony\Component\Console\Command\Command;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class PrintLastFortuneCommand extends Command
{
    private $printLastFortuneHandler;

    public function __construct(PrintLastFortuneHandler $printLastFortuneHandler)
    {
        $this->printLastFortuneHandler = $printLastFortuneHandler;

        parent::__construct();
    }

    protected function configure()
    {
        $this->setName('print-last-fortune');
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $printLastFortune = new PrintLastFortune();

        $lastFortune = $this->printLastFortuneHandler->handle($printLastFortune);

        $output->writeln($lastFortune['content']);
    }
}
```

> **Note**: In the command, we extract Input parameters and options to put them
> in `PrintLastFortune` which is going to validate them. We then simply call
> `PrintLastFortuneHandler` to take care of the logic associated to `PrintLastFortune`.

Now all that's left to do is wire everything together using Dependency Injection:

```
# app/config/services.yml

services:
    # Commands
    app.print_last_fortune_command:
        class: 'AppBundle\Command\PrintLastFortuneCommand'
        arguments:
            - '@app.print_last_fortune_handler'
        tags:
            - { name: console.command }

    # Controllers
    app.api.fortune_controller:
        class: 'AppBundle\Controller\Api\FortuneController'
        arguments:
            - '@app.submit_new_fortune_handler'

    app.fortune_controller:
        class: 'AppBundle\Controller\FortuneController'
        arguments:
            - '@app.list_all_fortunes_handler'
            - '@twig'

    # Handlers
    app.list_all_fortunes_handler:
        class: 'AppBundle\Service\ListAllFortunesHandler'
        arguments:
            - '@app.find_all_fortunes'

    app.print_last_fortune_handler:
        class: 'AppBundle\Service\PrintLastFortuneHandler'
        arguments:
            - '@app.find_last_fortune'

    app.submit_new_fortune_handler:
        class: 'AppBundle\Service\SubmitNewFortuneHandler'
        arguments:
            - '@app.save_new_fortune'

    # Services
    app.find_all_fortunes:
        alias: app.bridge.doctrine_dbal_find_all_fortunes

    app.bridge.doctrine_dbal_find_all_fortunes:
        class: 'AppBundle\Service\Bridge\DoctrineDbalFindAllFortunes'
        arguments:
            - '@database_connection'

    app.find_last_fortune:
        alias: app.bridge.doctrine_dbal_find_last_fortune

    app.bridge.doctrine_dbal_find_last_fortune:
        class: 'AppBundle\Service\Bridge\DoctrineDbalFindLastFortune'
        arguments:
            - '@database_connection'

    app.save_new_fortune:
        alias: app.bridge.doctrine_dbal_save_new_fortune

    app.bridge.doctrine_dbal_save_new_fortune:
        class: 'AppBundle\Service\Bridge\DoctrineDbalSaveNewFortune'
        arguments:
            - '@database_connection'

    # Listeners
    app.json_request_content_listener:
        class: 'AppBundle\EventListener\JsonRequestContentListener'
        tags:
            - { name: kernel.event_listener, event: kernel.request, method: onKernelRequest }

    app.exception_listener:
        class: 'AppBundle\EventListener\ExceptionListener'
        tags:
            - { name: kernel.event_listener, event: kernel.exception, method: onKernelException }
```

Let's run the tests:

```
rm -rf var/cache/*
./bin/console doctrine:database:drop --force
./bin/console doctrine:database:create
bin/console doctrine:query:sql 'CREATE TABLE fortune (id SERIAL, content TEXT);'
vendor/bin/phpunit
```

All green! Let's add some fortunes:

```
php -S localhost:2501 -t web
curl -i -X POST localhost:2501/app.php/api/v1/fortunes -H 'Content-Type: application/json' -d '{"content":"I am sorry to have kept you waiting, but I am afraid my walk has become rather sillier recently"}'
curl -i -X POST localhost:2501/app.php/api/v1/fortunes -H 'Content-Type: application/json' -d '{"content":"Well you cannot expect to wield supreme executive power just because some watery tart threw a sword at you."}'
curl -i -X POST localhost:2501/app.php/api/v1/fortunes -H 'Content-Type: application/json' -d '{"content":"All right... all right... but apart from better sanitation, the medicine, education, wine, public order, irrigation, roads, a fresh water system, and public health ... what have the Romans ever done for us?"}'
```

We can now check our command:

```
bin/console print-last-fortune
```

This time instead of an empty line, we do get the last fortune.

## Conclusion

To create a new command, we need to:

* create a Command class
* register the command as a service, with a `console.command` tag

The command's logic is then up to us, it doesn't have to be done in a "Symfony"
way. For example we can:

* extract Input parameters and put them in a class that validates them
* pass the class to a handler that will call services to do the actual logic
* define our services as interfaces, and then create implementations to integrate
  them with third party libraries
