---
layout: post
title: Mars Rover, Locating moving
tags:
    - mars rover series
    - TDD
    - phpspec
    - event sourcing
    - mono repo
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

In this article we're going to move geolocation value objects (`Location`,
`Coordinates` and `Orientation`) into their new package (`geolocation`):

```
git checkout 5-location
cd packages/geolocation
```

## Geolocation

Let's move our value objects to their new package:

```
mkdir -p src/MarsRover/Geolocation spec/MarsRover/Geolocation
mv ../navigation/src/MarsRover/Navigation/{Coordinates,Location,Orientation}.php ./src/MarsRover/Geolocation/
mv ../navigation/spec/MarsRover/Navigation/{Coordinates,Location,Orientation}Spec.php ./spec/MarsRover/Geolocation/
```

We then need to fix the namespace:

```
sed -i 's/Navigation/Geolocation/' */MarsRover/Geolocation/*.php
```

This should allow us to run successfully our tests for this package:

```
vendor/bin/phpspec run
```

All Green!

## Navigation

Now let's update the `navigation` package:

```
cd ../navigation
```

In order to find where our `Location` class is used, we can use the following:

```
grep -R Location src spec/
```

We need to fix the use statement in `spec/MarsRover/Navigation/LandRoverSpec.php`:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Geolocation\Location;
use MarsRover\Geolocation\Orientation;
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

We can see that we also use `Orientation`, so we fix it here and we'lldo a search later.

Then we need to add use statements in `src/MarsRover/Navigation/LandRover.php`:

```php
<?php

namespace MarsRover\Navigation;

use MarsRover\Geolocation\{
    Coordinates,
    Location,
    Orientation
};

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

We also spot a use of `Coordinates`, so we fix it here now and we'll do a search later.

All done. Let's search for `Coordinates`:

```
grep -R Coordinates src spec
```

There's nothing we haven't fixed yet, so let's search for `Orientation`:

```
grep -R Orientation src spec
```

It looks like `spec/MarsRover/Navigation/LandRoverHandlerSpec.php` uses it, so let's fix it:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\EventSourcing\AnEventHappened;
use MarsRover\EventSourcing\Event;
use MarsRover\Navigation\Events;
use MarsRover\EventSourcing\EventStore;
use MarsRover\Navigation\LandRover;
use MarsRover\Geolocation\Orientation;
use PhpSpec\ObjectBehavior;

class LandRoverHandlerSpec extends ObjectBehavior
{
    const X = 23;
    const Y = 42;
    const ORIENTATION = Orientation::NORTH;

    const EVENT_NAME = Events::ROVER_LANDED;
    const EVENT_DATA = [
        'x' => self::X,
        'y' => self::Y,
        'orientation' => self::ORIENTATION,
    ];

    function it_lands_a_rover_at_given_location(
        AnEventHappened $anEventHappened,
        Event $roverLanded,
        EventStore $eventStore
    ) {
        $this->beConstructedwith($anEventHappened, $eventStore);
        $landRover = new LandRover(
            self::X,
            self::Y,
            self::ORIENTATION
        );

        $anEventHappened->justNow(
            self::EVENT_NAME,
            self::EVENT_DATA
        )->willReturn($roverLanded);
        $eventStore->log($roverLanded)->shouldBeCalled();

        $this->handle($landRover);
    }
}
```

That should be it for our `navigation` package. Let's run the tests:

```
vendor/bin/phpspec run
```

All Green!

## Location

Finally we can use our value objects in our `location` package:

```
cd ../location
```

We can now use `Orientation` for our constant in `spec/MarsRover/Location/LocateRoverHandlerSpec.php`,
and also make sure both `FindLatestLocation` and `LocateRoverHandler` return a `Location`
value object:

```php
<?php

namespace spec\MarsRover\Location;

use MarsRover\Geolocation\Coordinates;
use MarsRover\Geolocation\Location;
use MarsRover\Geolocation\Orientation;
use MarsRover\Location\Service\FindLatestLocation;
use PhpSpec\ObjectBehavior;

class LocateRoverHandlerSpec extends ObjectBehavior
{
    const X = 23;
    const Y = 42;
    const ORIENTATION = Orientation::NORTH;

    const LOCATION = [
        'x' => self::X,
        'y' => self::Y,
        'orientation' => self::ORIENTATION,
    ];

    function it_finds_a_rover_latest_location(
        FindLatestLocation $findLatestLocation
    ) {
        $this->beConstructedWith($findLatestLocation);
        $location = new Location(
            new Coordinates(self::X, self::Y),
            new Orientation(self::ORIENTATION)
        );

        $findLatestLocation->find()->willReturn($location);

        $this->handle()->shouldBe($location);
    }
}
```

Let's update `src/MarsRover/Location/Service/FindLatestLocation.php` to add the return type:

```php
<?php

namespace MarsRover\Location\Service;

use MarsRover\Geolocation\Location;

interface FindLatestLocation
{
    public function find() : Location;
}
```

And finally let's update `src/MarsRover/Location/LocateRoverHandler.php`:

```php
<?php

namespace MarsRover\Location;

use MarsRover\Geolocation\Location;
use MarsRover\Location\Service\FindLatestLocation;

class LocateRoverHandler
{
    private $findLatestLocation;

    public function __construct(FindLatestLocation $findLatestLocation)
    {
        $this->findLatestLocation = $findLatestLocation;
    }

    public function handle() : Location
    {
        return $this->findLatestLocation->find();
    }
}
```

Now tests should pass:

```
vendor/bin/phpspec run
```

All green! Let's check all tests across our project:

```
cd ../../
vendor/bin/phpspec run
```

[Super green](https://www.youtube.com/watch?v=rKHh3EIFcZw)!
We can now commit our work:

```
git add -A
git commit -m 'Moved geolocation value objects in their package'
git checkout master
git merge --no-ff 5-location
```

## Conclusion

And that's it! We now have a fully functional Mars Rover, that covers the
following use cases:

> 1. Mars Rovers need first to be landed at a given position. A position is
>    composed of coordinates (`x` and `y`, which are both integers) and an
>    orientation (a string being one of `north`, `east`, `west` or `south`).
> 2. Once a rover has been landed on Mars it is possible to drive them, using
>    instructions such as:
>    * `move_forward` (keeps orientation, but moves along the `x` or `y` axis)
>    * `turn_left` / `turn_right` (keeps the same coordinates, but changes the
>      orientation).
> 3. Mars rover will be requested to give its current location (`x` and `y`
>    coordinates and the orientation).

In order to follow the CQRS principle, we've decided to separate our code in
two main packages:

* `navigation`: write logic
* `location`: read logic

With this we can imagine deploying `navigation` on a central, restricted in
access server, and deploy many `location` servers, all synchronized with the
data received in `navigation`.

Splitting our code into many packages would have been quite bothersome without
Mono Repo: all our packages are versioned in the same git repository and can be
linked together using Composer.

For each use case, we've structured our code as follow:

1. create a "Command" object that represents user input and intentation
2. create a "Value Object" for each Command parameter, with simple input validation
3. create a "CommandHandler" object that does the actual work

With Event Sourcing, the "actual work" for "write" use cases is simply creating
an event and store it. For the "read" use cases it could be retrieving the
latests state by replaying all the past events in the store, or simply retrieving
the latest state from a cache.

And last but not least, we've written tests before writing the actual code, which
helped us to think about how the code will be used. Our test method names were
written as if they were sentences, which has the consequence to make our test
a descriptive and accurate documentation. And of course our tests make sure we
don't introduce regressions.

I hope this series has helped to introduce you to those concepts.
