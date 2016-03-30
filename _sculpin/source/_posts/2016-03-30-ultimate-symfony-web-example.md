---
layout: post
title: The Ultimate Developer Guide to Symfony - Web Example
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
"fortune" project with [an endpoint that allows us to submit new fortunes](/2016/03/24/ultimate-symfony-api-example.html).

In this article, we're going to continue the "fortune" project by creating a page
that lists all fortunes.

> **Note**: To start with the same code, use the following repository:
>
> ```
> git clone https://github.com/gnugat-examples/fortune.git
> cd fortune
> composer install -o --ignore-platform-reqs
> git checkout api-example
> git chekcout -b web-example
> ```

## Create the Controller

We'll first start by writing a functional test for our new endpoint:

```php
<?php
// tests/AppBundle/Controller/FortuneControllerTest.php

namespace Tests\AppBundle\Controller;

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
    public function it_lists_all_fortunes()
    {
        $request = Request::create('/');

        $response = $this->app->handle($request);

        self::assertSame(200, $response->getStatusCode(), $response->getContent());
    }
}
```

Just like for our endpoint, we're only interested in checking the status code
of the response (`200` is successful response).

Let's run the tests:

```
vendor/bin/phpunit
```

They fail, with a `404 NOT FOUND` response. That's because we don't have any
controllers, so let's fix that:

```php
<?php
// src/AppBundle/Controller/FortuneController.php

namespace AppBundle\Controller;

use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

class FortuneController
{
    public function listAll(Request $request)
    {
        return new Response('', 200);
    }
}
```

After creating a controller, the next step is to configure its route:

```
# app/config/routing.yml

submit_new_fortunes_endpoint:
    path: /api/v1/fortunes
    defaults:
        _controller: app.api.fortune_controller:submit
    methods:
        - POST

list_all_fortunes_page:
    path: /
    defaults:
        _controller: app.fortune_controller:listAll
    methods:
        - GET
```

In this configuration, `_controller` is set to call the `listAll` method of the
`app.fortune_controller` service. Here's how to define this service:

```
# app/config/services.yml

services:
    # Controllers
    app.api.fortune_controller:
        class: 'AppBundle\Controller\Api\FortuneController'
        arguments:
            - '@app.submit_new_fortune_handler'

    app.fortune_controller:
        class: 'AppBundle\Controller\FortuneController'

    # Handlers
    app.submit_new_fortune_handler:
        class: 'AppBundle\Service\SubmitNewFortuneHandler'
        arguments:
            - '@app.save_new_fortune'

    # Services
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

Now let's try again our tests:

```
rm -rf var/cache/test
vendor/bin/phpunit
```

> **Note**: Everytime the configuration changes, we need to remove the cache.

The test suite is now green. Let's start the server:


```
rm -rf var/cache/prod
php -S localhost:2501 -t web
```

We can now visit our page: [http://localhost:2501/app.php/](http://localhost:2501/app.php/)

We should successfully get a blank page.

## Create the logic

So now we have an empty page. Let's fix it by creating a use case to list all
fortunes:

```php
<?php
// tests/AppBundle/Service/ListAllFortunesTest.php

namespace Tests\AppBundle\Service;

use AppBundle\Service\ListAllFortunes;

class ListAllFortunesTest extends \PHPUnit_Framework_TestCase
{
    /**
     * @test
     */
    public function it_has_no_parameters()
    {
        $listAllFortunes = new ListAllFortunes();
    }
}
```

We can now run the tests:

```
vendor/bin/phpunit
```

They fail because we need to create the actual class:

```php
<?php
// src/AppBundle/Service/ListAllFortunes.php

namespace AppBundle\Service;

class ListAllFortunes
{
}
```

> **Note**: Currently the use case class has no parameters to validate.
> If new requirements come up with the need for some parameters, we're going
> to be able to heck them here.

This should fix the issue:

```
vendor/bin/phpunit
```

Now let's create Handler that will list all fortunes:

```php
<?php
// tests/AppBundle/Service/ListAllFortunesHandlerTest.php

namespace Tests\AppBundle\Service;

use AppBundle\Service\FindAllFortunes;
use AppBundle\Service\ListAllFortunes;
use AppBundle\Service\ListAllFortunesHandler;

class ListAllFortunesHandlerTest extends \PHPUnit_Framework_TestCase
{
    const CONTENT = "It's just a flesh wound.";

    private $listAllFortunesHandler;
    private $findAllFortunes;

    protected function setUp()
    {
        $this->findAllFortunes = $this->prophesize(FindAllFortunes::class);
        $this->listAllFortunesHandler = new ListAllFortunesHandler(
            $this->findAllFortunes->reveal()
        );
    }

    /**
     * @test
     */
    public function it_submits_new_fortunes()
    {
        $listAllFortunes = new ListAllFortunes();

        $this->findAllFortunes->findAll()->shouldBeCalled();

        $this->listAllFortunesHandler->handle($listAllFortunes);
    }
}
```

Let's run the tests:

```
vendor/bin/phpunit
```

They're telling us to create `ListAllFortunesHandler`:

```php
<?php
// src/AppBundle/Service/ListAllFortunesHandler.php

namespace AppBundle\Service;

class ListAllFortunesHandler
{
    private $findAllFortunes;

    public function __construct(FindAllFortunes $findAllFortunes)
    {
        $this->findAllFortunes = $findAllFortunes;
    }

    public function handle(ListAllFortunes $listAllFortunes)
    {
        return $this->findAllFortunes->findAll();
    }
}
```

This should fix this specific error:

```
vendor/bin/phpunit
```

Now our tests are telling us to create `FindAllFortunes`:

```php
<?php
// src/AppBundle/Service/FindAllFortunes.php

namespace AppBundle\Service;

interface FindAllFortunes
{
    public function findAll();
}
```

Let's see if it did the trick:

```
vendor/bin/phpunit
```

Yes it did! To sum up what we've done in this section:

* we've created a `ListAllFortunes` use case which could be validating input parameter,
  for now it's empty and only serve us to convey intention (use case: list all fortunes)
* we've create a `ListAllFortunesHandler` class that call services which will
  do the actual logic
* we've created a `FindAllFortunes` interface, its implementations will find all
  fortunes

## Wiring

We're going to use Doctrine DBAL to actually find all fortunes from a database.
This can be done by creating an implementation of `FindAllFortunes`:

```php
<?php
// src/AppBundle/Service/Bridge/DoctrineDbalFindAllFortunes.php

namespace AppBundle\Service\Bridge;

use AppBundle\Service\FindAllFortunes;
use Doctrine\DBAL\Driver\Connection;

class DoctrineDbalFindAllFortunes implements FindAllFortunes
{
    private $connection;

    public function __construct(Connection $connection)
    {
        $this->connection = $connection;
    }

    public function findAll()
    {
        $queryBuilder = $this->connection->createQueryBuilder();
        $queryBuilder->select('*');
        $queryBuilder->from('fortune');
        $sql = $queryBuilder->getSql();
        $parameters = $queryBuilder->getParameters();
        $statement = $this->connection->prepare($sql);
        $statement->execute($parameters);

        return $statement->fetchAll();
    }
}
```

This was the last class we needed to write. We can now use `ListAllFortunes`
in our controller:

```php
<?php
// src/AppBundle/Controller/FortuneController.php

namespace AppBundle\Controller;

use AppBundle\Service\ListAllFortunes;
use AppBundle\Service\ListAllFortunesHandler;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

class FortuneController
{
    private $listAllFortunesHandler;

    public function __construct(ListAllFortunesHandler $listAllFortunesHandler)
    {
        $this->listAllFortunesHandler = $listAllFortunesHandler;
    }

    public function listAll(Request $request)
    {
        $listAllFortunes = new ListAllFortunes(
        );
        $fortunes = $this->listAllFortunesHandler->handle($listAllFortunes);

        return new Response('', 200);
    }
}
```

> **Note**: In the controller, we extract Request (input) parameters and put them
> in `ListAllFortunes` which is going to validate them. We then simply call
> `ListAllFortunesHandler` to take care of the logic associated to `ListAllFortunes`.

Now all that's left to do is wire everything together using Dependency Injection:

```
# app/config/services.yml

services:
    # Controllers
    app.api.fortune_controller:
        class: 'AppBundle\Controller\Api\FortuneController'
        arguments:
            - '@app.submit_new_fortune_handler'

    app.fortune_controller:
        class: 'AppBundle\Controller\FortuneController'
        arguments:
            - '@app.list_all_fortunes_handler'

    # Handlers
    app.list_all_fortunes_handler:
        class: 'AppBundle\Service\ListAllFortunesHandler'
        arguments:
            - '@app.find_all_fortunes'

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
./bin/console doctrine:database:drop --force
./bin/console doctrine:database:create
bin/console doctrine:query:sql 'CREATE TABLE fortune (content TEXT);'
rm -rf var/cache/test
vendor/bin/phpunit
```

All green!

## View

If we start the server and check the page, it's going to be blank. That's because
in our controlller we create a Response with empty content. Let's improve this situation:

```php
<?php
// src/AppBundle/Controller/FortuneController.php

namespace AppBundle\Controller;

use AppBundle\Service\ListAllFortunes;
use AppBundle\Service\ListAllFortunesHandler;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

class FortuneController
{
    private $listAllFortunesHandler;

    public function __construct(ListAllFortunesHandler $listAllFortunesHandler)
    {
        $this->listAllFortunesHandler = $listAllFortunesHandler;
    }

    public function listAll(Request $request)
    {
        $listAllFortunes = new ListAllFortunes(
        );
        $fortunes = $this->listAllFortunesHandler->handle($listAllFortunes);
        $fortunesHtml = '';
        foreach ($fortunes as $fortune) {
            $fortunesHtml .= "<li>{$fortune['content']}</li>\n";
        }
        $html =<<<HTML
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Fortunes</title>
</head>
<body>
    <ul>
        $fortunesHtml
    </ul>
</body>
HTML
        ;

        return new Response($html, 200);
    }
}
```

Let's start the server:


```
rm -rf var/cache/prod
php -S localhost:2501 -t web
```

In order to see a list of fortunes, we first need to submit some! We can use our
endpoint for this purpose:

```
curl -i -X POST localhost:2501/app.php/api/v1/fortunes -H 'Content-Type: application/json' -d '{"content":"I came here to have an argument!"}'
curl -i -X POST localhost:2501/app.php/api/v1/fortunes -H 'Content-Type: application/json' -d '{"content":"Has not got as much spam in it as spam egg sausage and spam, has it?"}'
curl -i -X POST localhost:2501/app.php/api/v1/fortunes -H 'Content-Type: application/json' -d '{"content":"The Castle of aaarrrrggh"}'
```

We can now visit our page: [http://localhost:2501/app.php/](http://localhost:2501/app.php/)

While it seems a bit plain (a bit of CSS, javascript and more HTML wouldn't be
too much), we do see a list of all fortunes.

Controllers shouldn't contain any "view" logic, let's push it to a template using
[Twig](http://twig.sensiolabs.org/):

{% verbatim %}
```
{# app/Resources/views/list-all-fortunes.html.twig #}
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>Fortunes</title>
</head>
<body>
    <ul>
        {% for fortune in fortunes %}
        <li>{{ fortune.content }}</li>
        {% endfor %}
    </ul>
</body>
```
{% endverbatim %}

We now need to use Twig in the controller:

```php
<?php
// src/AppBundle/Controller/FortuneController.php

namespace AppBundle\Controller;

use AppBundle\Service\ListAllFortunes;
use AppBundle\Service\ListAllFortunesHandler;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

class FortuneController
{
    private $listAllFortunesHandler;
    private $twig;

    public function __construct(
        ListAllFortunesHandler $listAllFortunesHandler,
        \Twig_Environment $twig
    ) {
        $this->listAllFortunesHandler = $listAllFortunesHandler;
        $this->twig = $twig;
    }

    public function listAll(Request $request)
    {
        $listAllFortunes = new ListAllFortunes(
        );
        $fortunes = $this->listAllFortunesHandler->handle($listAllFortunes);
        $html = $this->twig->render('::list-all-fortunes.html.twig', array(
            'fortunes' => $fortunes,
        ));

        return new Response($html, 200);
    }
}
```

> **Note**: The first argument of `render` is the "path" to the view. This path
> contains 3 parts, separated by colons (`:`):
>
> * the first part is the bundle name (by default it's `AppBundle` so we don't need to provide it)
> * the second one is the directory from `Resources/views` (in our case it's at the root so we don't need to provide it)
> * the template file name
>
> Some other path example: `FortuneBundle:Fortunes/List:all.html.twig`, etc.
>
> The second argument is an array which associates Twig variable names to their values,
> in our case we're going to have access to a `fortunes` variable in our template,
> which is going to be the content of the `$fortunes` variable from our controller.

In order to get Twig injected in our controller, we'll update it's service configuration:

```
# app/config/services.yml

services:
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

Since we changed the configuration, we'll need to clear the cache:

```
rm -rf var/cache/prod
```

Finally we can visit again our page: [http://localhost:2501/app.php/](http://localhost:2501/app.php/).

Let's run our test suite one last time:

```
rm -rf var/cache/test
vendor/bin/phpunit
```

Everything is still green!

## Conclusion

To create a new page, we need to:

* create a Controller class
* configure its routing
* register the controller as a service

The page's logic is then up to us, it doesn't have to be done in a "Symfony"
way. For example we can:

* extract Request parameters and put them in a class that validates them
* pass the class to a handler that will call services to do the actual logic
* define our services as interfaces, and then create implementations to integrate
  them with third party libraries

Finally to display the result we need to create a template file and call a
templating engine, such as Twig, from our controller.
