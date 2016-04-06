---
layout: post
title: The Ultimate Developer Guide to Symfony - API Example
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

In this article, we're going to put all this knowledge in practice by creating a
"fortune" project with an endpoint that allows us to submit new fortunes.

In the next articles we'll also create for this application:

* [a page that lists all fortunes](/2016/03/30/ultimate-symfony-web-example.html)
* [a command that prints the last fortune](/2016/04/06/ultimate-symfony-cli-example.html)

## Create the project

The first step is to create our project. For this example we'll use the
[Standard Edition](https://github.com/symfony/symfony-standard):

```
composer create-project symfony/framework-standard-edition fortune
```

This will ask us some configuration questions (e.g. database credentials), allowing
us to set up everything in one step.

> **Note**: Nothing prevents us from adding new libraries (e.g. [Assert](https://github.com/beberlei/assert)),
> replacing the ones provided by default (e.g. replacing [Doctrine](http://www.doctrine-project.org/projects/orm.html)
> with [Pomm](http://www.pomm-project.org/)) or remove the ones we don't need
> (e.g. [Swiftmailer](http://swiftmailer.org/) if we don't need emailing).

To begin with a clean slate we'll need to remove some things:

```
cd fortune
echo '' >> app/config/routing.yml
rm -rf src/AppBundle/Controller/* tests/AppBundle/Controller/* app/Resources/views/*
```

Then we're going to install PHPUnit locally:

```
composer require --dev phpunit/phpunit:5.2 --ignore-platform-reqs
```

We're now ready to begin.

## Create the Controller

We'll first start by writing a functional test for our new endpoint:

```php
<?php
// tests/AppBundle/Controller/Api/FortuneControllerTest.php

namespace Tests\AppBundle\Controller\Api;

use Symfony\Component\HttpFoundation\Request;

class FortuneControllerTest extends \PHPUnit_Framework_TestCase
{
    private $app;

    protected function setUp()
    {
        $this->app = new \AppKernel('test', false);
    }

    /**
     * @test
     */
    public function it_cannot_submit_fortunes_without_content()
    {
        $headers = array(
            'CONTENT_TYPE' => 'application/json',
        );
        $request = Request::create('/api/v1/fortunes', 'POST', array(), array(), array(), $headers, json_encode(array(
        )));

        $response = $this->app->handle($request);

        self::assertSame(422, $response->getStatusCode(), $response->getContent());
    }

    /**
     * @test
     */
    public function it_cannot_submit_fortunes_with_non_string_content()
    {
        $headers = array(
            'CONTENT_TYPE' => 'application/json',
        );
        $request = Request::create('/api/v1/fortunes', 'POST', array(), array(), array(), $headers, json_encode(array(
            'content' => 42,
        )));

        $response = $this->app->handle($request);

        self::assertSame(422, $response->getStatusCode(), $response->getContent());
    }

    /**
     * @test
     */
    public function it_submits_new_fortunes()
    {
        $headers = array(
            'CONTENT_TYPE' => 'application/json',
        );
        $request = Request::create('/api/v1/fortunes', 'POST', array(), array(), array(), $headers, json_encode(array(
            'content' => 'Hello',
        )));

        $response = $this->app->handle($request);

        self::assertSame(201, $response->getStatusCode(), $response->getContent());
    }
}
```

With functional tests, we're only interested in making sure all components play
well together, so checking the response status code (`201` is succesfully created,
`422` is a validation error) is sufficient.

> **Note**: `400 BAD REQUEST` is only used if there's a syntax error in the Request
> (e.g. invalid JSON).

Let's run the tests:

```
vendor/bin/phpunit
```

They fail, with a `404 NOT FOUND` response. That's because we don't have any
controllers, so let's fix that:

```php
<?php
// src/AppBundle/Controller/Api/FortuneController.php

namespace AppBundle\Controller\Api;

use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

class FortuneController
{
    public function submit(Request $request)
    {
        return new Response('', 201);
    }
}
```

Having a controller is no good without routing configuration:

```
# app/config/routing.yml

submit_new_fortunes_endpoint:
    path: /api/v1/fortunes
    defaults:
        _controller: app.api.fortune_controller:submit
    methods:
        - POST
```

In this configuration, `_controller` is set to call the `submit` method of the
`app.api.fortune_controller` service. Here's how to define this service:

```
# app/config/services.yml

services:
    app.api.fortune_controller:
        class: 'AppBundle\Controller\Api\FortuneController'
```

Now let's try again our tests:

```
rm -rf var/cache/test
vendor/bin/phpunit
```

> **Note**: We need to remove the cache to take into account the new configuration.

The last test (happy scenario) pass! We'll have to fix the first two ones (unhappy
scenario) later.

We can now call directly our endpoint:

```
php -S localhost:2501 -t web &
curl -i -X POST localhost:2501/app.php/api/v1/fortunes -H 'Content-Type: application/json' -d '{"content":"Nobody expects the spanish inquisition!"}'
killall -9 php
```

We should successfully get a `201 CREATED`.

## Create the logic

So now we have an endpoint that does nothing. Let's fix it by creating the logic.
Our first step will be to write a unit test for a class that will do a basic
validation of the input:

```php
<?php
// tests/AppBundle/Service/SubmitNewFortuneTest.php

namespace Tests\AppBundle\Service;

use AppBundle\Service\SubmitNewFortune;

class SubmitNewFortuneTest extends \PHPUnit_Framework_TestCase
{
    const CONTENT = "Look, matey, I know a dead parrot when I see one, and I'm looking at one right now.";

    /**
     * @test
     */
    public function it_has_a_content()
    {
        $submitNewFortune = new SubmitNewFortune(self::CONTENT);

        self::assertSame(self::CONTENT, $submitNewFortune->content);
    }

    /**
     * @test
     */
    public function it_fails_if_the_content_is_missing()
    {
        $this->expectException(\DomainException::class);

        new SubmitNewFortune(null);
    }

    /**
     * @test
     */
    public function it_fails_if_the_content_is_not_a_string()
    {
        $this->expectException(\DomainException::class);

        new SubmitNewFortune(42);
    }
}
```

> **Note**: You need PHPUnit 5.2 to be able to use `expectException`.

Our `SubmitNewFortune` will check that we submitted a stringy content. Let's run
the tests:

```
vendor/bin/phpunit
```

> **Note**: If we had used [phpspec](/2015/08/03/phpspec.html) to write our unit
> tests, it would have created an empty `SubmitNewFortune` class for us.
> There's nothing wrong with using [both PHPUnit and phpspec](/2015/09/23/phpunit-with-phpspec.html),
> (the first for functional tests and the second for unit tests).

The tests fail because the actual class doesn't exist yet. We need to write it:

```php
<?php
// src/AppBundle/Service/SubmitNewFortune.php

namespace AppBundle\Service;

class SubmitNewFortune
{
    public $content;

    public function __construct($content)
    {
        if (null === $content) {
            throw new \DomainException('Missing required "content" parameter', 422);
        }
        if (false === is_string($content)) {
            throw new \DomainException('Invalid "content" parameter: it must be a string', 422);
        }
        $this->content = $content;
    }
}
```

Let's run the tests again:

```
vendor/bin/phpunit
```

This time they pass.

Validating the input parameters isn't enough, we now need to execute some logic
to actually submit new quotes. This can be done in a class that handles `SubmitNewFortune`:

```php
<?php
// tests/AppBundle/Service/SubmitNewFortuneHandlerTest.php

namespace Tests\AppBundle\Service;

use AppBundle\Service\SaveNewFortune;
use AppBundle\Service\SubmitNewFortune;
use AppBundle\Service\SubmitNewFortuneHandler;

class SubmitNewFortuneHandlerTest extends \PHPUnit_Framework_TestCase
{
    const CONTENT = "It's just a flesh wound.";

    private $submitNewFortuneHandler;
    private $saveNewFortune;

    protected function setUp()
    {
        $this->saveNewFortune = $this->prophesize(SaveNewFortune::class);
        $this->submitNewFortuneHandler = new SubmitNewFortuneHandler(
            $this->saveNewFortune->reveal()
        );
    }

    /**
     * @test
     */
    public function it_submits_new_fortunes()
    {
        $submitNewFortune = new SubmitNewFortune(self::CONTENT);

        $this->saveNewFortune->save(array(
            'content' => self::CONTENT
        ))->shouldBeCalled();

        $this->submitNewFortuneHandler->handle($submitNewFortune);
    }
}
```

Let's run the tests:

```
vendor/bin/phpunit
```

They're telling us to create `SubmitNewFortuneHandler`:

```php
<?php
// src/AppBundle/Service/SubmitNewFortuneHandler.php

namespace AppBundle\Service;

class SubmitNewFortuneHandler
{
    private $saveNewFortune;

    public function __construct(SaveNewFortune $saveNewFortune)
    {
        $this->saveNewFortune = $saveNewFortune;
    }

    public function handle(SubmitNewFortune $submitNewFortune)
    {
        $newFortune = array(
            'content' => $submitNewFortune->content,
        );

        $this->saveNewFortune->save($newFortune);
    }
}
```

This should fix this specific error:

```
vendor/bin/phpunit
```

Now our tests are telling us to create `SaveNewFortune`:

```php
<?php
// src/AppBundle/Service/SaveNewFortune.php

namespace AppBundle\Service;

interface SaveNewFortune
{
    public function save(array $newFortune);
}
```

Let's see if it did the trick:

```
vendor/bin/phpunit
```

Yes it did! To sum up what we've done in this section:

* we've created a `SubmitNewFortune` class that contains all input parameters
  to submit a new fortune, and it validates them
* we've create a `SubmitNewFortuneHandler` class that uses parameters from
  `SubmitNewFortune` to call services which will do the actual logic
* we've created a `SaveNewFortune` interface, its implementations will save new
  fortunes

## Wiring

We're going to use Doctrine DBAL to actually save new fortunes in a database.
This can be done by creating an implementation of `SaveNewFortune`:

```php
<?php
// src/AppBundle/Service/Bridge/DoctrineDbalSaveNewFortune.php

namespace AppBundle\Service\Bridge;

use AppBundle\Service\SaveNewFortune;
use Doctrine\DBAL\Driver\Connection;

class DoctrineDbalSaveNewFortune implements SaveNewFortune
{
    private $connection;

    public function __construct(Connection $connection)
    {
        $this->connection = $connection;
    }

    public function save(array $newFortune)
    {
        $queryBuilder = $this->connection->createQueryBuilder();
        $queryBuilder->insert('fortune');
        $queryBuilder->setValue('content', '?');
        $queryBuilder->setParameter(0, $newFortune['content']);
        $sql = $queryBuilder->getSql();
        $parameters = $queryBuilder->getParameters();
        $statement = $this->connection->prepare($sql);
        $statement->execute($parameters);
    }
}
```

This was the last class we needed to write. We can now use `SubmitNewFortune`
in our controller:

```php
<?php
// src/AppBundle/Controller/Api/FortuneController.php

namespace AppBundle\Controller\Api;

use AppBundle\Service\SubmitNewFortune;
use AppBundle\Service\SubmitNewFortuneHandler;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

class FortuneController
{
    private $submitNewFortuneHandler;

    public function __construct(SubmitNewFortuneHandler $submitNewFortuneHandler)
    {
        $this->submitNewFortuneHandler = $submitNewFortuneHandler;
    }

    public function submit(Request $request)
    {
        $submitNewFortune = new SubmitNewFortune(
            $request->request->get('content')
        );
        $this->submitNewFortuneHandler->handle($submitNewFortune);

        return new Response('', 201);
    }
}
```

> **Note**: In the controller, we extract Request (input) parameters and put them
> in `SubmitNewFortune` which is going to validate them. We then simply call
> `SubmitNewFortuneHandler` to take care of the logic associated to `SubmitNewFortune`.

Now all that's left to do is wire everything together using Dependency Injection:

```
# app/config/services.yml

services:
    app.api.fortune_controller:
        class: 'AppBundle\Controller\Api\FortuneController'
        arguments:
            - '@app.submit_new_fortune_handler'

    app.submit_new_fortune_handler:
        class: 'AppBundle\Service\SubmitNewFortuneHandler'
        arguments:
            - '@app.save_new_fortune'

    app.save_new_fortune:
        alias: app.bridge.doctrine_dbal_save_new_fortune

    app.bridge.doctrine_dbal_save_new_fortune:
        class: 'AppBundle\Service\Bridge\DoctrineDbalSaveNewFortune'
        arguments:
            - '@database_connection'
```

Let's run the tests:

```
rm -rf var/cache/test
vendor/bin/phpunit
```

They currently fail with `500 INTERNAL SERVER ERROR`. To get an idea of what's
going on, we need to have a look at our logs:

```
grep CRITICAL var/logs/test.log | tail -n 1 # Get the last line containing "CRITICAL", which is often cause by 500
```

This is what we got:

```
[2016-03-24 19:31:32] request.CRITICAL: Uncaught PHP Exception DomainException: "Missing required "content" parameter" at /home/foobar/fortune/src/AppBundle/Service/SubmitNewFortune.php line 13 {"exception":"[object] (DomainException(code: 422): Missing required \"content\" parameter at /home/foobar/fortune/src/AppBundle/Service/SubmitNewFortune.php:13)"} []
```

It looks like we don't get any data in the `request` attribute from `Request`.
That's because PHP doesn't populate `$_POST` when we send JSON data. We can fix
it by creating an `EventListener` that will prepare the Request for us:

```php
<?php
// src/AppBundle/EventListener/JsonRequestContentListener.php

namespace AppBundle\EventListener;

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Event\GetResponseEvent;

/**
 * PHP does not populate $_POST with the data submitted via a JSON Request,
 * causing an empty $request->request.
 *
 * This listener fixes this.
 */
class JsonRequestContentListener
{
    public function onKernelRequest(GetResponseEvent $event)
    {
        $request = $event->getRequest();
        $hasBeenSubmited = in_array($request->getMethod(), array('PATCH', 'POST', 'PUT'), true);
        $isJson = (1 === preg_match('#application/json#', $request->headers->get('Content-Type')));
        if (!$hasBeenSubmited || !$isJson) {
            return;
        }
        $data = json_decode($request->getContent(), true);
        if (JSON_ERROR_NONE !== json_last_error()) {
            $event->setResponse(new Response('{"error":"Invalid or malformed JSON"}', 400, array('Content-Type' => 'application/json')));
        }
        $request->request->add($data ?: array());
    }
}
```

Our listener needs to be registered in the Dependency Injection Container:

```
# app/config/services.yml

services:
    app.api.fortune_controller:
        class: 'AppBundle\Controller\Api\FortuneController'
        arguments:
            - '@app.submit_new_fortune_handler'

    app.submit_new_fortune_handler:
        class: 'AppBundle\Service\SubmitNewFortuneHandler'
        arguments:
            - '@app.save_new_fortune'

    app.save_new_fortune:
        alias: app.bridge.doctrine_dbal_save_new_fortune

    app.bridge.doctrine_dbal_save_new_fortune:
        class: 'AppBundle\Service\Bridge\DoctrineDbalSaveNewFortune'
        arguments:
            - '@database_connection'

    app.json_request_content_listener:
        class: 'AppBundle\EventListener\JsonRequestContentListener'
        tags:
            - { name: kernel.event_listener, event: kernel.request, method: onKernelRequest }
```

This should fix our error:

```
rm -rf var/cache/test
vendor/bin/phpunit
grep CRITICAL var/logs/test.log | tail -n 1
```

We still get a `500`, but this time for the following reason:

```
[2016-03-24 19:36:09] request.CRITICAL: Uncaught PHP Exception Doctrine\DBAL\Exception\ConnectionException: "An exception occured in driver: SQLSTATE[08006] [7] FATAL:  database "fortune" does not exist" at /home/foobar/fortune/vendor/doctrine/dbal/lib/Doctrine/DBAL/Driver/AbstractPostgreSQLDriver.php line 85 {"exception":"[object] (Doctrine\\DBAL\\Exception\\ConnectionException(code: 0): An exception occured in driver: SQLSTATE[08006] [7] FATAL:  database \"fortune\" does not exist at /home/foobar/fortune/vendor/doctrine/dbal/lib/Doctrine/DBAL/Driver/AbstractPostgreSQLDriver.php:85, Doctrine\\DBAL\\Driver\\PDOException(code: 7): SQLSTATE[08006] [7] FATAL:  database \"fortune\" does not exist at /home/foobar/fortune/vendor/doctrine/dbal/lib/Doctrine/DBAL/Driver/PDOConnection.php:47, PDOException(code: 7): SQLSTATE[08006] [7] FATAL:  database \"fortune\" does not exist at /home/foobar/fortune/vendor/doctrine/dbal/lib/Doctrine/DBAL/Driver/PDOConnection.php:43)"} []
```

The database doesn't exist. It can be created with the following command, provided by Doctrine:

```
bin/console doctrine:database:create
```

Let's take this opportunity to also create the table:

```
bin/console doctrine:query:sql 'CREATE TABLE fortune (content TEXT);'
```

Let's re-run the tests:

```
vendor/bin/phpunit
```

Hooray! We can now submit new fortunes by calling our endpoint:

```
rm -rf var/cache/prod
php -S localhost:2501 -t web &
curl -i -X POST localhost:2501/app.php/api/v1/fortunes -H 'Content-Type: application/json' -d '{"content":"What... is the air-speed velocity of an unladen swallow?"}'
killall -9 php
```

We can see our fortunes in the database:

```
bin/console doctrine:query:sql 'SELECT * FROM fortune;'
```

We still have two failing tests though. That's because we don't catch our `DomainExceptions`.
This can be fixed in an `EventListener`:

```php
<?php
// src/AppBundle/EventListener/ExceptionListener.php

namespace AppBundle\EventListener;

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Event\GetResponseForExceptionEvent;

class ExceptionListener
{
    public function onKernelException(GetResponseForExceptionEvent $event)
    {
        $exception = $event->getException();
        if (!$exception instanceof \DomainException) {
            return;
        }
        $event->setResponse(new Response(json_encode(array(
            'error' => $exception->getMessage(),
        )), $exception->getCode(), array('Content-Type' => 'application/json')));
    }
}
```

It then needs to be registered as a service:

```
# app/config/services.yml

services:
    app.api.fortune_controller:
        class: 'AppBundle\Controller\Api\FortuneController'
        arguments:
            - '@app.submit_new_fortune_handler'

    app.submit_new_fortune_handler:
        class: 'AppBundle\Service\SubmitNewFortuneHandler'
        arguments:
            - '@app.save_new_fortune'

    app.save_new_fortune:
        alias: app.bridge.doctrine_dbal_save_new_fortune

    app.bridge.doctrine_dbal_save_new_fortune:
        class: 'AppBundle\Service\Bridge\DoctrineDbalSaveNewFortune'
        arguments:
            - '@database_connection'

    app.json_request_content_listener:
        class: 'AppBundle\EventListener\JsonRequestContentListener'
        tags:
            - { name: kernel.event_listener, event: kernel.request, method: onKernelRequest }

    app.exception_listener:
        class: 'AppBundle\EventListener\ExceptionListener'
        tags:
            - { name: kernel.event_listener, event: kernel.exception, method: onKernelException }
```

Finally we run the tests:

```
rm -rf var/cache/test
vendor/bin/phpunit
```

All green!

## Conclusion

To create a new endpoint, we need to:

* create a Controller class
* configure its routing
* register the controller as a service

We might need to create some event listeners (to populate `$request->request`
when receiving JSON content, or to convert exceptions to responses).

The endpoint's logic is then up to us, it doesn't have to be done in a "Symfony"
way. For example we can:

* extract Request parameters and put them in a class that validates them
* pass the class to a handler that will call services to do the actual logic
* define our services as interfaces, and then create implementations to integrate
  them with third party libraries

You can find the code on Github: [Fortune - API example](https://github.com/gnugat-examples/fortune/tree/api-example)
