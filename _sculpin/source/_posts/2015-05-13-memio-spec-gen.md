---
layout: post
title: Memio SpecGen v0.1
tags:
    - memio
    - specgen
    - phpspec
    - pet project
    - introducing library
---

> **TL;DR**: [SpecGen](http://github.com/memio/spec-gen) is a [phpspec](http://phpspec.net)
> extension that improves its code generator. Currently available: type hinted method arguments.

With [Memio v1.0 released](http://memio.github.io/memio), it is now possible to
create powerful code generators without re-inventing the wheel.
[SpecGen](http://github.com/memio/spec-gen) is the first project to use this library, let's
see what it can do for us.

## phpspec

First of all we'll talk about [phpspec](http://phpspec.net), which is an exciting
project that provides many benefits:

* a testing tool (allows to write specifications, which are kind of unit tests)
* a "best practice" enforcer (for e.g. cannot test private methods to force us to split code into smaller public APIs)
* a time saver (bootstraps tests and code)

> **Note**: See [My top 10 favourite phpsepc limitations](http://techportal.inviqa.com/2014/09/11/my-top-ten-favourite-phpspec-limitations/).

It makes Test Driven Development cycles even more meaningful:

1. bootstrap test by thinking on a class name
2. write a test by thinking how the class should behave
3. bootstrap the corresponding code by running the whole test suite
4. write code as quick as possible without thinking about best practices or design patterns (be pragmatic)
5. run the test suite to check if the code fulfills the test's specifications
6. refactor the code (manage the technical debt)
7. run the test suite to check for regressions
8. repeat!

phpspec's code generator is a big part of its value. Let's see if we can improve it.

## phpspec example

Let's have a look at how phpspec works. For this we'll need to have a project configured with
[Composer](https://getcomposer.org/download):

```
{
    "name": "vendor/project",
    "autoload": {
        "psr-4": {
            "Vendor\\Project\\": "src/Vendor/Project"
        }
    },
    "require": {},
    "require-dev": {}
}
```

We can install phpspec with the following:

    composer require --dev phpspec/phpspec:~2.2

Let's say we want to create a class that handles requests, conforming to the HTTP protocol
(take a `Request`, return a `Response`). We can call this class `RequestHandler`:

    phpspec describe 'Vendor\Project\RequestHandler'

> **Tip**: make your vendor's binaries available by adding `vendor/bin` to your `$PATH`.
> `export PATH="vendor/bin:$PATH"`.

We should now have the `spec/Vendor/Project/RequestHandlerSpec.php` file, bootstraped
for us by phpspec:

```php
<?php

namespace spec\Vendor\Project;

use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class RequestHandlerSpec extends ObjectBehavior
{
    function it_is_initializable()
    {
        $this->shouldHaveType('Vendor\Project\RequestHandler');
    }
}
```

We can directly start by writing our first specification (test method) in it:

```php
<?php
// File: spec/Vendor/Project/RequestHandlerSpec.php

namespace spec\Vendor\Project;

use PhpSpec\ObjectBehavior;
use Vendor\Project\Request;

class RequestHandlerSpec extends ObjectBehavior
{
    function it_takes_arequest_and_returns_a_response(Request $request)
    {
        $this->handle($request)->shouldHaveType('Vendor\Project\Response');
    }
}
```

> **Note**: We tried to make the test method as descriptive as possible (e.g. not `testHandler()`).
> This is the whole point of specBDD (specification Behavior Driven Development).

With this we can start to boostrap the code by simply running the test suite:

    phpspec run

It will ask the following 3 questions:

1. Would you like me to generate an interface `Vendor\Project\Request` for you?
2. Do you want me to create `Vendor\Project\RequestHandler` for you?
3. Do you want me to create `Vendor\Project\RequestHandler::handle()` for you?

By accepting everytime, phpspec will bootstrap the following
`src/Vendor/Project/Vendor/RequestHandler.php` file:

```php
<?php

namespace Vendor\Project;

class RequestHandler
{

    public function handle($argument1)
    {
        // TODO: write logic here
    }
}
```

In our specification, we make use of a non existing `Request` class, and phpspec
also bootstraped it for us in `src/Vendor/Project/Vendor/Request.php`:

```php
<?php

namespace Vendor\Project;

interface Request
{
}
```

This is extremely usefull to kickstart our TDD cycle!

## Memio SpecGen

SpecGen is a phpspec extension, it makes use of Memio (the PHP code generator library)
to make the above bootstraping even more awesome.

Here's how to install it:

    composer require --dev memio/spec-gen:~0.1

We also need to register it as a phpspec extension by writing the following `phpspec.yml` file:

```
extensions:
  - Memio\SpecGen\MemioSpecGenExtension
```

Its first release, v0.1 (unstable for now), improves the method generation with:

* type hinted arguments
* object arguments named after their type
* putting each arguments on their own lines if the inline alternative would have been longer than 120 characters

To be fair, this is exactly what already [Ciaran McNulty](https://ciaranmcnulty.com/)'s
[Typehinted Methods extension](https://github.com/ciaranmcnulty/phpspec-typehintedmethods)
provides, so why would we choose SpecGen? Well simply because it intends to do much more:

* insertion of `use` statements
* constructor generation (each argument will have a corresponding property and a property initialization)
* PHPdoc
* ???
* profit!

## Memio SpecGen example

Let's give it a try by first removing the code we boostrapped until now:

    rm -rf src

In order to demonstrate more type hints, we'll add more arguments:

```php
<?php
// File: spec/Vendor/Project/RequestHandlerSpec.php

namespace spec\Vendor\Project;

use PhpSpec\ObjectBehavior;
use Vendor\Project\Request;

class RequestHandlerSpec extends ObjectBehavior
{
    function it_takes_arequest_and_returns_a_response(Request $request)
    {
        $parameters = array();
        $isEnabled = true;
        $this->handle($request, $parameters, $isEnabled)->shouldHaveType('Vendor\Project\Response');
    }
}
```

We can now run the test suite to bootstrap the code:

    phpspec run

This should create the following `src/Vendor/Project/RequestHandler.php` file:

```php
<?php

namespace Vendor\Project;

class RequestHandler
{
    public function handle(Request $request, array $argument1, $argument2)
    {
    }
}
```

> **Note**: for now `use` statements aren't generated. In our example it doesn't
> matter since `Request` is in the same namespace as `RequestHandler`.

Let's remove again the generated code:

    rm -rf src

Now we'd like to see this multiline feature by adding many arguments to our specifiction:

```php
<?php
// File: spec/Vendor/Project/RequestHandlerSpec.php

namespace spec\Vendor\Project;

use PhpSpec\ObjectBehavior;

class RequestHandlerSpec extends ObjectBehavior
{
    function it_takes_arequest_and_returns_a_response()
    {
        $this->myMethod(1, 2, 3, 4, 5, 6, 7, 8);
    }
}
```

Again, we run the test suite:

    phpspec run

This should bootstrap the following `src/Vendor/Project/RequestHandler.php` file:

```php
<?php

namespace Vendor\Project;

class RequestHandler
{
    public function myMethod(
        $argument1,
        $argument2,
        $argument3,
        $argument4,
        $argument5,
        $argument6,
        $argument7,
        $argument8
    )
    {
    }
}
```

And that's it!

## Conclusion

Memio SpecGen improves phpspec's generator by adding better named, type hinted
and PSR-2 compliant method arguments.

Note that this kind of improvement has to be done in extension. They cannot be
done directly in phpspec because it tries to enforce best practices, and one of
them is to type hint only against interfaces. As it happens, the current extensions
can also type hint against implementations, depending on how the developers write
their specifications.

The next versions will bring even more exciting features, such as constructor and PHPdoc
generation.

> **Reference**: <a class="button button-reference" href="/2015/08/03/phpspec.html">see the phpspec reference article</a>
