---
layout: post
title: Mars Rover, Locating handler
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
cd packages/location
git checkout 5-location
```

## Locate Rover

As usual, we're going to use our
[Command Bus twist](/2016/06/29/mars-rover-landing.html#twisting-command-bus):

* create a Command object that contains and validates input parameters
* create a Command Handler object that receives the Command and does the
  actual logic

However in this case we don't have any input parameters: we only want the
location of the rover. So do we really need to create an empty `LocateRover`
class?

If in the future we want to handle many rovers (a Rover name or ID parameter)
or if we want to know the location of a rover at a given time (time parameter),
then having this empty class can make sense: we can then fill it later.

However, in this tutorial anyway, we don't have such a need so we can be
pragmatic about it and just omit it.

## LocateRoverHandler

Let's start straight away by creating the `LocateRoverHandler`. We're starting
by bootstraping the test class:

```
vendor/bin/phpspec describe 'MarsRover\Location\LocateRoverHandler'
```

This should create the following
`spec/MarsRover/Location/LocateRoverHandlerSpec.php` file:

```php
<?php

namespace spec\MarsRover\Location;

use MarsRover\Location\LocateRoverHandler;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class LocateRoverHandlerSpec extends ObjectBehavior
{
    function it_is_initializable()
    {
        $this->shouldHaveType(LocateRoverHandler::class);
    }
}
```

We'll need a service which is able to replay all the landing and driving events
to compute the latest location of the rover. Let's call it `FindLatestLocation`.
Or maybe it'd be faster if we computed that latest location on the go, while
we receive each landing and driving event? In that case our `FindLatestLocation`
would just need to retrieve those values from a sort of cache.

It sounds like we can have many ways of finding the rover location, and
commiting to one right now only to find out later that another implementation
was better would be a shame. So let's delay our decision and rely on an
interface for now:

```php
<?php

namespace spec\MarsRover\Location;

use MarsRover\Location\Service\FindLatestLocation;
use PhpSpec\ObjectBehavior;

class LocateRoverHandlerSpec extends ObjectBehavior
{
    const X = 23;
    const Y = 42;
    const ORIENTATION = 'north';

    const LOCATION = [
        'x' => self::X,
        'y' => self::Y,
        'orientation' => self::ORIENTATION,
    ];

    function it_finds_a_rover_latest_location(
        FindLatestLocation $findLatestLocation
    ) {
        $this->beConstructedWith($findLatestLocation);

        $findLatestLocation->find()->willReturn(self::LOCATION);

        $this->handle()->shouldBe(self::LOCATION);
    }
}
```

It might be our smallest Handler of all. Since it only uses one service, we
might start wondering if it was worth to have a handler at all (we could just
use the `FindLatestLocation` service directly), after all we did skip the
Command for similar reasons.

However, if we throw away our handler, we'll lose our "automated use case
documentation": the service is an interface and cannot be tested. So let's keep
it. Let's run the tests now:

```
vendor/bin/phpspec run
```

They fail because `LocateRoverHandler` doesn't exist, but phpspec bootstrapped
it for us in the `src/MarsRover/Location/LocateRoverHandler.php` file:

```php
<?php

namespace MarsRover\Location;

use MarsRover\Location\Service\FindLatestLocation;

class LocateRoverHandler
{
    private $findLatestLocation;

    public function __construct(FindLatestLocation $findLatestLocation)
    {
        $this->findLatestLocation = $findLatestLocation;
    }

    public function handle()
    {
    }
}
```

Thanks to the [SpecGen extension](https://github.com/memio/spec-gen), phpspec
was able to detect Dependency Injection, and bootstrapped a constructor with
an attribute initialization for us. How nice!

We'll just need to complete the `handle` method:

```php
<?php

namespace MarsRover\Location;

use MarsRover\Location\Service\FindLatestLocation;

class LocateRoverHandler
{
    private $findLatestLocation;

    public function __construct(FindLatestLocation $findLatestLocation)
    {
        $this->findLatestLocation = $findLatestLocation;
    }

    public function handle()
    {
        return $this->findLatestLocation->find();
    }
}
```

Overall, the code looks very similar to the test. Let's run them again:

```
vendor/bin/phpspec run
```

All green! We can commit our work:

```
git add -A
git commit -m '5: Created LocateRoverHandler'
```

## Conclusion

Locating the rover is as simple as retrieving it from somewhere. We've
delegated the decision on where this "somewhere" is because there are many
valid solutions (replaying all the events from the EventStore, a cache, etc).

Delegating those decisions can be done by creating an interface, it allows us
to create as many implementations as we want, without having to modify the
logic we've just written.

## What's next?

The Test Driven Development cycle wouldn't be complete without a refactoring
step. In the next article we'll create a `Location` value object, to make our
`FindLatestLocation` and `LocateRoverHandler` classes return something more
explicit.
