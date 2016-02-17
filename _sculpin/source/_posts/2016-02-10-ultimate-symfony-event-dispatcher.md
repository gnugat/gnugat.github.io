---
layout: post
title: The Ultimate Developer Guide to Symfony - Event Dispatcher
tags:
    - symfony
    - ultimate symfony series
    - reference
---

> **Reference**: This article is intended to be as complete as possible and is
> kept up to date.

> **TL;DR**:
>
> ```php
> $eventDispatcher->addListener($eventName, $listener1, $priority);
> $eventDispatcher->addListener($eventName, $listener2, $priority - 1);
> $eventDispatcher->dispatch($eventName); // Calls $listener1, then $listener2
> ```

In this guide we explore the standalone libraries (also known as "Components")
provided by [Symfony](http://symfony.com) to help us build applications.

We've already seen:

* [HTTP Kernel and HTTP Foundation](/2016/02/03/ultimate-symfony-http-kernel.html)

We're now about to check Event Dispatcher, then in the next articles we'll have a look at:

* [Routing and YAML](/2016/02/17/ultimate-symfony-routing.html)
* Dependency Injection
* Console

## Event Dispatcher

Symfony provides an [EventDispatcher component](http://symfony.com/doc/current/components/event_dispatcher/introduction.html)
which allows the execution of registered function at key points in our applications.

It revolves around the following interface:

```php
<?php

namespace Symfony\Component\EventDispatcher;

interface EventDispatcherInterface
{
    /**
     * @param string   $eventName
     * @param callable $listener
     * @param int      $priority  High priority listeners will be executed first
     */
    public function addListener($eventName, $listener, $priority = 0);

    /**
     * @param string $eventName
     * @param Event  $event
     */
    public function dispatch($eventName, Event $event = null);
}
```

> **Note**: This snippet is a truncated version, the actual interface has methods
> to add/remove/get/check listeners and subscribers (which are "auto-configured" listeners).

An implementation is provided out of the box and can be used as follow:

```php
<?php

use Symfony\Component\EventDispatcher\EventDispatcher;

$eventDispatcher = new EventDispatcher();

$eventDispatcher->addListener('something_happened', function () {
    echo "Log it\n";
}, 1);
$eventDispatcher->addListener('something_happened', function () {
    echo "Save it\n";
}, 2);

$eventDispatcher->dispatch('something_happened');
```

This will output:

```
Save it
Log it
```

Since the second listener had a higher priority, it got executed first.

> **Note**: Listeners must be a [callable](http://php.net/manual/en/language.types.callable.php),
> for example:
>
> * an anonymous function: `$listener = function (Event $event) {};`.
> * an array with an instance of a class and a method name:
>   `$listener = array($service, 'method');`.
> * a fully qualified classname with a static method name:
>  `$listener = 'Vendor\Project\Service::staticMethod'`.

If we want to provide some context to the listeners (parameters, etc) we can
create a sub-class of `Event`:

```php
<?php

use Symfony\Component\EventDispatcher\Event;
use Symfony\Component\EventDispatcher\EventDispatcher;

class SomethingHappenedEvent extends Event
{
    private $who;
    private $what;
    private $when;

    public function __construct($who, $what)
    {
        $this->who = $who;
        $this->what = $what;
        $this->when = new \DateTime();
    }

    public function who()
    {
        return $this->who;
    }

    public function what()
    {
        return $this->what;
    }

    public function when()
    {
        return $this->when;
    }
}

$eventDispatcher = new EventDispatcher();

$eventDispatcher->addListener('something_happened', function (SomethingHappenedEvent $event) {
    echo "{$event->who()} was {$event->what()} at {$event->when()->format('Y/m/d H:i:s')}\n";
});

$eventDispatcher->dispatch('something_happened', new SomethingHappenedEvent('Arthur', 'hitchhiking'));
```

## HttpKernel example

The HttpKernel component we've seen in [the previous article](/2016/02/03/ultimate-symfony-http-kernel.html)
provides a `Kernel` abstract class that heavily relies on EventDispatcher.

For each key steps of its execution, it dispatches the following events:

1. `kernel.request`: gets a `Request`
2. `kernel.controller`: executes a callable (also known as "Controller")
3. `kernel.view`: converts the Controller's returned value into a `Response` (if necessary)
4. `kernel.response`: returns a `Response`

And in case of error:

* `kernel.exception`: handles errors

Just before returning the `Response`, `HttpKernel` dispatches one last event:

* `kernel.finish_request`: clean ups, sending emails, etc

After the `Response` has been displayed, we can dispatch:

* `kernel.terminate`: same as `kernel.finish_request`, except it won't slow down
  the rendering of request if FastCGI is enabled

Please note that `kernel.finish_request`

### Kernel Request

Listeners that registered for `kernel.request` can modify the Request object.

Out of the box there's a `RouterListener` registered which sets the following
parameters in `Request->attributes`:

* `_route`: the route name that matched the Request
* `_controller`: a callable that will handle the Request and return a Response
* `_route_parameters`: query parameters extracted from the Request

An example of a custom Listener could be one that decodes JSON content and sets
it in `Request->request`:

```php
<?php

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
    /**
     * @param GetResponseEvent $event
     */
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

Another example would be to start a database transaction:

```php
<?php

namespace AppBundle\EventListener;

use PommProject\Foundation\QueryManager\QueryManagerInterface;
use Symfony\Component\HttpKernel\Event\GetResponseEvent;

class StartTransactionListener
{
    /**
     * @var QueryManagerInterface
     */
    private $queryManager;

    /**
     * @param QueryManagerInterface $queryManager
     */
    public function __construct(QueryManagerInterface $queryManager)
    {
        $this->queryManager = $queryManager;
    }

    /**
     * @param GetResponseEvent $event
     */
    public function onKernelRequest(GetResponseEvent $event)
    {
        $this->queryManager->query('START TRANSACTION');
    }
}
```

> **Note**: [Pomm](http://pomm-project.org) is used here as an example.

### Kernel Controller

Listeners that registered for `kernel.controller` can modify the Request object.

This can be useful when we'd like to change the Controller.

For example `SensioFrameworkExtraBundle` has a `ControllerListener` that parses
the controller annotations at this point.

### Kernel View

Listeners that registered for `kernel.view` can modify the Response object.

For example `SensioFrameworkExtraBundle` has a `TemplateListener` that uses `@Template`
annotation: controllers only need to return an array and the listener will create
a response using [Twig](http://twig.sensiolabs.org/) (it will pass the array as
Twig parameters).

### Kernel Response

Listeners that registered for `kernel.response` can modify the Response object.

Out of the box there's a `ResponseListener` regitered which sets some Response
headers according to the Request's one.

### Kernel Terminate

Listeners that registered for `kernel.terminate` can execute actions after the
Response has been served (if our web server uses FastCGI).

An example of a custom Listener could be one that rollsback a database transaction,
when running in test environment:

```php
<?php

namespace AppBundle\EventListener\Pomm;

use PommProject\Foundation\QueryManager\QueryManagerInterface;
use Symfony\Component\HttpKernel\Event\PostResponseEvent;

class RollbackListener
{
    /**
     * @var QueryManagerInterface
     */
    private $queryManager;

    /**
     * @param QueryManagerInterface $queryManager
     */
    public function __construct(QueryManagerInterface $queryManager)
    {
        $this->queryManager = $queryManager;
    }

    /**
     * @param PostResponseEvent $event
     */
    public function onKernelTerminate(PostResponseEvent $event)
    {
        $this->queryManager->query('ROLLBACK');
    }
}
```

> **Note**: We'll se later how to register this listener only for test environment.

### Kernel Exception

Listeners that registered for `kernel.exception` can catch an exception and generate
an appropriate Response object.

An example of a custom Listener could be one that logs debug information and generates
a 500 Response:

```php
<?php

namespace AppBundle\EventListener;

use Psr\Log\LoggerInterface;
use Ramsey\Uuid\Uuid;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Event\GetResponseForExceptionEvent;

class ExceptionListener
{
    /**
     * @var LoggerInterface
     */
    private $logger;

    /**
     * @param LoggerInterface $logger
     */
    public function __construct(LoggerInterface $logger)
    {
        $this->logger = $logger;
    }

    /**
     * @param GetResponseForExceptionEvent $event
     */
    public function onKernelException(GetResponseForExceptionEvent $event)
    {
        $exception = $event->getException();
        $token = Uuid::uuid4()->toString();
        $this->logger->critical(
            'Caught PHP Exception {class}: "{message}" at {file} line {line}',
            array(
                'class' => get_class($exception),
                'message' => $exception->getMessage(),
                'file' => $exception->getFile(),
                'line' => $exception->getLine()
                'exception' => $exception,
                'token' => $token
            )
        );
        $event->setResponse(new Response(
            json_encode(array(
                'error' => 'An error occured, if it keeps happening please contact an administrator and provide the following token: '.$token,
            )),
            500,
            array('Content-Type' => 'application/json'))
        );
    }
}
```

> **Note**: [Ramsey UUID](https://benramsey.com/projects/ramsey-uuid/) is used
> here to provide a unique token that can be referred to.

## Conclusion

EventDispatcher is another example of a simple yet powerful Symfony component.
HttpKernel uses it to configure a standard "Symfony application", but also to
allow us to change its behaviour.

In this article we've seen the basics and how it works behind the hood when used
by HttpKernel, but we could create our own event and dispatch it to make our
own code "Open for extension, but Close to modification"
([Open/Close principle](https://blog.8thlight.com/uncle-bob/2014/05/12/TheOpenClosedPrinciple.html)).
