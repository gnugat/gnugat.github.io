---
layout: post
title: PHPUnit setUp() is a lie
tags:
    - phpunit
---

[PHPUnit](https://phpunit.de/index.html) creates as many instances a Test Class, as it has test methods.

## Proof (and it gets worse)

Let's set up a project to verify our claim:

```
mkdir /tmp/phpunit-is-a-cake && cd "$_"
composer init --no-interaction --name 'follow/the-white-rabbit' --type project --autoload '.'
composer require -o --dev phpunit/phpunit:^9.6
```

Next we write a catchy test:

```
<?php declare(strict_types=1);
use PHPUnit\Framework\TestCase;

class CatchyTest extends TestCase
{
    private string $letMeCountThemForYou = '';

    public function __construct($name = null, array $data = [], $dataName = '')
    {
        parent::__construct($name, $data, $dataName);

        echo "How many times have I, how many times have I, how many times have I been instanciated?\n";
    }

    public function __destruct()
    {
        echo "Till the morning light\n";
    }

    public function testOne(): void
    {
        $this->letMeCountThemForYou .= 'One';

        echo "{$this->letMeCountThemForYou}\n";
    }

    public function testTwo(): void
    {
        $this->letMeCountThemForYou .= 'Two';

        echo "{$this->letMeCountThemForYou}\n";
    }

    /**
     * @dataProvider provider
     */
    public function testMore($times): void
    {
        $this->letMeCountThemForYou .= $times;

        echo "{$this->letMeCountThemForYou}\n";
    }

    public function provider(): array
    {
        return [['Three'], ['Four'], ['Five'], ['Six'], ['Seven'], ['Eight']];
    }
}
```

Finally we run the tests to see the output:

```
> phpunit ./CatchyTest.php
How many times have I, how many times have I, how many times have I been instanciated?
How many times have I, how many times have I, how many times have I been instanciated?
How many times have I, how many times have I, how many times have I been instanciated?
Till the morning light
How many times have I, how many times have I, how many times have I been instanciated?
How many times have I, how many times have I, how many times have I been instanciated?
How many times have I, how many times have I, how many times have I been instanciated?
How many times have I, how many times have I, how many times have I been instanciated?
How many times have I, how many times have I, how many times have I been instanciated?
How many times have I, how many times have I, how many times have I been instanciated?
PHPUnit 9.6.19 by Sebastian Bergmann and contributors.

ROne
RTwo
RThree
RFour
RFive
RSix
RSeven
R                                                            8 / 8 (100%)Eight
// [...]
Till the morning light
Till the morning light
Till the morning light
Till the morning light
Till the morning light
Till the morning light
Till the morning light
Till the morning light
```

And Bob's your uncle! Hang on, what?

The constructor has been called 3 (test methods) + 6 (items in data provider) = 9 times
and we can observe that the class attribute's value isn't shared between the test methods
but gets reset every time.

And those instances stay alive until the vey end of the run,
meaning a concerningly increasing memory usage througout the test suite,
which also slows it down!

## "Solution"

There's [a hack that's been around for decades](https://kriswallsmith.net/post/18029585104/faster-phpunit)
to free the memory and speed up the test suites:

```
<?php declare(strict_types=1);
use PHPUnit\Framework\TestCase;

abstract class BaseTestCase extends TestCase
{
    protected function tearDown()
    {
        $refl = new ReflectionObject($this);
        foreach ($refl->getProperties() as $prop) {
            if (!$prop->isStatic() && 0 !== strpos($prop->getDeclaringClass()->getName(), 'PHPUnit\\')) {
                $prop->setAccessible(true);
                $prop->setValue($this, null);
            }
        }
    }
}
```

The `tearDown` method is called after each test method, so it's a good place to unset class attributes.

To avoid having to think about it, a catch all solution using relfection can be put inside a custom `BaseTestCase`
that'll be extended by all our test classes.

And indeed most of the code bases don't directly extend PHPUnit's TestCase,
for example [Symfony's documentation suggest to use FrameworkBundle's KernelTestCase](https://symfony.com/doc/current/testing.html).

But what does it do exactly?

## Showing the bad example

Here's a highly opinionated summary of its code:

```
<?php

namespace Symfony\Bundle\FrameworkBundle\Test;

use PHPUnit\Framework\TestCase;
use Symfony\Component\HttpKernel\KernelInterface;

abstract class KernelTestCase extends TestCase
{
    protected static ?KernelInterface $kernel = null;

    protected static function bootKernel(): KernelInterface
    {
        static::$kernel = new \AppKernel('test', true);
        $kernel->boot();

        return static::$kernel;
    }

    protected function tearDown(): void
    {
        if (null !== static::$kernel) {
            static::$kernel->shutdown();
            static::$kernel = null;
        }
    }
}
```

Symfony's HttpKernel is stateless, so being able to boot it (which is slow) only once
and store it in a static attribute of a TestCase that all our functional test implement is great!

However calling `bootKernel` will always return a new instance of the application kernel and will always boot it,
while the `tearDown` method also makes sure to nuke it after each test method...

Now I can't pretend to know the reason behind this (maybe assuming that applications are stateful?),
nor am I familiar with all the different applications out there and their specific use cases,
but that seems very unfortunate to me.

To fix it, we can rewrite it as follow:

```
<?php declare(strict_types=1);
use PHPUnit\Framework\TestCase;
use Symfony\Component\HttpKernel\KernelInterface;

abstract class MyTestCase extends TestCase
{
    protected static ?KernelInterface $kernel = null;

    protected static function getKernel(): KernelInterface
    {
        if (null === static::$kernel) {
            static::$kernel = new \AppKernel('test', true);
            $kernel->boot();
        }

        return static::$kernel;
    }
}
```

We got rid of the kernel shutdown shenanigans (can be called manually if needed),
and made sure the Kernel is instanciated (and booted) only once.

But why have this as part of the TestCase? This should be extracted into its own class:

```
<?php declare(strict_types=1);
use Symfony\Component\HttpKernel\KernelInterface;

class KernelSingleton
{
    protected static ?KernelInterface $kernel = null;

    protected static function get(): KernelInterface
    {
        if (null === static::$kernel) {
            static::$kernel = new \AppKernel('test', true);
            $kernel->boot();
        }

        return static::$kernel;
    }
}
```

I know, I know. The Singleton desing pattern has been receiving a lot of bad rap over the years.
But here, it's a legitimate use case!

## Conclusion

What have we learned?

That each PHPUnit test method is run in isolation inside its own Test Class instance,
so class attribute values will rapidly consume more and more memory (and slow down the test suite),
and they cannot be shared between two test methods unless you make them static.

And perhaps consider using Singletons instead of relying on "FrameworkTestCase".

As for PHPUnit's setUp method, in your opinion, is it best described as "executed before each test method",
or as "executed everytime the test class is instanciated"?
