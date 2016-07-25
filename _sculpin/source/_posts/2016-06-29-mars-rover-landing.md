---
layout: post
title: Mars Rover, Landing
tags:
    - mars rover series
    - TDD
    - phpspec
---

In this series we're going to build the software of a Mars Rover, according to
the [following specifications](/2016/06/15/mars-rover-introduction.html).
It will allow us to practice the followings:

* Monolithic Repositories (MonoRepo)
* Command / Query Responsibility Segregation (CQRS)
* Event Sourcing (ES)
* Test Driven Development (TDD)

Previously we've created a
[navigation package](/2016/06/22/mars-rover-initialization.html), we can now
start developing the first use case:

> Mars Rovers need first to be landed at a given position. A position is
> composed of coordinates (`x` and `y`, which are both integers) and an
> orientation (a string being one of `north`, `east`, `west` or `south`).

## Twisting Command Bus

The [Command Bus design pattern](/2016/05/11/towards-cqrs-command-bus.md)
is composed of 3 classes:

* a `Command` class which validates use case input and with a name that
  communicates imperative intention (e.g. `LandRover`)
* associated to it (one to one relationship) is the `CommandHandler`,
  which does the actual logic for the use case
* a `CommandBus` that takes a `Command` and executes the appropriate
  `CommandHandler`, and that allows for middlewares

We're going to twist this design pattern for the Mars Rover by omiting the
`CommandBus` class, as we don't really need middlewares or to find the
appropriate `CommandHandler` for a given `Command`.

Let's start by creating the `Command` class that'll take care of the input
parameter validation:

```
cd packages/navigation
git checkout -b 2-landing
```

## Land Rover

We're going to bootstrap the test class for `LandRover`, using
[phpspec](http://www.phpspec.net/en/stable/):

```
vendor/bin/phpspec describe 'MarsRover\Navigation\LandRover'
```

This should generate this `spec/MarsRover/Navigation/LandRoverSpec.php` class:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\LandRover;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class LandRoverSpec extends ObjectBehavior
{
    function it_is_initializable()
    {
        $this->shouldHaveType(LandRover::class);
    }
}
```

This leaves us the task of editing it to start describing input parameters:

```php
<?php

namespace spec\MarsRover\Navigation;

use PhpSpec\ObjectBehavior;

class LandRoverSpec extends ObjectBehavior
{
    const X = 23;
    const Y = 42;
    const ORIENTATION = 'north';

    function it_has_x_coordinate()
    {
        $this->beConstructedWith(
            self::X,
            self::Y,
            self::ORIENTATION
        );

        $this->getX()->shouldBe(self::X);
    }

    function it_has_y_coordinate()
    {
        $this->beConstructedWith(
            self::X,
            self::Y,
            self::ORIENTATION
        );

        $this->getY()->shouldBe(self::Y);
    }

    function it_has_an_orientation()
    {
        $this->beConstructedWith(
            self::X,
            self::Y,
            self::ORIENTATION
        );

        $this->getOrientation()->shouldBe(self::ORIENTATION);
    }
}
```

We can now run the tests:

```
vendor/bin/phpspec run
```

This will generate the `src/MarsRover/Navigation/LandRover.php` file:

```php
<?php

namespace MarsRover\Navigation;

class LandRover
{
    private $argument1;

    private $argument2;

    private $argument3;

    public function __construct($argument1, $argument2, $argument3)
    {
        $this->argument1 = $argument1;
        $this->argument2 = $argument2;
        $this->argument3 = $argument3;
    }

    public function getX()
    {
    }

    public function getY()
    {
    }

    public function getOrientation()
    {
    }
}
```

All we need to do is to edit it:

```php
<?php

namespace MarsRover\Navigation;

class LandRover
{
    private $x;
    private $y;
    private $orientation;

    public function __construct($x, $y, $orientation)
    {
        $this->x = $x;
        $this->y = $y;
        $this->orientation = $orientation;
    }

    public function getX() : int
    {
        return $this->x;
    }

    public function getY() : int
    {
        return $this->y;
    }

    public function getOrientation() : string
    {
        return $this->orientation;
    }
}
```

Let's run the tests again:

```
vendor/bin/phpspec run
```

All green! But our job isn't finished yet, we haven't described invalid input
parameters:

```php
<?php

namespace spec\MarsRover\Navigation;

use PhpSpec\ObjectBehavior;

class LandRoverSpec extends ObjectBehavior
{
    const X = 23;
    const Y = 42;
    const ORIENTATION = 'north';

    function it_has_x_coordinate()
    {
        $this->beConstructedWith(
            self::X,
            self::Y,
            self::ORIENTATION
        );

        $this->getX()->shouldBe(self::X);
    }

    function it_cannot_have_non_integer_x_coordinate()
    {
        $this->beConstructedWith(
            'Nobody expects the Spanish Inquisition!',
            self::Y,
            self::ORIENTATION
        );

        $this->shouldThrow(
            \InvalidArgumentException::class
        )->duringInstantiation();
    }

    function it_has_y_coordinate()
    {
        $this->beConstructedWith(
            self::X,
            self::Y,
            self::ORIENTATION
        );

        $this->getY()->shouldBe(self::Y);
    }

    function it_cannot_have_non_integer_y_coordinate()
    {
        $this->beConstructedWith(
            self::X,
            'No one expects the Spanish Inquisition!',
            self::ORIENTATION
        );

        $this->shouldThrow(
            \InvalidArgumentException::class
        )->duringInstantiation();
    }

    function it_has_an_orientation()
    {
        $this->beConstructedWith(
            self::X,
            self::Y,
            self::ORIENTATION
        );

        $this->getOrientation()->shouldBe(self::ORIENTATION);
    }

    function it_cannot_have_a_non_cardinal_orientation()
    {
        $this->beConstructedWith(
            self::X,
            self::Y,
            'A hareng!'
        );

        $this->shouldThrow(
            \InvalidArgumentException::class
        )->duringInstantiation();
    }
}
```

Running the tests again:

```
vendor/bin/phpspec run
```

They fail, because we need to check input parameters:

```php
<?php

namespace MarsRover\Navigation;

class LandRover
{
    const VALID_ORIENTATIONS = ['north', 'east', 'west', 'south'];

    private $x;
    private $y;
    private $orientation;

    public function __construct($x, $y, $orientation)
    {
        if (false === is_int($x)) {
            throw new \InvalidArgumentException(
                'X coordinate must be an integer'
            );
        }
        $this->x = $x;
        if (false === is_int($y)) {
            throw new \InvalidArgumentException(
                'Y coordinate must be an integer'
            );
        }
        $this->y = $y;
        if (false === in_array($orientation, self::VALID_ORIENTATIONS, true)) {
            throw new \InvalidArgumentException(
                'Orientation must be one of: '
                .implode(', ', self::VALID_ORIENTATIONS)
            );
        }
        $this->orientation = $orientation;
    }

    public function getX() : int
    {
        return $this->x;
    }

    public function getY() : int
    {
        return $this->y;
    }

    public function getOrientation() : string
    {
        return $this->orientation;
    }
}
```

Let's run the tests again:

```
vendor/bin/phpspec run
```

All green! We can now commit our work:

```
git add -A
git commit -m '2: Created LandRover'
```

## Conclusion

We've followed the first steps of TDD: write a test then write the code.

Using phpspec makes this process easier as the code gets bootstrapped for us
once we've written the test.

Since we write those tests first, in a descriptive way (test method names
are sentences), we can use them as runnable self-checking specifications!
phpspec allows us to display them explicitly:

```
vendor/bin/phpspec run --format=pretty
```

This should display:

```

      MarsRover\Navigation\LandRover

  13  ✔ has x coordinate
  24  ✔ cannot have non integer x coordinate
  37  ✔ has y coordinate
  48  ✔ cannot have non integer y coordinate
  61  ✔ has an orientation
  72  ✔ cannot have a non cardinal orientation


1 specs
6 examples (6 passed)
10ms
```

> **Note**: `navigation` tests can also be run from the MonoRepo:
>
> ```
> cd ../../
> composer update --optimize-autoloader
> vendor/bin/phpspec run
> ```

## What's next

In the next article we'll complete the TDD cycle by refactoring `LandRover`:
we'll extract `x` and `y` coordinates into their own class.
