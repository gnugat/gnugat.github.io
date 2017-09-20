---
layout: post
title: PragmatiClean - Command Bus
tags:
    - pragmaticlean
    - symfony
    - command bus
---

> **TL;DR**: Use Command Bus pattern in your controllers, but drop the bus.

The Command Bus pattern relies on 3 types of classes:

The first one is the *Command*:

* its class name should describe the intended action in an imperative manner
  (eg `SubmitNewQuote`, `AssignReviewers`, etc)
* it is constructed using the input parameters
  (eg a Request's query/post/header parameters, a Console's input argument/option, etc)
* it applies "simple" validation on those parameters
  (eg parameter type, missing required parameter, etc)

Next is the *Command Handler*:

* it is dedicated to a single Command
  and its class name is its Command's name suffixed with `Handler`
* it applies "complex" validation on the Command's parameters
  (eg existence of referenced resource, existence of duplicates, etc)
* it calls services to apply the actual logic,
  reading it should feel like reading the steps of a use case
* it shouldn't return anything, to allow asynchronous actions

And Finally there's a *Command Bus* interface allowing us to build Middlewares:

1. we can have a Command Bus that calls the appropriate Command Handler for the given Command
2. we can have a Command Bus that wraps the above one in a database transaction
3. we can have a Command Bus that wraps the above ones to log all incoming commands
4. we can have a Command Bus that wraps the above ones to check permissions
5. etc

Middlewares can do any action we want before and/or after the wrapped Command Bus.
They can be nested in a specific order, allowing us a fine grained control over
how the Command will be handled.

## Clean Code

Command Bus can be described as a routing for the domain:
a Command (like a Request) is given to the Command Bus (like a Router)
which is going to call the appropriate Command Handler (like a Controller).

We can use Command Bus in our controller: create the Command using the
Request's inputs, and then take the code that would be in the Controller
and move it in the Command Handler.

This way our Domain logic is decoupled from the Framework. The idea of being
able to switch an application to a different framework might seem ludicrous
(when does that ever happen?), but the truth is that two major versions of
a single framework often feel like having two different frameworks
(eg symony1 V Symfony2) and in some cases it's even the case for minor versions
(eg Symfony 2.0 V Symfony 2.1).

## Pragmatic Code

The main point of Command Bus is the possibility to create Middlewares, however
the same thing could be achieved with a good old Event Dispatcher, so let's
ditch the Bus.

The Routing thing should already be done for us by the framework, and it should
be true regardless of the framework or version upgrades. So we can safely inject
Command Handlers directly in Controllers.

Finally, most of the time applications aren't asynchronous. So when it's not
the case it should be OK for the Command Handler to return a value
(eg the created or updated resource).

## Symfony Example

Let's put all this wisdom into practice by creating a Controller allowing us to
submit a code to reset a counter.

First we're going to create the Command, it should contain all the input
parameters, do a simple validation on it and have an
intention revealing name describing the action we'd like to do:

```php
<?php
// File: src/Dharma/Swan/SubmitCode.php;

namespace Dharma\Swan\Code;

class SubmitCode
{
    public $code;

    /**
     * @throws \DomainException If the required "code" parameter is missing
     * @throws \DomainException If the "code" parameter is not a string
     */
    public function __construct($code)
    {
        if (null === $code) {
            throw new \DomainException(
                'Missing required "code" parameter',
                422
            );
        }
        if (!is_string($code)) {
            throw new \DomainException(
                'Invalid "code" parameter: should be a string',
                422
            );
        }
        $this->code = (string) $code;
    }
}
```

> _Note 1_: Command class attributes are set in the constructor, and then read
> in the Command Handler. Since it's never used anywhere else, there's no point
> creating a getter or setter for it, we can just make those attributes public.

> _Note 2_: Commands are going to check the parameters type, so there's no need
> to type hint the constructor arguments (we should allow wrong types so we can
> throw an exception with a helpful message).

> _Note 3:_ `DomainException` is the PHP standard exception for application
> errors (eg not found, forbidden, etc). Here we use the code `422` which is
> the HTTP status code for `UNPROCESSABLE ENTITY` ("validation failed").
> Our advice is to create custom Application Exceptions that extend
> `DomainException` and set the right code (eg `ValidationFailed` with code 422,
> `NotFound` with code 404, etc).

The second step is to create the Command Handler. It needs to do more complex
validation, and the actual logic associated to the Command's intention:

```php
<?php
// File: src/Dharma/Swan/SubmitCodeHandler.php;

namespace Dharma\Swan;

use Dharma\Swan\Service\CheckCode;
use Dharma\Swan\Service\ResetCounter;

class SubmitCodeHandler
{
    private $checkCode;
    private $resetCounter;

    public function __construct(
        CheckCode $checkCode,
        ResetCounter $resetCounter
    ) {
        $this->checkCode = $checkCode;
        $this->resetCounter = $resetCounter;
    }

    /**
     * @throws \DomainException If the "code" parameter is not a valid code
     */
    public function handle(SubmitCode $submitCode): int
    {
        $this->checkCode->check(
            $submitCode->code
        );
        $newCount = $this->resetCounter->reset();

        return $newCount;
    }
}
```

> _Note 4_: Services with descriptive names are injected and used in the
> Command Handler, so that reading the `handle` methods feels like reading the
> steps of the current use case.

> _Note 5_: The `CheckCode` service will throw a 442 exception if the code is
> invalid (eg if the code is not `4 8 15 16 23 42`).

> _Note 6_: We've decided for `ResetCounter` to return the new count.
> For an asynchronous application, it wouldn't return anything, neither would
> the Command Handler.

Finally we can use the Command and Command Handler in our Controller:

```php
<?php
// File: src/Dharma/Swan/Controller/SubmitCodeController.php;

namespace Dharma\Swan\Controller;

use Dharma\Swan\SubmitCode;
use Dharma\Swan\SubmitCodeHandler;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpFoundation\Request;

class SubmitCodeController
{
    private $submitCodeHandler;

    public function __construct(SubmitCodeHandler $submitCodeHandler)
    {
        $this->submitCodeHandler = $submitCodeHandler;
    }

    /**
     * @throws \DomainException If the required "code" parameter is missing
     * @throws \DomainException If the "code" parameter is not a string
     * @throws \DomainException If the "code" parameter is not a valid code
     */
    public function submitCode(Request $request): Response
    {
        $newCount = $this->submitCodeHandler->handle(new SubmitCode(
            $request->request->get('code')
        ));

        return new Response(json_encode(['counter' => $newCount]), 200, [
            'Content-Type' => 'application/json',
        ]);
    }
}
```

> _Note 7_: Exceptions should be handled by event listeners, those should log
> important errors and create an appropriate response.

> _Note 8_: Some controllers have more than one action meaning they'd be
> injected with more than one Command Handler, however only one will be called
> per Request. Since Symfony 3.3 [Service Locators](https://symfony.com/blog/new-in-symfony-3-3-service-locators)
> can be injected so that the controller can only access the listed Command
> Handlers, and only one Command Handler will actually be instantiated.
> Before Symfony 3.3, the Container should be injected (same effect, but all
> services are accessible).

## Conclusion

Command Bus allows us to decouple our application logic from the framework,
protecting us from Backward Compability Breaking changes.

However since the Bus can be replaced by Event Listeners, we can simply drop it
and inject the Command Handlers directly in Controllers. If our application
isn't asynchronous, then Command Handlers should be able to return values.

So our PragmatiClean Command Bus is simply a Command and Command Handler pair
for each Use Case in our application (so one pair per Controller action).

> For more resources one the Command Bus design pattern, check these links:
>
> * [CommandBus](http://shawnmc.cool/command-bus)
>   by [Shawn McCool](https://twitter.com/ShawnMcCool)
> * [What am I missing with this whole command bus (reddit question)](https://www.reddit.com/r/PHP/comments/29a6qz/what_am_i_missing_with_this_whole_command_bus/)
> * [A wave of command buses (series)](http://php-and-symfony.matthiasnoback.nl/tags/SimpleBus/)
>   by [Matthias Noback](https://twitter.com/matthiasnoback)
> * [Avoid the Mud (slides)](https://speakerdeck.com/richardmiller/avoiding-the-mud)
>   by [Richard Miller](https://twitter.com/mr_r_miller)
> * [Messaging Flavours](http://verraes.net/2015/01/messaging-flavours/)
>   and [Form, Command, Model validation](http://verraes.net/2015/02/form-command-model-validation/)
>   and also [Functional Foundation for CQRS/ES](http://verraes.net/2014/05/functional-foundation-for-cqrs-event-sourcing/)
>   by [Mathias Verraes](https://twitter.com/mathiasverraes)
> * [Tactician](http://tactician.thephpleague.com/), a simple Command Bus library for PHP
> * [Clarified CQRS](http://www.udidahan.com/2009/12/09/clarified-cqrs/)
>   by [Udi Dahan](https://twitter.com/UdiDahan)
>
> Also here are some usage examples, with code and everything:
>
> * [Mars Rover](https://gnugat.github.io/2016/06/15/mars-rover-introduction.html):
>   an application coded chapter after chapter, using this design pattern
> * [The Ultimate Developer Guide to Symfony](https://gnugat.github.io/2016/03/24/ultimate-symfony-api-example.html)
>   Examples on how to create an API endpoint, a full stack web page and a console command
>   with Symfony and this design pattern
