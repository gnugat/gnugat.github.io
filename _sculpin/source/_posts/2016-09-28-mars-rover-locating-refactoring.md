---
layout: post
title: Mars Rover, Locating refactoring
tags:
    - mars rover series
    - TDD
    - phpspec
---

In this series we're building the software of a Mars Rover, according to
the [following specifications](/2016/06/15/mars-rover-introduction.html).
It allows us to practice the followings:

* Monolithic Repositories (MonoRepo)
* Command / Query Responsibility Segregation (CQRS)
* Event Sourcing (ES)
* Test Driven Development (TDD)

We've already developed the first use case about landing the rover on mars,
and the second one about driving it. We're now developing the last one,
requesting its location:

> Mars rover will be requested to give its current location (`x` and `y`
> coordinates and the orientation).

In this article we're going to create the locating logic:

```
git checkout 5-location
```

## Location

Our `LocateRover` command object relies on a `FindLatestLocation` service. They
both currently return an array containing the coordinates and orientation of
our rover. Since `FindLatestLocation` is an interface, we can't control what's
being actually returned... This could be fixed by specifying a `Location`
object as a return type, and it would make things more explicit.

Since Our `Location` object will contain `Coordinates` and `Orientation`, we
might want to create it in the `navigation` packages, where those two other
objects are alreay:

```
cd packages/navigation
```

We can now start writing `Location`'s test:

```
vendor/bin/phpspec describe 'MarsRover\Navigation\Location'
```

This should have bootstrapped the following
`spec/MarsRover/Navigation/LocationSpec.php` file:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\Location;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class LocationSpec extends ObjectBehavior
{
    function it_is_initializable()
    {
        $this->shouldHaveType(Location::class);
    }
}
```

We can then edit it to specify that it should contain `Coordinates` and
`Orientation`:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\Coordinates;
use MarsRover\Navigation\Orientation;
use PhpSpec\ObjectBehavior;

class LocationSpec extends ObjectBehavior
{
    const X = 23;
    const Y = 42;
    const ORIENTATION = Orientation::NORTH;

    function it_has_coordinates()
    {
        $coordinates = new Coordinates(self::X, self::Y);
        $orientation = new Orientation(self::ORIENTATION);
        $this->beConstructedWith($coordinates, $orientation);

        $this->getCoordinates()->shouldBe($coordinates);
    }

    function it_has_orientation()
    {
        $coordinates = new Coordinates(self::X, self::Y);
        $orientation = new Orientation(self::ORIENTATION);
        $this->beConstructedWith($coordinates, $orientation);

        $this->getOrientation()->shouldBe($orientation);
    }
}
```

That sounds simple enough, we can run the tests:

```
vendor/bin/phpspec run
```

And of course they fail because `Location` doesn't exist yet. to help us write
it, phpspec bootstrapped the following `src/MarsRover/Navigation/Location.php`
file:

```php
<?php

namespace MarsRover\Navigation;

class Location
{
    private $coordinates;

    private $orientation;

    public function __construct(Coordinates $coordinates, Orientation $orientation)
    {
        $this->coordinates = $coordinates;
        $this->orientation = $orientation;
    }

    public function getCoordinates()
    {
    }

    public function getOrientation()
    {
    }
}
```

Let's complete it:

```php
<?php

namespace MarsRover\Navigation;

class Location
{
    private $coordinates;
    private $orientation;

    public function __construct(
        Coordinates $coordinates,
        Orientation $orientation
    ) {
        $this->coordinates = $coordinates;
        $this->orientation = $orientation;
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

This should be enough to make our tests pass:

```
vendor/bin/phpspec run
```

All green! We can now commit our work:

```
git add -A
git commit -m '5: Created Location'
```

## Refactoring LandRover

This `Location` value object looks great! Why didn't we create it in the first
place? That'll be pragmatism for you: don't create something you might need in
the future, create something you need now. But now that's it's here, we can
refactor `LocateRover` to use it.

First let's update its test:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\Location;
use MarsRover\Navigation\Orientation;
use PhpSpec\ObjectBehavior;

class LandRoverSpec extends ObjectBehavior
{
    const X = 23;
    const Y = 42;
    const ORIENTATION = Orientation::NORTH;

    function it_has_location()
    {
        $this->beConstructedWith(
            self::X,
            self::Y,
            self::ORIENTATION
        );

        $location = $this->getLocation();
        $location->shouldHaveType(Location::class);
        $coordinates = $location->getCoordinates();
        $coordinates->getX()->shouldBe(self::X);
        $coordinates->getY()->shouldBe(self::Y);
        $location->getOrientation()->get()->shouldBe(self::ORIENTATION);
    }
}
```

Then its code:

```php
<?php

namespace MarsRover\Navigation;

class LandRover
{
    private $location;

    public function __construct($x, $y, $orientation)
    {
        $this->location = new Location(
            new Coordinates($x, $y),
            new Orientation($orientation)
        );
    }

    public function getLocation() : Location
    {
        return $this->location;
    }
}
```

And finally `LandRoverHandler`:

```php
<?php

namespace MarsRover\Navigation;

use MarsRover\EventSourcing\{
    AnEventHappened,
    EventStore
};

class LandRoverHandler
{
    private $anEventHappened;
    private $eventStore;

    public function __construct(
        AnEventHappened $anEventHappened,
        EventStore $eventStore
    ) {
        $this->anEventHappened = $anEventHappened;
        $this->eventStore = $eventStore;
    }

    public function handle(LandRover $landRover)
    {
        $location = $landRover->getLocation();
        $coordinates = $location->getCoordinates();
        $orientation = $location->getOrientation();
        $roverLanded = $this->anEventHappened->justNow(Events::ROVER_LANDED, [
            'x' => $coordinates->getX(),
            'y' => $coordinates->getY(),
            'orientation' => $orientation->get(),
        ]);
        $this->eventStore->log($roverLanded);
    }
}
```

Let's check the tests:

```
vendor/bin/phpspec run
```

All green! That should be enough to commit:

```
git add -A
git commit -m '5: Used Location in LandRover'
```

## Conclusion

While we've been playing with the notion of `Location` since the very first
use case, it's only now that we really need it that we created it.

It encapsulates X and Y coordinates as well as an orientation.

## What's next?

`Location` is currently in the `navigation` package, but we also need it in
the `location` package... To fix this we have the following solutions:

* add `navigation` as a dependency of `location`
* merge together `navigation` and `location`
* create a new `geolocation` package, with `Location`, `Coordinates` and
  `Orientation`

Since we want to keep `navigation` and `location` separate, we'll opt for the
third option and create this new package in the next article.
