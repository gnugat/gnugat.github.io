---
layout: post
title: Lightweight console library
tags:
    - pet project
    - deprecated
---

> **Deprecated**: This article has been deprecated.

> **TL;DR**: [Konzolo](https://github.com/gnugat/konzolo) can be used to create
> minimalistic CLI applications, or to implement the command design pattern.

After implementing a same feature in many projects, I usually have the reflex to
create a library out of it. [Konzolo](https://github.com/gnugat/konzolo) is one
of them :) .

In this article we'll see its features:

* [Create a command](#create-a-command)
* [Binding up an application](#binding-up-an-application)
* [Input constraint](#input-constraint)
* [Input validator](#input-validator)
* [Exceptions](#exceptions)
* [Conclusion](#conclusion)

## Create a command

Let's create a "hello world" command:

```php
<?php

namespace Acme\Demo\Command;

use Gnugat\Konzolo\Command;
use Gnugat\Konzolo\Input;

class HelloWorldCommand implements Command
{
    public function execute(Input $input)
    {
        $name = $input->getArgument('name');
        echo "Hello $name\n";

        return Command::EXIT_SUCCESS;
    }
}
```

> **Note**: If the name argument is missing, an exception will be thrown.
> Keep reading to know more about those exceptions.

We only have to implement the `execute` method, which receives a convenient
`Input` class and returns 0 on success (actually this is optional).

## Binding up an application

Now that we have a command, let's put it in an application:

```php
<?php
// File: console.php

use Acme\Demo\Command\HelloWorldCommand;
use Gnugat\Konzolo\Application;
use Gnugat\Konzolo\Input;

require __DIR__.'/vendor/autoload.php';

$input = new Input($argv[1]); // command name (acme:hello-world)
if (isset($argv[2])) {
    $input->setArgument('name', $argv[2]);
}

$application = new Application();
$application->addCommand('acme:hello-world', new HelloWorldCommand());

$application->run($input);
```

You can then run it:

    php console.php acme:hello-world Igor

## Input constraint

If you need to validate the input, you can create a constraint:

```php
<?php

namespace Acme\Demo\Validation;

use Gnugat\Konzolo\Exception\InvalidInputException;
use Gnugat\Konzolo\Input;
use Gnugat\Konzolo\Validation\InputConstraint;

class NoWorldNameConstraint implements InputConstraint
{
    public function throwIfInvalid(Input $input)
    {
        $name = $input->getArgument('name');
        if ('World' === $name) {
            throw new InvalidInputException($input, 'The "name" parameter must not be set to "World"');
        }
    }
}
```

This constraint can be used directly in the command, as a dependency:

```php
<?php

namespace Acme\Demo\Command;

use Acme\Demo\Validation\NoWorldNameConstraint;
use Gnugat\Konzolo\Command;
use Gnugat\Konzolo\Input;

class HelloWorldCommand implements Command
{
    private $noWorldNameConstraint;

    public function __construct(NoWorldNameConstraint $noWorldNameConstraint)
    {
        $this->noWorldNameConstraint = $noWorldNameConstraint;
    }

    public function execute(Input $input)
    {
        $this->noWorldNameConstraint->throwIfInvalid($input);
        $name = $input->getArgument('name');
        echo "Hello $name\n";

        return Command::EXIT_SUCCESS;
    }
}
```

And then inject it:

```php
<?php
// File: console.php

use Acme\Demo\Command\HelloWorldCommand;
use Acme\Demo\Validation\NoWorldNameConstraint;
use Gnugat\Konzolo\Application;
use Gnugat\Konzolo\Input;

require __DIR__.'/vendor/autoload.php';

$input = new Input($argv[1]); // command name (acme:hello-world)
if (isset($argv[2])) {
    $input->setArgument('name', $argv[2]);
}

$application = new Application();
$application->addCommand('acme:hello-world', new HelloWorldCommand(new NoWorldNameConstraint()));

$application->run($input);
```

## Input validator

More conveniently, the command can depend on a validator:

```php
<?php

namespace Acme\Demo\Command;

use Gnugat\Konzolo\Command;
use Gnugat\Konzolo\Input;
use Gnugat\Konzolo\Validation\InputValidator;

class HelloWorldCommand implements Command
{
    private $validator;

    public function __construct(InputValidator $validator)
    {
        $this->validator = $validator;
    }

    public function execute(Input $input)
    {
        $this->validator->throwIfInvalid($input);
        $name = $input->getArgument('name');
        echo "Hello $name\n";

        return Command::EXIT_SUCCESS;
    }
}
```

You can add many constraint in a validator, and set priorities:

```php
<?php
// File: console.php

use Acme\Demo\Command\HelloWorldCommand;
use Acme\Demo\Validation\NoWorldNameConstraint;
use Gnugat\Konzolo\Application;
use Gnugat\Konzolo\Input;
use Gnugat\Konzolo\Validation\InputValidator;

require __DIR__.'/vendor/autoload.php';

$input = new Input($argv[1]); // command name (acme:hello-world)
if (isset($argv[2])) {
    $input->setArgument('name', $argv[2]);
}

$helloWorldValidator = new InputValidator();
$helloWorldValidator->addConstraint(new NoWorldNameConstraint(), 42);

$application = new Application();
$application->addCommand('acme:hello-world', new HelloWorldCommand($helloWorldValidator));

$application->run($input);
```

> **Note**: The highest the priority, the soonest the constraint will be executed.
> For example, a constraint with priority 1337 will be executed before another
> one with priority 23 (even if this second one has been added first in the validator).

## Exceptions

Konzolo's exceptions all implement the `Gnugat\Konzolo\Exception\Exception` interface.
This means you can catch every single one of them using this type. They also
extend at the standard `\Exception` class, so if you don't care about Konzolo
specific exceptions, you can catch them all!

This is usefull for example in [Symfony2](https://symfony.com): you can create
a Konzolo exception listener.

You can find more about the different kind of exceptions and their specific
methods in [its dedicated documentation](http://github.com/gnugat/konzolo/tree/master/doc/exception.md).

## Conclusion

We have seen how to create commands and validate their inputs.

Our examples showed how to create a CLI application, but Konzolo is mainly aimed at being used **in**
applications (not only CLI ones).
For example, [Redaktilo](https://github.com/gnugat/redaktilo) uses internally
a system of Command/CommandInvoker, using an array as input and sanitizer as a
validation mechanism. All this logic can now be externalized, thanks to Konzolo!

I'd like to keep Konzolo as small as possible, but here's a list of possible
features it could see in the future:

### Command finder

Currently we can find commands by their exact names. But wouldn't it be nice if
we could just provide part of a name? Or an alias?

### Input Factories

Creating input manually isn't always what we need. A factory that creates one
from an array could improve the situation.
