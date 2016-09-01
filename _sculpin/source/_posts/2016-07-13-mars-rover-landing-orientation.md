---
layout: post
title: Mars Rover, Landing orientation
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

We've also started to refactor it by
[extracting coordinates in their own class](/2016/07/06/mars-rover-landing-coordinates.html).

In this article we're going to further refactor `LandRover`:

```
cd packages/navigation
git checkout 2-landing
```

## Responsibilities

By having a look at `LandRover`, we can guess that it has 2 reasons to change:

* coordinates `x` and `y` might become floats, or have an additional `z`
* orientation might become an angular degree, or have a vertical orientation

This hints toward two new classes, extracted from `LandRover`: `Coordinates`
and `Orientation`. In this article we'll take care of `Orientation`.

## Orientation

Let's start by bootstraping `Orientation` test class using
[phpspec](http://www.phpspec.net/en/stable/):

```
vendor/bin/phpspec describe 'MarsRover\Navigation\Orientation'
```

It should create the `spec/MarsRover/Navigation/OrientationSpec.php` file:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\Orientation;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class OrientationSpec extends ObjectBehavior
{
    function it_is_initializable()
    {
        $this->shouldHaveType(self::class);
    }
}
```

Instead of reusing tests from `LandRover`, we'll try to describe all the
possible orientations:

```php
<?php

namespace spec\MarsRover\Navigation;

use PhpSpec\ObjectBehavior;

class OrientationSpec extends ObjectBehavior
{
    const NORTH = 'north';
    const EAST = 'east';
    const WEST = 'west';
    const SOUTH = 'south';

    function it_can_face_north()
    {
        $this->beConstructedWith(self::NORTH);

        $this->get()->shouldBe(self::NORTH);
    }

    function it_can_face_east()
    {
        $this->beConstructedWith(self::EAST);

        $this->get()->shouldBe(self::EAST);
    }

    function it_can_face_west()
    {
        $this->beConstructedWith(self::WEST);

        $this->get()->shouldBe(self::WEST);
    }

    function it_can_face_south()
    {
        $this->beConstructedWith(self::SOUTH);

        $this->get()->shouldBe(self::SOUTH);
    }

    function it_cannot_face_anywhere_else()
    {
        $this->beConstructedWith('Somehwere else');

        $this
            ->shouldThrow(\InvalidArgumentException::class)
            ->duringInstantiation()
        ;
    }
}
```

Now we can run the tests:

```
vendor/bin/phpspec run
```

They fail because `src/MarsRover/Navigation/Orientation.php` doesn't exist,
so phpspec bootstrapped it for us:

```php
<?php

namespace MarsRover\Navigation;

class Orientation
{
    private $argument;

    public function __construct($argument)
    {
        $this->argument = $argument;
    }

    public function get()
    {
    }
}
```

We can edit it:

```php
<?php

namespace MarsRover\Navigation;

class Orientation
{
    const NORTH = 'north';
    const EAST = 'east';
    const WEST = 'west';
    const SOUTH = 'south';

    const ALLOWED_ORIENTATIONS = [
        self::NORTH,
        self::EAST,
        self::WEST,
        self::SOUTH,
    ];

    private $orientation;

    public function __construct($orientation)
    {
        if (false === in_array($orientation, self::ALLOWED_ORIENTATIONS, true)) {
            throw new \InvalidArgumentException(
                'Orientation must be one of: '
                .implode(', ', self::ALLOWED_ORIENTATIONS)
            );
        }
        $this->orientation = $orientation;
    }

    public function get() : string
    {
        return $this->orientation;
    }
}
```

And run the tests:

```
vendor/bin/phpspec run
```

All green! It's important to note that tests should also be refactored.
We're going to use `Orientation` constants in the tests:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\Orientation;
use PhpSpec\ObjectBehavior;

class OrientationSpec extends ObjectBehavior
{
    function it_can_face_north()
    {
        $this->beConstructedWith(Orientation::NORTH);

        $this->get()->shouldBe(Orientation::NORTH);
    }

    function it_can_face_east()
    {
        $this->beConstructedWith(Orientation::EAST);

        $this->get()->shouldBe(Orientation::EAST);
    }

    function it_can_face_west()
    {
        $this->beConstructedWith(Orientation::WEST);

        $this->get()->shouldBe(Orientation::WEST);
    }

    function it_can_face_south()
    {
        $this->beConstructedWith(Orientation::SOUTH);

        $this->get()->shouldBe(Orientation::SOUTH);
    }

    function it_cannot_face_anywhere_else()
    {
        $this->beConstructedWith('Somehwere else');

        $this
            ->shouldThrow(\InvalidArgumentException::class)
            ->duringInstantiation()
        ;
    }
}
```

Running the tests again:

```
vendor/bin/phpspec run
```

Still green! We can now update `LandRover` tests to use `Orientation`:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\Orientation;
use PhpSpec\ObjectBehavior;

class LandRoverSpec extends ObjectBehavior
{
    const X = 23;
    const Y = 42;
    const ORIENTATION = Orientation::NORTH;

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

        $this->getOrientation()->get()->shouldBe(self::ORIENTATION);
    }
}
```

We've removed orientation checking from `LandRover` tests, as we now trust
`Orientation` to do the job. Now We can use `Orientation` in `LandRover`:

```php
<?php

namespace MarsRover\Navigation;

class LandRover
{
    private $coordinates;
    private $orientation;

    public function __construct($x, $y, $orientation)
    {
        $this->coordinates = new Coordinates($x, $y);
        $this->orientation = new Orientation($orientation);
    }

    public function getCoordinates() : Coordinates
    {
        return $this->coordinates;
    }

    public function getOrientation() : Orientation
    {
        return $this->orientation;
    }
}
```

Let's run the tests:

```
vendor/bin/phpspec run
```

All green! We can now commit our work:

```
git add -A
git commit -m '2: Created Orientation'
```

## Conclusion

Once again we've completed the full TDD cycle: first test, then code and
finally refactor.

Before we started to extract `Coordinates` and `Orientation`, `LandRover` tests
were starting to get long and so we didn't bother to go too much into details.
This refactoring allowed us to get more confidence and add more testing cases.

phpspec has been really helpful by boostraping tests, and then when running the
tests by bootstraping code: it makes the whole TDD cycle more natural. But
it also allows us to have runnable self-checking specifications:

```
vendor/bin/phpspec run --format=pretty
```

This should now output:

```

      MarsRover\Navigation\Coordinates

  12  ✔ has x coordinate
  22  ✔ cannot have non integer x coordinate
  34  ✔ has y coordinate
  44  ✔ cannot have non integer y coordinate

      MarsRover\Navigation\LandRover

  14  ✔ has coordinates
  27  ✔ has an orientation

      MarsRover\Navigation\Orientation

  10  ✔ can face north
  17  ✔ can face east
  24  ✔ can face west
  31  ✔ can face south
  38  ✔ cannot face anywhere else


3 specs
11 examples (11 passed)
12ms
```

## What's next

In the next article we'll create the actual landing logic, using Event Sourcing.
