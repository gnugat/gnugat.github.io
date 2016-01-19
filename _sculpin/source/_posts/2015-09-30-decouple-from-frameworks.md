---
layout: post
title: Decouple from Frameworks
tags:
    - decoupling
    - symfony
    - phpspec
    - phpunit
    - command bus
---

Frameworks solve infrastructure problems, for example how to create a HTTP or CLI application.
While necessary, those concerns don't add any value to your project: the business
need will not be fulfilled by creating an empty application.

As always, different responsibilities mean also different reasons to change: frameworks
have a history of Backward Compatibility (BC) breaks and they do so regardless of your
project.

Take for example [Symfony](http://symfony.com/): it only started to follow [Semantic Versioning](http://semver.org/)
from version 2.3. The upgrade to version 3 has been made easier by allowing developers
to know what was deprecated, but the removal of those features still means a lot of
work in your application.
The arrival of the [new standard PSR-7](http://www.php-fig.org/psr/psr-7/) brings
a lot of questions on the future of Symfony: for now it [allows to choose](http://symfony.com/blog/psr-7-support-in-symfony-is-here)
between `symfony/http-foundation` and `psr/http-message`, but if Symfony doesn't
want to fall back behind ([Zend 3 is fully based on PSR-7](http://framework.zend.com/blog/announcing-the-zend-framework-3-roadmap.html))
it might have to introduce another big BC break (event listeners with the Request
and Response [are not possible the way they are now with PSR-7](http://evertpot.com/psr-7-issues/)).

Migrating Symfony applications (from symfony1, from symfony 2.0, etc) is so hard
that it is a business on its own.

Does that mean that we shouldn't use any frameworks? Should we just don't care and
embrace fully frameworks?

This article will explain how to avoid both extremes, by decoupling from the framework.
It can be done by restricting the framework to its infrastructure responsibilities
(HTTP, CLI), by only using its entry points (Controller, Command) and by using
the Command Bus pattern.

## Fortune: our example

We're going to build part of a [fortune](https://en.wikipedia.org/wiki/Fortune_%28Unix%29)
application for our example, more precisely we're going to build an endpoint allowing us to
submit quotes.

To do so, we'll bootstrap a symfony application using the [Empty Edition](https://github.com/gnugat/symfony-empty-edition):

    composer create-project gnugat/symfony-empty-edition fortune
    cd fortune

We'll need to install our test frameworks:

    composer require --dev phpunit/phpunit
    composer require --dev phpspec/phpspec

Then add them to our test script:

```
#!/usr/bin/env sh

# bin/test.sh

echo ''
echo '// Building test environment'

rm -rf app/cache/test app/logs/*test.log
composer --quiet --no-interaction install --optimize-autoloader  > /dev/null
php app/console --env=test --quiet cache:clear

echo ''
echo ' [OK] Test environment built'
echo ''

vendor/bin/phpspec --format=dot && vendor/bin/phpunit
```

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

## Request listener

Our endpoint will receive JSON encoded content. PHP does not populate `$_POST` with
this data, causing an empty `$request->request`. We can create an event listener
to fix this issue:

```php
<?php
// src/AppBundle/EventListener/JsonRequestListener.php

namespace AppBundle\EventListener;

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Event\GetResponseEvent;

class JsonRequestListener
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

This logic is infrastructure related, so it makes sense to keep it in `AppBundle`.

To enable it, configure it in the Dependency Injection Container:

```
# app/config/services/event_listener.yml

services:
    app.json_request_listener:
        class: AppBundle\EventListener\JsonRequestListener
        tags:
            - { name: kernel.event_listener, event: kernel.request, method: onKernelRequest }
```

We also need to make sure files in `app/config/services` are imported:

```php
<?php
// app/config/importer.php

use Symfony\Component\Finder\Finder;

$finder = new Finder();
$files = $finder->files()->name('*.yml')->in(__DIR__.'/services');
foreach ($files as $file) {
    $loader->import($file->getRealpath());
}
```

## Controller

Our first step will be to describe how the endpoint should work, with a test:

```php
<?php
// tests/AppBundle/Controller/QuoteControllerTest.php

namespace tests\AppBundle\Controller;

use AppKernel;
use PHPUnit_Framework_TestCase;
use Symfony\Component\HttpFoundation\Request;

class QuoteControllerTest extends PHPUnit_Framework_TestCase
{
    private $app;

    protected function setUp()
    {
        $this->app = new AppKernel('test', false);
        $this->app->boot();
    }

    /**
     * @test
     */
    public function it_submits_a_new_quote()
    {
        $headers = array('CONTENT_TYPE' => 'application/json');
        $request = Request::create('/v1/quotes', 'POST', array(), array(), array(), $headers, json_encode(array(
            'quote' => 'Nobody expects the spanish inquisition',
        )));

        $response = $this->app->handle($request);

        self::assertSame(201, $response->getStatusCode(), $response->getContent());
    }
}
```

> **Note**: Testing only the status code is called "Smoke Testing" and is a very
> efficient way to check if the application is broken.
> Testing the content would be tedious and would make our test fragile as it might change often.

Let's run it:

    ./bin/test.sh

The tests fail because the controller doesn't exist. Let's fix that:

```php
<?php
// src/AppBundle/Controller/QuoteController.php

namespace AppBundle\Controller;

use Acme\Fortune\Quote\SubmitNewQuote;
use Acme\Fortune\Quote\SubmitNewQuoteHandler;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

class QuoteController
{
    private $submitNewQuoteHandler;

    public function __construct(SubmitNewQuoteHandler $submitNewQuoteHandler)
    {
        $this->submitNewQuoteHandler = $submitNewQuoteHandler;
    }

    public function submitNewAction(Request $request)
    {
        $sumbitNewQuote = new SubmitNewQuote(
            $request->request->get('quote')
        );
        $newQuote = $this->submitNewQuoteHandler->handle($sumbitNewQuote);

        return new Response(json_encode($newQuote), 201, array('Content-Type' => 'application/json'));
    }
}
```

Now we need to configure the controller as a service:

```
# app/config/services/controller.yml

services:
    app.quote_controller:
        class: AppBundle\Controller\QuoteController
        arguments:
            - "@app.submit_new_quote_handler"
```

Then we need to configure the route:

```
# app/config/routings/quote.yml

submit_new_quote:
    path: /v1/quotes
    defaults:
        _controller: app.quote_controller:submitNew
    methods:
        - POST
```

This file needs to be imported:

```
# app/config/routing.yml

quote:
    resource: routings/quote.yml
```

Finally we can run the test again:

    ./bin/test.sh

It now fails for a different reason: `SubmitNewQuote` and its handler class don't exist.

## Command (from CommandBus)

`SubmitNewQuote` is a Data Transfer Object (DTO): its responsibility is to wrap
input parameters in a well named class (in this case a class that describes the action intended).
It's also the best place to do some basic validation on the input parameters.

> **Note**: In the Command Bus pattern, `SubmitNewQuote` would be a Command (different from the CLI Command).

We'll write a test for this, but first we'll bootstrap the test class:

    vendor/bin/phpspec describe 'Acme\Fortune\Quote\SubmitNewQuote'

Now we can decribe the different validation rules:

```php
<?php
// spec/Acme/Fortune/Quote/SubmitNewQuoteSpec.php

namespace spec\Acme\Fortune\Quote;

use PhpSpec\ObjectBehavior;

class SubmitNewQuoteSpec extends ObjectBehavior
{
    const QUOTE = 'Nobody expects the spanish inquisition';

    function it_fails_if_required_quote_parameter_is_missing()
    {
        $this->beConstructedWith(null);

        $this->shouldThrow('Acme\Fortune\Exception\ValidationFailedException')->duringInstantiation();
    }

    function it_fails_if_quote_parameter_is_empty()
    {
        $this->beConstructedWith('');

        $this->shouldThrow('Acme\Fortune\Exception\ValidationFailedException')->duringInstantiation();
    }
}
```

> **Note**: Since this class has nothing to do with Symfony, we don't put it in `AppBundle`.
> By keeping it in its own namespace, we protect it from framework directory tree changes,
> for example before `AppBundle` the norm was `Acme\FortuneBundle`. We also allow ourselves
> to move it to another framework (e.g. Laravel, Zend, etc).

Let's run the tests:

    ./bin/test.sh

It fails because the exception doesn't exist yet:

```php
<?php
// src/Acme/Fortune/Exception/ValidationFailedException.php

namespace Acme\Fortune\Exception;

class ValidationFailedException extends FortuneException
{
}
```

We're making it a sub type of `FortuneException`: that way we can catch all exceptions
related to our code (all other exceptions can be considered as Internal Server Errors).

```php
<?php
// src/Acme/Fortune/Exception/FortuneException.php

namespace Acme\Fortune\Exception;

use DomainException;

class FortuneException extends DomainException
{
}
```

Now we need to create the Command:

```php
<?php
// src/Acme/Fortune/Quote/SubmitNewQuote.php

namespace Acme\Fortune\Quote;

use Acme\Fortune\Exception\ValidationFailedException;

class SubmitNewQuote
{
    public function __construct($quote)
    {
        if (null === $quote) {
            throw new ValidationFailedException('Missing required "quote" parameter');
        }
        if ('' === $quote) {
            throw new ValidationFailedException('Invalid "quote" parameter: must not be empty');
        }
        $this->quote = (string) $quote;
    }
}
```

Running the tests again:

    ./bin/test.sh

Everything seems fine.

## Exception listener

Instead of catching exceptions in our controllers we can create an event listener:

```php
<?php
// src/AppBundle/EventListener/FortuneExceptionListener.php

namespace AppBundle\EventListener;

use Symfony\Component\HttpKernel\Event\GetResponseForExceptionEvent;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Event\GetResponseEvent;

class FortuneExceptionListener
{
    public function onKernelException(GetResponseForExceptionEvent $event)
    {
        $exception = $event->getException();
        if (!$exception instanceof FortuneException) {
            return;
        }
        $content = json_encode(array('error' => $exception->getMessage()));
        $statusCode = Response::HTTP_UNPROCESSABLE_ENTITY;
        $event->setResponse(new Response($content, $statusCode, array('Content-Type' => 'application/json')));
    }
}
```

This lowers the risk of forgetting to catch an exception and it also keeps our controller slim.

Let's enable it in the DIC:

```
# app/config/services/event_listener.yml

services:
    app.fortune_exception_listener:
        class: AppBundle\EventListener\FortuneExceptionListener
        tags:
            - { name: kernel.event_listener, event: kernel.exception, method: onKernelException }

    app.json_request_listener:
        class: AppBundle\EventListener\JsonRequestListener
        tags:
            - { name: kernel.event_listener, event: kernel.request, method: onKernelRequest }
```

## Command Handler

`SubmitNewQuoteHandler`'s responsibility is to validate `SubmitNewQuote` data against
business rules (e.g. no quote duplicates, author must exist, etc) and to call the
appropriate services to process it.
Reading its code feels like reading the details of a use case:

> To handle the submission of a new quote,
> we need to generate a unique identifier
> and then we need to save the new quote.

Let's bootstrap its test:

    vendor/bin/phpspec describe 'Acme\Fortune\Quote\SubmitNewQuoteHandler'

Then edit the test:

```php
<?php
// spec/Acme/Fortune/Quote/SubmitNewQuoteHandlerSpec.php

namespace spec\Acme\Fortune\Quote;

use Acme\Fortune\Quote\SubmitNewQuote;
use Acme\Fortune\Quote\Service\SaveNewQuote;
use Acme\Fortune\Quote\Service\UniqueIdentifierGenerator;
use PhpSpec\ObjectBehavior;

class SubmitNewQuoteHandlerSpec extends ObjectBehavior
{
    const ID = '921410e8-eb98-4f99-ba98-055d46980511';
    const QUOTE = 'Nobody expects the spanish inquisition!';

    function let(SaveNewQuote $saveNewQuote, UniqueIdentifierGenerator $uniqueIdentifierGenerator)
    {
        $this->beConstructedWith($saveNewQuote, $uniqueIdentifierGenerator);
    }

    function it_saves_new_quote(SaveNewQuote $saveNewQuote, UniqueIdentifierGenerator $uniqueIdentifierGenerator)
    {
        $submitNewQuote = new SubmitNewQuote(self::QUOTE);
        $quote = array(
            'id' => self::ID,
            'quote' => self::QUOTE,
        );

        $uniqueIdentifierGenerator->generate()->willReturn(self::ID);
        $saveNewQuote->save($quote)->shouldBeCalled();

        $this->handle($submitNewQuote)->shouldBe($quote);
    }
}
```

Let's run the tests:

    ./bin/test.sh

After generating interfaces for `SaveNewQuote` and `UniqueIdentifierGenerator`
and after bootstrapping the code for `SubmitNewQuoteHandler`, the test will fail
because we need to complete it:

```php
<?php
// src/Acme/Fortune/Quote/SubmitNewQuoteHandler.php

namespace Acme\Fortune\Quote;

use Acme\Fortune\Quote\Service\SaveNewQuote;
use Acme\Fortune\Quote\Service\UniqueIdentifierGenerator;

class SubmitNewQuoteHandler
{
    private $saveNewQuote;
    private $uniqueIdentifierGenerator;

    public function __construct(SaveNewQuote $saveNewQuote, UniqueIdentifierGenerator $uniqueIdentifierGenerator)
    {
        $this->saveNewQuote = $saveNewQuote;
        $this->uniqueIdentifierGenerator = $uniqueIdentifierGenerator;
    }

    public function handle(SubmitNewQuote $sumbitNewQuote)
    {
        $quote = array(
            'id' => $this->uniqueIdentifierGenerator->generate(),
            'quote' => $sumbitNewQuote->quote,
        );
        $this->saveNewQuote->save($quote);

        return $quote;
    }
}
```

Now we can configure the service:

```php
# app/config/services/quote.yml

services:
    app.submit_new_quote_handler:
        class: Acme\Fortune\Quote\SubmitNewQuoteHandler
        arguments:
            - "@app.save_new_quote"
            - "@app.unique_identifier_generator"
```

Finally can run the tests one last time:

    ./bin/test.sh

Allmost green!

They fail because `app.save_new_quote` and `app.unique_identifier_generator` don't
exist yet. They will be the topic of another article ;) .

## Conclusion

By restricting frameworks to their entry points (Controllers, Commands, etc) and
using the Command Bus to define our project entry points (domain boundaries) we
are able to decouple from the framework, allowing us to restrict the impact of BC breaks.

Of course, all projects are different and this solution might not be possible everywhere.
RAD development is a robust solution for web agencies, especially if they are chosen
to bootstrap a project as fast as possible and then need to pass the project over
to their customer after a short period.

On the other hand some companies are creating projects they will have to maintain
for decades and those are also in need of delivering a first version early.
Decoupling from the framework isn't something that slows down development, and there
are ways to still release early (e.g. define Minimum Valuable Product and deliver
small features iterations by iterations).

> **Note**: There are a couple of bundles that provides Symfony with a Command Bus, among them:
>
> * [Tactician](/2015/09/09/tactician.html)
> * [SimpleBus](/2015/08/04/simple-bus.html)

If you're interrested on the subject, here's some resources:

* The framework as an implementation detail
  ([slides](http://www.slideshare.net/marcello.duarte/the-framework-as-an-implementation-detail)
  and [video](https://www.youtube.com/watch?v=0L_9NutiJlc)),
  by [Marcello Duarte](http://marcelloduarte.net/)
  and [Konstantin Kudryashov](http://everzet.com/)
* [Framework bound](https://blog.8thlight.com/uncle-bob/2014/05/11/FrameworkBound.html),
  by [Robert Cecil Martin](https://sites.google.com/site/unclebobconsultingllc/)
* [Decoupling the Framework](http://kristopherwilson.com/2013/11/27/decoupling-the-framework/),
  by [Kristopher Wilson](https://twitter.com/mrkrstphr)

> **Reference**: <a class="button button-reference" href="/2015/08/03/phpspec.html">see the phpspec reference article</a>
