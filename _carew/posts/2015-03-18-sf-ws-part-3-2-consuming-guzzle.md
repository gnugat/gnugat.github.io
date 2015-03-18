---
layout: post
title: Symfony / Web Services - part 3.2: Consuming, Guzzle
tags:
    - Symfony
    - technical
    - Symfony / Web Services series
---

This is the sixth article of the series on managing Web Services in a
[Symfony](https://symfony.com) environment. Have a look at the five first ones:

* {{ link('posts/2015-01-14-sf-ws-part-1-introduction.md', '1. Introduction') }}
* {{ link('posts/2015-01-21-sf-ws-part-2-1-creation-bootstrap.md', '2.1 Creation bootstrap') }}
* {{ link('posts/2015-01-28-sf-ws-part-2-2-creation-pragmatic.md', '2.2 Creation, the pragmatic way') }}
* {{ link('posts/2015-03-04-sf-ws-part-2-3-creation-refactoring.md', '2.3 Creation, refactoring') }}
* {{ link('posts/2015-03-11-sf-ws-part-3-1-consuming-request-handler.md', '3.1 Consuming, RequestHandler') }}

You can check the code in the [following repository](https://github.com/gnugat-examples/sf-cs).

In the previous article, we've bootstrapped an application with a RequestHandler,
allowing us to be decoupled from the third part library we'll choose to request
remote endpoints.

In this article, we'll create a Guzzle 5 implementation.

## Guzzle Request Handler

As usual, we first describe the class we want to create:

    ./bin/phpspec describe 'AppBundle\RequestHandler\Middleware\GuzzleRequestHandler'

Our Guzzle implementation will translate our `Request` into a guzzle one, and a
guzzle response into our `Response`:

```php
<?php
// spec/AppBundle/RequestHandler/Middleware/GuzzleRequestHandlerSpec.php

namespace spec\AppBundle\RequestHandler\Middleware;

use AppBundle\RequestHandler\Request;
use GuzzleHttp\ClientInterface;
use GuzzleHttp\Message\RequestInterface;
use GuzzleHttp\Message\ResponseInterface;
use GuzzleHttp\Stream\StreamInterface;
use PhpSpec\ObjectBehavior;

class GuzzleRequestHandlerSpec extends ObjectBehavior
{
    const VERB = 'POST';
    const URI = '/api/v1/profiles';

    const HEADER_NAME = 'Content-Type';
    const HEADER_VALUE = 'application/json';

    const BODY = '{"username":"King Arthur"}';

    function let(ClientInterface $client)
    {
        $this->beConstructedWith($client);
    }

    function it_is_a_request_handler()
    {
        $this->shouldImplement('AppBundle\RequestHandler\RequestHandler');
    }

    function it_uses_guzzle_to_do_the_actual_request(
        ClientInterface $client,
        RequestInterface $guzzleRequest,
        ResponseInterface $guzzleResponse,
        StreamInterface $stream
    )
    {
        $request = new Request(self::VERB, self::URI);
        $request->setHeader(self::HEADER_NAME, self::HEADER_VALUE);
        $request->setBody(self::BODY);

        $client->createRequest(self::VERB, self::URI, array(
            'headers' => array(self::HEADER_NAME => self::HEADER_VALUE),
            'body' => self::BODY,
        ))->willReturn($guzzleRequest);
        $client->send($guzzleRequest)->willReturn($guzzleResponse);
        $guzzleResponse->getStatusCode()->willReturn(201);
        $guzzleResponse->getHeaders()->willReturn(array('Content-Type' => 'application/json'));
        $guzzleResponse->getBody()->willReturn($stream);
        $stream->__toString()->willReturn('{"id":42,"username":"King Arthur"}');

        $this->handle($request)->shouldHaveType('AppBundle\RequestHandler\Response');
    }
}
```

Time to boostrap this implementation:

    ./bin/phpspec run

And to actually write it:

```php
<?php
// File: src/AppBundle/RequestHandler/Middleware/GuzzleRequestHandler.php

namespace AppBundle\RequestHandler\Middleware;

use AppBundle\RequestHandler\Request;
use AppBundle\RequestHandler\RequestHandler;
use AppBundle\RequestHandler\Response;
use GuzzleHttp\ClientInterface;
use GuzzleHttp\Message\RequestInterface;
use GuzzleHttp\Message\ResponseInterface;
use GuzzleHttp\Stream\StreamInterface;

class GuzzleRequestHandler implements RequestHandler
{
    private $client;

    public function __construct(ClientInterface $client)
    {
        $this->client = $client;
    }

    public function handle(Request $request)
    {
        $guzzleRequest = $this->client->createRequest($request->getVerb(), $request->getUri(), array(
            'headers' => $request->getHeaders(),
            'body' => $request->getBody(),
        ));
        $guzzleResponse = $this->client->send($guzzleRequest);
        $response = new Response($guzzleResponse->getStatusCode());
        $response->setHeaders($guzzleResponse->getHeaders());
        $response->setBody($guzzleResponse->getBody()->__toString());

        return $response;
    }
}
```

Let's check it:

    ./bin/phpspec run

Brilliant!

    git add -A
    git commit -m 'Created GuzzleRequestHandler'

## Event Middleware

In the future we'd like to be able to hook in the `RequestHandler`'s workflow,
for example if the Response's body is in JSON, convert it into an array.

This kind of thing can be done by sending events, in our case when a Response is received:

```php
<?php
// File: src/AppBundle/RequestHandler/ReceivedResponse.php

namespace AppBundle\RequestHandler\Event;

use AppBundle\RequestHandler\Response;
use Symfony\Component\EventDispatcher\Event;

class ReceivedResponse extends Event
{
    private $response;

    public function __construct(Response $response)
    {
        $this->response = $response;
    }

    public function getResponse()
    {
        return $this->response;
    }
}
```

> **Note**: This is a simple Data Transfer Object (DTO), it doesn't contain any
> logic and never will. This means that we don't have to write any tests for it.

We could add an `EventDispatcher` in `GuzzleRequestHandler`, or we could create
a middleware: a RequestHandler that dispatches events and then calls another RequestHandler
(e.g. `GuzzleRequestHandler`):

    ./bin/phpspec describe 'AppBundle\RequestHandler\Middleware\EventRequestHandler'

This way if we want to throw away `GuzzleRequestHandler` and replace it with something
else, we don't have to write again the dispatching code. Here's the specification:

```php
<?php
// File: spec/AppBundle/RequestHandler/Middleware/EventRequestHandlerSpec.php

namespace spec\AppBundle\RequestHandler\Middleware;

use AppBundle\RequestHandler\Request;
use AppBundle\RequestHandler\RequestHandler;
use AppBundle\RequestHandler\Response;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;
use Symfony\Component\EventDispatcher\EventDispatcherInterface;

class EventRequestHandlerSpec extends ObjectBehavior
{
    function let(EventDispatcherInterface $eventDispatcher, RequestHandler $requestHandler)
    {
        $this->beConstructedWith($eventDispatcher, $requestHandler);
    }

    function it_is_a_request_handler()
    {
        $this->shouldImplement('AppBundle\RequestHandler\RequestHandler');
    }

    function it_dispatches_events(
        EventDispatcherInterface $eventDispatcher,
        Request $request,
        RequestHandler $requestHandler,
        Response $response
    )
    {
        $requestHandler->handle($request)->willReturn($response);
        $receivedResponse = Argument::type('AppBundle\RequestHandler\Event\ReceivedResponse');
        $eventDispatcher->dispatch('request_handler.received_response', $receivedResponse)->shouldBeCalled();

        $this->handle($request)->shouldBe($response);
    }
}
```

> **Note**: We could improve this middleware by dispatching an event before giving
> the request to the RequestHandler. We could also catch exceptions coming from
> the RequestHandler and dispatch an event.

Time to bootstrap the code:

    ./bin/phpspec run

And to make the test pass:

```php
<?php
// File: src/AppBundle/RequestHandler/Middleware/EventRequestHandler.php

namespace AppBundle\RequestHandler\Middleware;

use AppBundle\RequestHandler\Event\ReceivedResponse;
use AppBundle\RequestHandler\Request;
use AppBundle\RequestHandler\RequestHandler;
use Symfony\Component\EventDispatcher\EventDispatcherInterface;

class EventRequestHandler implements RequestHandler
{
    private $eventDispatcher;
    private $requestHandler;

    public function __construct(EventDispatcherInterface $eventDispatcher, RequestHandler $requestHandler)
    {
        $this->eventDispatcher = $eventDispatcher;
        $this->requestHandler = $requestHandler;
    }

    public function handle(Request $request)
    {
        $response = $this->requestHandler->handle($request);
        $this->eventDispatcher->dispatch('request_handler.received_response', new ReceivedResponse($response));

        return $response;
    }
}
```

Did we succeed?

    ./bin/phpspec run

Yes, we did:

    git add -A
    git commit -m 'Created EventRequestHandler'

## Json Response Listener

When a Response contains a JSON body, we need to:

* check the content type
* decode the body
* check that the JSON syntax is valid

With this in mind, we can describe the listerner:

    ./bin/phpspec describe 'AppBundle\RequestHandler\Listener\JsonResponseListener'

Now we can write the specification:

```php
<?php
// src: spec/AppBundle/RequestHandler/Listener/JsonResponseListenerSpec.php

namespace spec\AppBundle\RequestHandler\Listener;

use AppBundle\RequestHandler\Event\ReceivedResponse;
use AppBundle\RequestHandler\Response;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class JsonResponseListenerSpec extends ObjectBehavior
{
    function it_handles_json_response(ReceivedResponse $receivedResponse, Response $response)
    {
        $receivedResponse->getResponse()->willReturn($response);
        $response->getHeader('Content-Type')->willReturn('application/json');
        $response->getBody()->willReturn('{"data":[]}');
        $response->setBody(array('data' => array()))->shouldBeCalled();

        $this->onReceivedResponse($receivedResponse);
    }

    function it_does_not_handle_non_json_response(ReceivedResponse $receivedResponse, Response $response)
    {
        $receivedResponse->getResponse()->willReturn($response);
        $response->getHeader('Content-Type')->willReturn('text/html');
        $response->getBody()->shouldNotBeCalled();

        $this->onReceivedResponse($receivedResponse);
    }

    function it_fails_to_handle_invalid_json(ReceivedResponse $receivedResponse, Response $response)
    {
        $receivedResponse->getResponse()->willReturn($response);
        $response->getHeader('Content-Type')->willReturn('application/json');
        $response->getBody()->willReturn('{"data":[');

        $exception = 'Exception';
        $this->shouldThrow($exception)->duringOnReceivedResponse($receivedResponse);
    }
}
```

Time to implement the code:

```php
<?php
// File: src/AppBundle/RequestHandler/Listener/JsonResponseListener.php

namespace AppBundle\RequestHandler\Listener;

use AppBundle\RequestHandler\Event\ReceivedResponse;
use Exception;

class JsonResponseListener
{
    public function onReceivedResponse(ReceivedResponse $receivedResponse)
    {
        $response = $receivedResponse->getResponse();
        $contentType = $response->getHeader('Content-Type');
        if (false === strpos($response->getHeader('Content-Type'), 'application/json')) {
            return;
        }
        $body = $response->getBody();
        $json = json_decode($body, true);
        if (json_last_error()) {
            throw new Exception("Invalid JSON: $body");
        }
        $response->setBody($json);
    }
}
```

Is it enough to make the tests pass?

    ./bin/phpspec run

Yes, we can commit:

    git add -A
    git commit -m 'Created JsonResponseListener'

## Creating services

In order to be able to use this code in our Symfony application, we need to
define those classes as services. Since we'll have a lot of definitions, we'll
create a `services` directory:

    mkdir app/config/services

We'll update `services.yml` to include our new file:

```
# File: app/config/services.yml
imports:
    - { resource: services/request_handler.yml }
```

And finally we'll create the `request_handler.yml` file:

    touch app/config/services/request_handler.yml

The first service we'll define is Guzzle:

```
#file: app/config/services/request_handler.yml
services:
    guzzle.client:
        class: GuzzleHttp\Client
```

This allows us to define the GuzzleRequestHandler:

```
#file: app/config/services/request_handler.yml

    app.guzzle_request_handler:
        class: AppBundle\RequestHandler\Middleware\GuzzleRequestHandler
        arguments:
            - "@guzzle.client"
```

We want to wrap each of these GuzzleRequestHandler calls with events, so we define
EventRequestHandler like this:

```
#file: app/config/services/request_handler.yml

    app.event_request_handler:
        class: AppBundle\RequestHandler\Middleware\EventRequestHandler
        arguments:
            - "@event_dispatcher"
            - "@app.guzzle_request_handler"
```

In the future we might add more middlewares (e.g. RetryRequestHandler, StopwatchRequestHandler, etc),
so we want to avoid using a service that points directly to an implementation. We
can define an alias:

```
#file: app/config/services/request_handler.yml

    app.request_handler:
        alias: app.event_request_handler
```

Finally, we want to define our listener:

```
#file: app/config/services/request_handler.yml

    app.request_handler.json_response_listener:
        class: AppBundle\RequestHandler\Listener\JsonResponseListener
        tags:
            - { name: kernel.event_listener, event: request_handler.received_response, method: onReceivedResponse }
```

And that's it!

    git add -A
    git commit -m 'Defined RequestHandler as a service'

## Conclusion

We can now send remote request using Guzzle, without coupling ourself to the library.
We even implemented an EventRequestHandler to allow extension points, it also provides
us an example on how to write more RequestHandler middlewares.

In the next article we'll start using RequestHandler in a specific kind of service:
Gateways.

### HTTP Adapter

You might be interested in [Ivory HttpAdapter](https://github.com/egeloen/ivory-http-adapter),
a library very similar to our RequestHandler: it sends remote request through a
given client (it supports many of them). It also provides events to hook into its workflow!

Personnaly, I'd rather create my own RequestHandler, as my purpose is to decouple
the application from an external library like Guzzle: using a third party library
to do so seems a bit ironic.
As you can see there's little effort involved, and it has the advantage of providing
the strict minimum the application needs.

### PSR-7

[PSR-7](https://github.com/php-fig/fig-standards/blob/master/proposed/http-message.md)
is a standard currently under review: it defines how frameworks should ideally
implement the HTTP protocole.

Since it's not yet accepted, it is subject to change so I wouldn't recommend to follow it yet.
Our RequestHandler kind of implement the HTTP protocole, but I'd rather not make
it PSR-7 compliant, as it requires the implementation of many features we don't
really need.

To get a balanced opinion on the matter, I'd recommend you to read:

* [PSR-7 By Example](https://mwop.net/blog/2015-01-26-psr-7-by-example.html)
* [PSR-7 is imminent, and here's my issues with it.](http://evertpot.com/psr-7-issues/)
