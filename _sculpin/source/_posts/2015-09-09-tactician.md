---
layout: post
title: Tactician
tags:
    - introducing library
    - tactician
    - command bus
---

Just like [SimpleBus](/2015/08/04/simple-bus.html),
[Tactician](https://tactician.thephpleague.com/) is a lightweight library created by
[Ross Tuck](http://rosstuck.com/) allowing you to use the Command Bus design pattern
in your applications.

> **Note**: Command Bus is often used to comply to [CQRS](/2015/08/25/cqrs.html, but not only.

## Usage example

Here's how to install Tactician:

    composer require league/tactician:^0.6

Then we have to associate a Command to a CommandHandler:

```php
<?php

use League\Tactician\Setup\QuickStart;

require __DIR__.'/vendor/autoload.php';

$commandBus = QuickStart::create(array(
    'Vendor\Project\Member\RegisterMember' => new Vendor\Project\Member\RegisterMemberHandler(),
));
```

It provides many framework integrations, including one for [Symfony](http://symfony.com/):

    composer require league/tactician-bundle:^0.3
    # Don't forget to register `League\Tactician\Bundle\TacticianBundle` in `AppKernel`

Then we just have to use the `tactician.commandBus` service. To register Command Handler, we
need to tag service definitions as follow:

```
services:
    register_member_handler:
        class: Vendor\Project\Member\RegisterMemberHandler
        tags:
            - { name: tactician.handler, command: Vendor\Project\Member\RegisterMember }
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
    private $username;

    public function __construct($username)
    {
        if (null === $username) {
            throw new \InvalidArgumentException('Missing required "username" parameter');
        }
        $this->username = $username;
    }

    public function getUsername()
    {
        return $this->username;
    }
}
```

> **Note**: Commands validate simple input logic (required parameters, parameter type, etc).

The Command Handler could look like this:

```php
<?php

namespace Vendor\Project\Member;

class RegisterMemberHandler
{
    private $memberRepository;

    public function __construct(MemberRespository $memberRepository)
    {
        $this->memberRepository = $memberRepository;
    }

    public function handle(RegisterMember $registerMember)
    {
        $username = $registerMember->getUsername();
        if ($memberRepository->has($username)) {
            throw new \DomainException(sprintf('Given username "%s" already exists, and duplicates are not allowed', $username));
        }
        $memberRepository->register($registerMember);
    }
}
```

The Command Handler validates more complex logic (member username duplication, etc).

Here's a nice reference about command validation: [Form, Command, and Model Validation](http://verraes.net/2015/02/form-command-model-validation/).

## Tips

Here are some personal tips!

CommandBus is able to return the value of the executed CommandHandler.
While this isn't advised in asynchronous applications (think messaging queues, like RabbitMQ)
it can be useful in simple applications.

Because Commands also contain simple input validation you can write unit test for them,
but since they're mainly DTOs it might not be too important.

CommandHandlers on the other way are good candidates for unit tests.

## Conclusion

Remember when people said that controllers shouldn't have any logic in it?
With the Command Bus pattern this becomes possible.
It also makes this kind of logic reusable and testable.

Tactician is a nice library for this: it doesn't get in our way and allows you to choose between
the "good" way or the "pragmatic" way (if you don't choose wisely, then shame on you).
