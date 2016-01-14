---
layout: post
title: Memio models
tags:
    - memio
    - pet project
    - introducing library
---

> **TL;DR**: Describe code by building [models](http://github.com/memio/model).

Memio is a highly opinionated PHP code generation library, its version 1.0.0 (stable)
is going to be released soon: currently the main package `memio/memio` is being
split into smaller packages.

In this article, we'll have a look at the very first package to be ready: `memio/model`.

## Describing code

Let's have a look at the following method:

```php
    public function handle(Request $request, $type = self::MASTER_REQUEST, $catch = true)
    {
    }
```

We have many things here:

* a method named `handle` which is:
    * public
    * non static
    * non final
    * non abstract

It has the following arguments:

* a `Request` object named `request`
* an integer named `type` which defaults to `self::MASTER_REQUEST`
* a boolean named `catch` which defaults to `true`

Memio provides models that allow us to describe this method by constructing objects:

```php
<?php

use Memio\Model\Argument;
use Memio\Model\Method;

require __DIR__.'/vendor/autoload.php';

$method = Method::make('handle')
    ->addArgument(Argument::make('Request', 'request'))
    ->addArgument(Argument::make('int', 'type')
        ->setDefaultValue('self::MASTER_REQUEST')
    )
    ->addArgument(Argument::make('bool', 'catch')
        ->setDefaultValue('true')
    )
;
```

> **Note**: Static constructors are used to allow fluent interface (chaining calls).
> From PHP 5.6 it is possible to do the following:
> `(new Method('handle'))->addArgument(new Argument('Request', 'request'));`

## Building models dynamically

Usually models aren't built manually, they could be constructed using:

* a configuration (a PHP array, a YAML file, etc)
* parameters (from CLI input, a web request, etc)
* existing code (using [nikic](http://nikic.github.io/aboutMe.html)'s [PHP-Parser](https://github.com/nikic/PHP-Parser) for instance)

Here's a usage example. When running the test suite, [phpspec](http://phpspec.net)
generates missing methods in our code (amongst many other nice things).

If the following call is found in a test:

```php
        $this->handle($request);
```

And if the `handle` method isn't defined in the class currently tested, then phpspec
gathers the following parameters:

* `$methodName`, which here is set to `'handle'`
* `$arguments`, which here is set to `array($request)`

Let's re-write its generator using Memio:

```php
<?php

use Memio\Model\Argument;
use Memio\Model\Method;

require __DIR__.'/vendor/autoload.php';

function phpspec_generator($methodName, array $arguments) {
    $method = new Method($methodName);
    $index = 1;
    foreach ($arguments as $argument) {
        $type = is_object($argument) ? get_class($argument) : gettype($argument);
        $argumentName = 'argument'.$index++;
        $method->addArgument(new Argument($type, $argumentName));
    }

    return $method
}
```

Pretty straightforward!

## Conclusion

Models are Memio's core, almost every memio packages will rely on them:

* `memio/linter` will scan models to detect errors (e.g. abstract methods in a final class)
* `memio/twig-template` will use them to actually generate the corresponding code

For now they can describe:

* a method argument (typehint when needed, default value)
* a method (with PHPdoc, visibility, staticness, abstracness and if it's final)
* a property (with PHPdoc, visibility, staticness, default value)
* a constant
* a class (with PHPdoc, parents, interfaces, abstractness and if it's final)
* an interface (with PHPdoc, parent interfaces)
* a file (with license header, namespace, use statements)

There are some limitations:

* it can only describe a method's body using a string (e.g. `$toto = 42;\necho $toto;`)
* a file must have a class or an interface

For now, it will be sufficient to start working on exciting projects!

If you'd like to find out more about Memio Models, have a look at the documentation:

* [regular Models](http://memio.github.io/memio/doc/01-model-tutorial.html)
* [PHPdoc Models](http://memio.github.io/memio/doc/02-phpdoc-tutorial.html)
