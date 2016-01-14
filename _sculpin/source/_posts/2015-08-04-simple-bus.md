---
layout: post
title: Simple Bus
tags:
    - introducing library
    - Simple Bus
---

[Simple Bus](http://simplebus.github.io/MessageBus/) is a lightweight library
created by [Matthias Noback](https://twitter.com/matthiasnoback) allowing you to
use the Command Bus design pattern in your applications.

## Command / Query Responsibility Separation

The [CQRS principle](http://martinfowler.com/bliki/CQRS.html) specifies that an
application entry point (e.g. console command, or web controller) should only do
an imperative command (e.g. register a member) or an interrogatory command (how many members?).

Here's a nice reference about the different kinds of commands, by
[Mathias Verraes](https://twitter.com/mathiasverraes): [Messaging flavours](http://verraes.net/2015/01/messaging-flavours/).

This allows to simplify the application and the code base: those are two different
concerns and with the [Single Responsibility Principle](http://www.objectmentor.com/resources/articles/srp.pdf)
we've learned that they shouldn't be mixed.

The Command Bus pattern aims at solving the imperative command part.

## Command Bus

With this design pattern, we have 3 different kinds of class:

* Command: a Data Transfer Object (no logic) with a name describing the command (e.g. `RegisterMember`)
* Command Handler: the service that does the actions require by the Command (note: 1 Command =  1 Command Handler)
* Command Bus: given a Command, it will execute the appropriate Command Handler

Our entry points would create the command using the parameters received
(e.g. console input or request content), and then give it to the Command Bus.

Having a Command Bus class is really nice as it allows us to execute things before and
after every commands: for example in a test environment we could wrap SQL queries in transactions
and roll them back.

## Usage example

Here's how to install Simple Bus:

    composer require simple-bus/message-bus:^3.0

Since it allows us to choose how the Command Bus will find the Command Handler, we
have to set it up:

```php
<?php

use SimpleBus\Message\Bus\Middleware\MessageBusSupportingMiddleware;
use SimpleBus\Message\CallableResolver\CallableMap;
use SimpleBus\Message\CallableResolver\ServiceLocatorAwareCallableResolver;
use SimpleBus\Message\Handler\DelegatesToMessageHandlerMiddleware;
use SimpleBus\Message\Handler\Resolver\NameBasedMessageHandlerResolver;
use SimpleBus\Message\Name\ClassBasedNameResolver;

require __DIR__.'/vendor/autoload.php';

$commandHandlerMap = new CallableMap(array(
    'Vendor\Project\Member\RegisterMember' => array('register_member_handler', 'handle'),
), new ServiceLocatorAwareCallableResolver(function ($serviceId) {
    if ('register_member_handler' === $serviceId) {
        return new Vendor\Project\Member\RegisterMemberHandler();
    }
}));

$commandBus = new MessageBusSupportingMiddleware();
$commandBus->appendMiddleware(new DelegatesToMessageHandlerMiddleware(new NameBasedMessageHandlerResolver(
    new ClassBasedNameResolver(),
    $commandHandlerMap
)));
```

This create a Command Bus that will use the given Command's Fully Qualified ClassName
(FQCN, the class name with its full namespace) to call the associated Command Handler
in the map. Also, the Command Handler will only be created if it is used!

This configuration looks a bit scary, but thankfully if we use [Symfony](http://symfony.com/)
we can just install the bundle:

    composer require simple-bus/symfony-bridge:^3.0
    # Don't forget to register `SimpleBus\SymfonyBridge\SimpleBusCommandBusBundle` in `AppKernel`

Then we just have to use the `command_bus` service. To register Command Handler, we
need to tag service definitions as follow:

```
services:
    register_member_handler:
        class: Vendor\Project\Member\RegisterMemberHandler
        tags:
            - { name: command_handler, handles: Vendor\Project\Member\RegisterMember }
```

Now that the configuration is settled, here's a usage example:

```php
$username = isset($argv[1]) ? $argv[1] : null;
$commandBus->handle(new RegisterMember($username));
```

The command would look like this:

```php
<?php

namespace Vendor\Project\Member;

class RegisterMember
{
    public $username;

    public function __construct($username)
    {
        if (null === $username) {
            throw new \InvalidArgumentException('Missing required "username" parameter');
        }
        $this->username = $username;
    }
}
```

> **Note**: Commands validate simple input logic (required parameters, parameter type, etc).

The Command Handler could look like this:

```php
<?php

namespace Vendor\Project\Member;

class RegisterMember
{
    private $memberRepository;

    public function __construct(MemberRespository $memberRepository)
    {
        $this->memberRepository = $memberRepository;
    }

    public function handle(RegisterMember $registerMember)
    {
        if ($memberRepository->has($registerMember->username)) {
            throw new \DomainException(sprintf('Given username "%s" already exists, and duplicates are not allowed', $registerMember->username));
        }
        $memberRepository->register($registerMember);
    }
}
```

The Command Handler validates more complex logic (member username duplication, etc).

Here's a nice reference about command validation: [Form, Command, and Model Validation](http://verraes.net/2015/02/form-command-model-validation/).

## Tips

Here are some personal tips!

We can reuse Command Handlers by injecting them into other Command Handlers
(don't inject the Command Bus in a Command Handler).

Command Handlers were not meant to return anything (think of asynchrone messages).
But this might not always be pragmatic: in this case we can store a return value in the Command.

We've talked about the Command part in CQRS, what about the Query part?
I've experimented a bit with a "Query Bus", but in the end I've settled down with
a Search Engine class, to which a Criteria is given.

## Conclusion

Remember when people said that controllers shouldn't have any logic in it?
With the Command Bus pattern this becomes possible.
It also makes this kind of logic reusable and testable.

Simple Bus is a nice library for this: it doesn't get in our way.
For more information about it, read the series of articles published for its first release
(caution: the public API changed a lot since): [A wave of command buses](http://php-and-symfony.matthiasnoback.nl/tags/SimpleBus/).

An alternative in the PHP world would be [Tactician](http://tactician.thephpleague.com/).

Here's also some nice slides by [Richard Miller](https://twitter.com/mr_r_miller)
about CQRS: [Avoiding the Mud](https://speakerdeck.com/richardmiller/avoiding-the-mud).
