---
layout: post
title: Mars Rover, Landing event
tags:
    - mars rover series
    - TDD
    - phpspec
    - event sourcing
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

We've then refactored it to extract
[coordinates](/2016/07/06/mars-rover-landing-coordinates.html)
and [orientation](/2016/07/13/mars-rover-landing-orientation.html)
in their own classes.

In this article we're going to create the actual landing logic, using
Event Sourcing:

```
cd packages/navigation
git checkout 2-landing
```

## LandRoverHandler

Following our [Command Bus twist](/2016/06/29/mars-rover-landing.html#twisting-command-bus),
we're now going to create the `LandRoverHandler` class that's going to take
care of the actual logic associated to the `LandRover` use case. We're starting
by bootstraping the test class:

```
vendor/bin/phpspec describe 'MarsRover\Navigation\LandRoverHandler'
```

this should create the following
`spec/MarsRover/Navigation/LandRoverHandlerSpec.php` file:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\LandRoverHandler;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class LandRoverHandlerSpec extends ObjectBehavior
{
    function it_is_initializable()
    {
        $this->shouldHaveType(LandRoverHandler::class);
    }
}
```

[Event Sourcing](/2016/06/15/mars-rover-introduction.html#event-sourcing) is
all about recording significant actions. Landing a rover seems significant
enough, so that's what `LandRoverHandler` should do:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\AnEventHappened;
use MarsRover\Navigation\Event;
use MarsRover\Navigation\EventStore;
use MarsRover\Navigation\LandRover;
use MarsRover\Navigation\Orientation;
use PhpSpec\ObjectBehavior;

class LandRoverHandlerSpec extends ObjectBehavior
{
    const X = 23;
    const Y = 42;
    const ORIENTATION = Orientation::NORTH;

    const EVENT_NAME = 'rover_landed';
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
        $this->beConstructedWith($anEventHappened, $eventStore);
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

In this test, we rely on:

* `Event`, a Data Transfer Object (DTO) that contains the name and the data
* `AnEventHappened`, which is actually an `Event` factory
* `EventStore`, a service responsible for "logging" `Event`s

We could have done without the factory and create directly `Event` in
`LandRoverHandler`, but then we'd have no way to check in our tests that it
was constructed with the right data.

Those classes don't exist yet, we've made them up to build a coherent
**story**. Let's run the tests:

```
vendor/bin/phpspec run
```

They fail because of the missing classes... But phpspec bootstrapped them for
us!

It created the `src/MarsRover/Navigation/AnEventHappened.php` file:

```php
<?php

namespace MarsRover\Navigation;

interface AnEventHappened
{

    public function justNow($argument1, $argument2);
}
```

It also created the `src/MarsRover/Navigation/Event.php` file:

```php
<?php

namespace MarsRover\Navigation;

interface Event
{
}
```

And it created the `src/MarsRover/Navigation/EventStore.php` file:

```php
<?php

namespace MarsRover\Navigation;

interface EventStore
{

    public function log($argument1);
}
```

As we can see, when we reference a non existence class, phpspec generates an
interface for us. It also generates methods, if we've described method calls
in our test.

For now we'll leave them like this, and have a look at the generated
`src/MarsRover/Navigation/LandRoverHandler.php` file:

```php
<?php

namespace MarsRover\Navigation;

class LandRoverHandler
{
    private $anEventHappened;

    private $eventStore;

    public function __construct(AnEventHappened $anEventHappened, EventStore $eventStore)
    {
        $this->anEventHappened = $anEventHappened;
        $this->eventStore = $eventStore;
    }

    public function handle(LandRover $landRover)
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

namespace MarsRover\Navigation;

class LandRoverHandler
{
    const EVENT_NAME = 'rover_landed';

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
        $roverLanded = $this->anEventHappened->justNow(self::EVENT_NAME, [
            'x' => $landRover->getCoordinates()->getX(),
            'y' => $landRover->getCoordinates()->getY(),
            'orientation' => $landRover->getOrientation()->get(),
        ]);
        $this->eventStore->log($roverLanded);
    }
}
```

Overall, the code looks very similar to the test. Let's run them:

```
vendor/bin/phpspec run
```

All green! We might want to use the same event name in both the code and the
test, so let's create a `src/MarsRover/Navigation/Events.php` file:

```php
<?php

namespace MarsRover\Navigation;

class Events
{
    const ROVER_LANDED = 'rover_landed';
}
```

Then use it in the code:

```php
<?php

namespace MarsRover\Navigation;

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
        $roverLanded = $this->anEventHappened->justNow(Events::ROVER_LANDED, [
            'x' => $landRover->getCoordinates()->getX(),
            'y' => $landRover->getCoordinates()->getY(),
            'orientation' => $landRover->getOrientation()->get(),
        ]);
        $this->eventStore->log($roverLanded);
    }
}
```

and finally in the test:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\AnEventHappened;
use MarsRover\Navigation\Event;
use MarsRover\Navigation\Events;
use MarsRover\Navigation\EventStore;
use MarsRover\Navigation\LandRover;
use MarsRover\Navigation\Orientation;
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
        $this->beConstructedWith($anEventHappened, $eventStore);
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

We can run the tests one last time:

```
vendor/bin/phpspec run
```

Still green! We can commit our work:

```
git add -A
git commit -m '2: Created LandRoverHandler'
git checkout master
git merge --no-ff 2-landing
```

## Conclusion

With Event Sourcing, the logic associated to our "Landing a Rover on Mars" use
case is quite simple: we just record it as an event.

## What's next?

In the next article, we'll extract Event Sourcing logic from the `navigation`
package and put it in its own `event-sourcing` one.
