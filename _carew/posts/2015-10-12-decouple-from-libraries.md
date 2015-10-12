---
layout: post
title: Decouple from Libraries
tags:
    - decoupling
    - phpspec
    - phpunit
    - guzzle
    - inversion of control
---

Libraries are similar to frameworks: they solve infrastructure problems (e.g.
requesting remote endpoints or querying databases). They also don't directly
add any value to our projects: the business need will not be fulfilled by
connecting to a database.

They also share the same Backward Compatibility (BC) break issue, since they will
change to solve their own concerns, regardless of our projects.

Here's a true story with [Guzzle](http://guzzle.readthedocs.org/en/latest/): we
started to use version 2 in our project and spread direct calls to it in different places.
After a while we've decided to use [Flysystem](http://flysystem.thephpleague.com/)
and its [SDK for Amazon S3](http://aws.amazon.com/sdkforphp) but we had a problem:
it required Guzzle 3.
This means tracking down every usage of Guzzle in the project and adapting the
calls to the new version. It's a dawnting task, especially when the project doesn't
have strong enough tests.

Later on, when Amazon S3 SDK stabilized, it started to require Guzzle 5...

[![Screaming with anger](http://i0.kym-cdn.com/photos/images/newsfeed/000/000/578/1234931504682.jpg)](http://knowyourmeme.com/memes/rage-guy-fffffuuuuuuuu)

Does that mean that we shouldn't use any libraries? Should we just don't care and
continue to use them in the same way?

This article will explain how to avoid both extremes, by decoupling from the library.
It can be done by using the Inversion of Control principle: instead of relying
on the library we rely on interfaces and provide an implementation that uses the library.

## Fortune: our example

In {{ link('posts/2015-09-30-decouple-from-frameworks.md', 'the previous article') }},
we started to create an endpoint allowing us to subit new quotes for a
[fortune](https://en.wikipedia.org/wiki/Fortune_%28Unix%29) application.

We're now going to create a SDK for it:

    mkdir fortune-sdk
    cd fortune-sdk

To do so, we'll create the `composer.json` file:

```
{
    "name": "acme/fortune-sdk",
    "description": "A PHP SDK for Fortune",
    "type": "library",
    "license": "MIT",
    "autoload": {
        "psr-4": {
            "Acme\\FortuneSdk\\": "src/Acme/FortuneSdk"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "Acme\\FortuneSdk\\Fixtures\\": "fixtures",
            "Acme\\FortuneSdk\\Tests\\": "tests"
        }
    },
    "require": {
        "php": ">=5.4",
    },
    "require-dev": {
        "phpspec/phpspec": "^2.3",
        "phpunit/phpunit": "^4.5",
        "symfony/console": "^2.3",
        "symfony/yaml": "^2.2"
    }
}
```

Then create a test script:

```
#!/usr/bin/env sh

# bin/test.sh

composer --quiet --no-interaction update --optimize-autoloader > /dev/null

vendor/bin/phpspec --no-interaction run -f dot && vendor/bin/phpunit
```

And finally configure PHPUnit:

```xml
<?xml version="1.0" encoding="UTF-8"?>

<!-- phpunit.xml.dist -->
<!-- http://phpunit.de/manual/4.1/en/appendixes.configuration.html -->
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="http://schema.phpunit.de/4.1/phpunit.xsd"
         backupGlobals="false"
         colors="true"
         bootstrap="vendor/autoload.php"
>
    <testsuites>
        <testsuite name="Fortune SDK Test Suite">
            <directory>tests</directory>
        </testsuite>
    </testsuites>
</phpunit>
```

## Request Handler

Since Guzzle might completly change next year, we're going to abstract it behind
our own HTTP client:

```php
<?php

// src/Acme/FortuneSdk/Remote/RequestHandler.php

namespace Acme\FortuneSdk\Remote;

use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;

interface RequestHandler
{
    /**
     * @param RequestInterface $request
     *
     * @return ResponseInterface
     *
     * @throws ClientException If client throws an unexpected exception (e.g. connection error, etc)
     */
    public function handle(RequestInterface $request);
}
```

We've decided to use the new PSR-7 standard:

    composer require psr/http-message:^1.0

We'll hide any errors behind our own exception:

```php
<?php

// src/Acme/FortuneSdk/Remote/ClientException.php

namespace Acme\FortuneSdk\Remote;

use RuntimeException;

class ClientException extends RuntimeException
{
}
```

Its first implementation will be with Guzzle 6:

```php
<?php

// src/Acme/FortuneSdk/Remote/RequestHandler/GuzzleSixRequestHandler.php

namespace Acme\FortuneSdk\Remote\RequestHandler;

use Acme\FortuneSdk\Remote\ClientException;
use Acme\FortuneSdk\Remote\RequestHandler;
use Exception;
use GuzzleHttp\Client;
use GuzzleHttp\Exception\BadResponseException;
use Psr\Http\Message\RequestInterface;

class GuzzleSixRequestHandler implements RequestHandler
{
    private $client;

    public function __construct(Client $client)
    {
        $this->client = $client;
    }

    public function handle(RequestInterface $request)
    {
        try {
            return $this->client->send($request);
        } catch (BadResponseException $e) {
            return $e->getResponse();
        } catch (Exception $e) {
            throw new ClientException('Client threw an unexpected exception', 0, $e);
        }
    }
}
```

And that's it. When Guzzle 7 will be released, we'll just have to create a new
implementation and throw away the old one instead of having to replace it everywhere
in our project. We can even change our mind and use a completly different HTTP client
(Buzz, etc).

Since we've started to softly depend on Guzzle, we need to install it with Composer:

    composer require guzzlehttp/guzzle:^6.0

## Functional test

We can now create a functional test describing our service:

```php
<?php

// tests/Quote/SubmitNewQuoteTest.php

namespace Acme\FortuneSdk\Tests\Quote;

use Acme\FortuneSdk\Quote\SubmitNewQuote\RemoteSubmitNewQuote;
use Acme\FortuneSdk\Fixtures\FixturesRequestHandler;
use PHPUnit_Framework_TestCase;

class SubmitNewQuoteTest extends PHPUnit_Framework_TestCase
{
    const URL = 'http://example.com';
    const QUOTE = 'Nobody expects the Spanish Inquisition!';

    private $submitNewQuote;

    protected function setUp()
    {
        $requestHandler = new FixturesRequestHandler();
        $this->submitNewQuote = new RemoteSubmitNewQuote($requestHandler, self::URL);
    }

    /**
     * @test
     */
    public function it_can_submit_a_new_quote()
    {
        $quote = $this->submitNewQuote->submit(self::QUOTE);

        self::assertSame(self::QUOTE, $quote['quote']);
    }
}
```

Let's run the tests:

    sh ./bin/test.sh

It fails because `FixturesRequestHandler` doesn't exist. It's an implementation
of `RequestHandler` designed for our tests: even if the endpoint actually existed,
relying on network calls in our tests would only make them brittle
(because it's slow and unreliable).

Let's create it:

```php
<?php

// fixtures/FixturesRequestHandler.php

namespace Acme\FortuneSdk\Fixtures;

use Acme\FortuneSdk\Remote\RequestHandler;
use Psr\Http\Message\RequestInterface;
use Zend\Diactoros\Response;
use Zend\Diactoros\Stream;

class FixturesRequestHandler implements RequestHandler
{
    private $routes;

    public function __construct()
    {
        $this->routes = array(
            array(
                'controller' => new Controller\Quote\SubmitNewQuoteController(),
                'pattern' => '#/quotes#',
                'methods' => array('POST'),
            ),
        );
    }

    public function handle(RequestInterface $request)
    {
        $path = $request->getUri()->getPath();
        $method = $request->getMethod();
        foreach ($this->routes as $route) {
            if (1 === preg_match($route['pattern'], $path)) {
                if (false === in_array($method, $route['methods'], true)) {
                    $body = new Stream('php://temp', 'w');
                    $body->write(json_encode(array(
                        'message' => "Method \"$method\" for route \"$path\" not supported (supported methods are: ".implode(', ', $route['methods']).")",
                    )));

                    return new Response($body, 405, array('Content-Type' => 'application/json'));
                }
                try {
                    return $route['controller']->handle($request);
                } catch (FixturesException $e) {
                    $body = new Stream('php://temp', 'w');
                    $body->write($e->getMessage());

                    return new Response($body, $e->getCode(), array('Content-Type' => 'application/json'));
                }
            }
        }
        $body = new Stream('php://temp', 'w');
        $body->write(json_encode(array(
            'message' => "Route \"$path\" not found",
        )));

        return new Response($body, 404, array('Content-Type' => 'application/json'));
    }
}
```

We've decided to rely on Zend Diactoros to build the request, since it is the de
facto implementation of PSR-7:

    composer require zendframework/zend-diactoros:^1.0

We've open the possibility of managing many endpoints with this class. We now need
to define a controller for the quote submission one:

```php
<?php

// fixtures/Controller/Quote/SubmitNewQuoteController.php

namespace Acme\FortuneSdk\Fixtures\Controller\Quote;

use Acme\FortuneSdk\Remote\RequestHandler;
use Acme\FortuneSdk\Fixtures\FixturesException;
use Psr\Http\Message\RequestInterface;
use Zend\Diactoros\Response;
use Zend\Diactoros\Stream;

class SubmitNewQuoteController implements RequestHandler
{
    public function handle(RequestInterface $request)
    {
        $submitNewQuote = json_decode($request->getBody()->__toString(), true);
        if (false === isset($submitNewQuote['quote'])) {
            throw FixturesException::make('Missing required "quote" parameter', 422);
        }
        $quote = (string) $submitNewQuote['quote'];
        if ('' === $quote) {
            throw FixturesException::make('Invalid "quote" parameter: must not be empty', 422);
        }
        $body = new Stream('php://temp', 'w');
        $body->write(json_encode(array(
            'id' => '',
            'quote' => $quote
        )));

        return new Response($body, 201, array('Content-Type' => 'application/json'));
    }
}
```

Finally we need to write the exception class:

```php
<?php

// fixtures/FixturesException.php

namespace fixtures\Acme\FortuneSdk\Fixtures;

use DomainException;

class FixturesException extends DomainException
{
    /**
     * @param string $message
     * @param int    $statusCode
     *
     * @return FixturesException
     */
    public static function make($message, $statusCode)
    {
        return new self(json_encode(array('message' => $message)), $statusCode);
    }
}
```

Let's run the tests:

    sh ./bin/test.sh

They now fail because `SubmitNewQuote` doesn't exist.

## SubmitNewQuote

First of all, we'll define our service as an interface:

```php
<?php

// src/Acme/FortuneSdk/Quote/SubmitNewQuote.php

namespace Acme\FortuneSdk\Quote;

interface SubmitNewQuote
{
    public function submit($quote);
}
```

This will allow developers using our SDK to create their own implementation for testing
or extension purpose.
It will also allow us to create Composite implementation: we can have a remote
implementation that does the actual work, wrapped in a lazy cache implementation
itself wrapped in a log implementation.

Here we'll just take care of the remote one, let's bootstrap its test:

    vendor/bin/phpspec describe 'Acme\FortuneSdk\Quote\SubmitNewQuote\RemoteSubmitNewQuote'

And now we can write the tests:

```php
<?php

// spec/Acme/FortuneSdk/Quote/SubmitNewQuote.php

namespace spec\Acme\FortuneSdk\Quote\SubmitNewQuote;

use Acme\FortuneSdk\Remote\RequestHandler;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\StreamInterface;

class RemoteSubmitNewQuoteSpec extends ObjectBehavior
{
    const URL = 'http://example.com';
    const QUOTE = 'Nobody expects the Spanish Inquisition!';

    function let(RequestHandler $requestHandler)
    {
        $this->beConstructedWith($requestHandler, self::URL);
    }

    function it_is_a_submit_new_quote()
    {
        $this->shouldImplement('Acme\FortuneSdk\Quote\SubmitNewQuote');
    }

    function it_calls_the_remote_endpoint(
        RequestHandler $requestHandler,
        ResponseInterface $response,
        StreamInterface $stream
    ) {
        $quote = array(
            'quote' => self::QUOTE,
        );

        $request = Argument::type('Psr\Http\Message\RequestInterface');
        $requestHandler->handle($request)->willReturn($response);
        $response->getBody()->willReturn($stream);
        $stream->__toString()->willReturn(json_encode($quote));

        $this->submit(self::QUOTE)->shouldBe($quote);
    }
}
```

In this test, we've used a wildcard to represent the request since the service is
going to create it. This is at the cost of not knowing how it is built.

If we absolutely want to have control over this, we need to delegate the request
construction to a factory, it then becomes possible to mock the request and check
how it is built:

```php
<?php

// spec/Acme/FortuneSdk/Quote/SubmitNewQuote.php

namespace spec\Acme\FortuneSdk\Quote\SubmitNewQuote;

use Acme\FortuneSdk\Remote\RequestFactory;
use Acme\FortuneSdk\Remote\RequestHandler;
use PhpSpec\ObjectBehavior;
use Psr\Http\Message\RequestInterface;
use Psr\Http\Message\ResponseInterface;
use Psr\Http\Message\StreamInterface;

class RemoteSubmitNewQuoteSpec extends ObjectBehavior
{
    const URL = 'http://example.com';
    const QUOTE = 'Nobody expects the Spanish Inquisition!';

    function let(RequestFactory $requestFactory, RequestHandler $requestHandler)
    {
        $this->beConstructedWith($requestFactory, $requestHandler, self::URL);
    }

    function it_is_a_submit_new_quote()
    {
        $this->shouldImplement('Acme\FortuneSdk\Quote\SubmitNewQuote');
    }

    function it_calls_the_remote_endpoint(
        RequestFactory $requestFactory,
        RequestHandler $requestHandler,
        RequestInterface $request,
        ResponseInterface $response,
        StreamInterface $stream
    ) {
        $quote = array(
            'quote' => self::QUOTE,
        );

        $requestFactory->make(self::URL.'/v1/quotes', 'POST', json_encode($quote), array(
            'Content-Type' => 'application/json'
        ))->willReturn($request);
        $requestHandler->handle($request)->willReturn($response);
        $response->getBody()->willReturn($stream);
        $stream->__toString()->willReturn(json_encode($quote));

        $this->submit(self::QUOTE)->shouldBe($quote);
    }
}
```

The choice between the first solution and the second one really depends on our preferences
and on what we're trying to achieve. For the sake of this article, we'll stick
to the first one (to avoid having to create the factory class and change the functional test,
this article is already long enough!).

Let's run our tests to bootstrap the code:

    vendor/bin/phpspec run

Now we can write the actual code:

```php
<?php

// src/Acme/FortuneSdk/Quote/SubmitNewQuote/RemoteSubmitNewQuote.php

namespace Acme\FortuneSdk\Quote\SubmitNewQuote;

use Acme\FortuneSdk\Quote\SubmitNewQuote;
use Acme\FortuneSdk\Remote\RequestHandler;
use Zend\Diactoros\Request;
use Zend\Diactoros\Stream;

class RemoteSubmitNewQuote implements SubmitNewQuote
{
    private $requestHandler;
    private $url;

    public function __construct(RequestHandler $requestHandler, $url)
    {
        $this->requestHandler = $requestHandler;
        $this->url = $url;
    }

    public function submit($quote)
    {
        $body = new Stream('php://memory', 'w');
        $body->write(json_encode(array(
            'quote' => $quote,
        )));
        $request = new Request($this->url.'/v1/quotes', 'POST', $body, array(
            'Content-Type' => 'application/json'
        ));
        $quote = json_decode($this->requestHandler->handle($request)->getBody()->__toString(), true);

        return $quote;
    }
}
```

This should be sufficient to make our tests pass:

    sh ./bin/test.sh

All green!

We now have a SDK that provides a `SubmitNewQuote` service allowing us to submit new quotes.
Since we've mocked the network connection, we can't be sure that our SDK actually works.
Manual testing can be sufficient in this case: we can build a Command Line Interface (CLI)
client and check by ourselves if everything is fine, once in a while.

## Conclusion

Inversion of Control is a principle that can come handy when dealing with third party library,
especially the ones that change often like Guzzle. It can be applied easily:
instead of making our high level classes rely on concrete low level ones, we just
need to introduce an interface.

Once again, all projects are different and this solution might not apply in every
case. If we're building an application that we expect to maintain for a couple of years
it can be worth it to protect ourselves from external changes.
