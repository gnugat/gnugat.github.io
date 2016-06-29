---
layout: post
title: Mars Rover, Landing coordinates
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
[navigation package](/2016/06/22/mars-rover-initialization.html), and in it
a `LandRover` class that
[validates input parameters](/2016/06/29/mars-rover-landing.html) for our
first use case:

> Mars Rovers need first to be landed at a given position. A position is
> composed of coordinates (`x` and `y`, which are both integers) and an
> orientation (a string being one of `north`, `east`, `west` or `south`).

In this article we're going to refactor `LandRover`:

```
cd packages/navigation
git checkout 2-landing
```

## Responsibilities

By having a look at `LandRover`, we can guess that it has 2 reasons to change:

* coordinates `x` and `y` might become floats, or have an additional `z`
* orientation might become an angular degree, or have a vertical orientation

This hints toward two new classes, extracted from `LandRover`: `Coordinates`
and `Orientation`. In this article we'll take care of `Cooridnates`.

## Coordinates

First let's bootstrap the test class, using
[phpspec](http://www.phpspec.net/en/stable/):

```
vendor/bin/phpspec describe 'MarsRover\Navigation\Coordinates'
```

This will create the `spec/MarsRover/Navigation/CoordinatesSpec.php` file:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\Coordinates;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class CoordinatesSpec extends ObjectBehavior
{
    function it_is_initializable()
    {
        $this->shouldHaveType(Coordinates::class);
    }
}
```

We can edit it, by using what we've done in `LandRover` test class:

```php
<?php

namespace spec\MarsRover\Navigation;

use PhpSpec\ObjectBehavior;

class CoordinatesSpec extends ObjectBehavior
{
    const X = 23;
    const Y = 42;

    function it_has_x_coordinate()
    {
        $this->beConstructedWith(
            self::X,
            self::Y
        );

        $this->getX()->shouldBe(self::X);
    }

    function it_cannot_have_non_integer_x_coordinate()
    {
        $this->beConstructedWith(
            'Nobody expects the Spanish Inquisition!',
            self::Y
        );

        $this->shouldThrow(
            \InvalidArgumentException::class
        )->duringInstantiation();
    }

    function it_has_y_coordinate()
    {
        $this->beConstructedWith(
            self::X,
            self::Y
        );

        $this->getY()->shouldBe(self::Y);
    }

    function it_cannot_have_non_integer_y_coordinate()
    {
        $this->beConstructedWith(
            self::X,
            'No one expects the Spanish Inquisition!'
        );

        $this->shouldThrow(
            \InvalidArgumentException::class
        )->duringInstantiation();
    }
}
```

If we run the tests now, it will bootsrap the `Coordinates` class:

```
vendor/bin/phpspec run
```

And it indeed created the `src/MarsRover/Navigation/Coordinates.php` file:

```php
<?php

namespace MarsRover\Navigation;

class Coordinates
{
    private $argument1;

    private $argument2;

    public function __construct($argument1, $argument2)
    {
        $this->argument1 = $argument1;
        $this->argument2 = $argument2;
    }

    public function getX()
    {
    }

    public function getY()
    {
    }
}
```

This leaves us with the task of completing it, reusing what's been done in
`LandRover` class:

```php
<?php

namespace MarsRover\Navigation;

class Coordinates
{
    private $x;
    private $y;

    public function __construct($x, $y)
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
    }

    public function getX() : int
    {
        return $this->x;
    }

    public function getY() : int
    {
        return $this->y;
    }
}
```

We can run the tests:

```
vendor/bin/phpspec run
```

All green! Now all we have to do is update `LandRover` test class to use
`Coordinates`:

```php
<?php

namespace spec\MarsRover\Navigation;

use PhpSpec\ObjectBehavior;

class LandRoverSpec extends ObjectBehavior
{
    const X = 23;
    const Y = 42;
    const ORIENTATION = 'north';

    function it_has_coordinates()
    {
        $this->beConstructedWith(
            self::X,
            self::Y,
            self::ORIENTATION
        );

        $coordinates = $this->getCoordinates();
        $coordinates->getX()->shouldBe(self::X);
        $coordinates->getY()->shouldBe(self::Y);
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

We no longer need to check for invalid `x` and `y` values, as we trust
`Coordinates` to take care of them for us. We can now update `LandRover` class:

```php
<?php

namespace MarsRover\Navigation;

class LandRover
{
    const VALID_ORIENTATIONS = ['north', 'east', 'west', 'south'];

    private $coordinates;
    private $orientation;

    public function __construct($x, $y, $orientation)
    {
        $this->coordinates = new Coordinates($x, $y);
        if (false === in_array($orientation, self::VALID_ORIENTATIONS, true)) {
            throw new \InvalidArgumentException(
                'Orientation must be one of: '
                .implode(', ', self::VALID_ORIENTATIONS)
            );
        }
        $this->orientation = $orientation;
    }

    public function getCoordinates() : Coordinates
    {
        return $this->coordinates;
    }

    public function getOrientation() : string
    {
        return $this->orientation;
    }
}
```

And that should make our test pass:

```
vendor/bin/phpspec run
```

All green! That's enough for us to commit our work:

```
git add -A
git commit -m '2: Created Coordinates'
```

## Conclusion

We've followed the full cycle of TDD: test, code and refactor. Using phpspec
has been really helpful as it bootstraped the test classes and then their code
classes for us.

## What's next

In the next article, we'll extract `Orientation` from `LandRover`.
