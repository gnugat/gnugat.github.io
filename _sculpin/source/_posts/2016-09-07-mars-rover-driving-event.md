---
layout: post
title: Mars Rover, Driving event
tags:
    - mars rover series
    - TDD
    - phpspec
    - event sourcing
---

In this series we're building the software of a Mars Rover, according to
the [following specifications](/2016/06/15/mars-rover-introduction.html).
It allows us to practice the followings:

* Monolithic Repositories (MonoRepo)
* Command / Query Responsibility Segregation (CQRS)
* Event Sourcing (ES)
* Test Driven Development (TDD)

We've already developed the first use case about landing the rover on mars,
and we've started the second one about driving it:

> Once a rover has been landed on Mars it is possible to drive them, using
> instructions such as `move_forward` (keeps orientation, but moves along the
> `x` or `y` axis) or `turn_left` / `turn_right` (keeps the same coordinates,
> but changes the orientation).

In this article we're going to create the actual driving logic, using
Event Sourcing:

```
cd packages/navigation
git checkout 4-driving
```

## DriveRoverHandler

Following our [Command Bus twist](/2016/06/29/mars-rover-landing.html#twisting-command-bus),
we're now going to create the `DriveRoverHandler` class that's going to take
care of the actual logic associated to the `DriveRover` use case. We're
starting by bootstraping the test class:

```
vendor/bin/phpspec describe 'MarsRover\Navigation\DriveRoverHandler'
```

This should create the following
`spec/MarsRover/Navigation/DriveRoverHandlerSpec.php` file:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\DriveRoverHandler;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class DriveRoverHandlerSpec extends ObjectBehavior
{
    function it_is_initializable()
    {
        $this->shouldHaveType(DriveRoverHandler::class);
    }
}
```

[Event Sourcing](/2016/06/15/mars-rover-introduction.html#event-sourcing) is
all about recording significant actions. Driving a rover seems significant
enough, so that's what `DriveRoverHandler` should do:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\EventSourcing\AnEventHappened;
use MarsRover\EventSourcing\Event;
use MarsRover\EventSourcing\EventStore;
use MarsRover\Navigation\DriveRover;
use MarsRover\Navigation\Instruction;
use PhpSpec\ObjectBehavior;

class DriveRoverHandlerSpec extends ObjectBehavior
{
    const DRIVING_INSTRUCTION = Instruction::MOVE_FORWARD;

    const EVENT_NAME = 'rover_driven';
    const EVENT_DATA = [
        'instruction' => self::DRIVING_INSTRUCTION,
    ];

    function it_drives_a_rover_with_given_instruction(
        AnEventHappened $anEventHappened,
        Event $roverDriven,
        EventStore $eventStore
    ) {
        $this->beConstructedWith($anEventHappened, $eventStore);
        $driveRover = new DriveRover(
            self::DRIVING_INSTRUCTION
        );

        $anEventHappened->justNow(
            self::EVENT_NAME,
            self::EVENT_DATA
        )->willReturn($roverDriven);
        $eventStore->log($roverDriven)->shouldBeCalled();

        $this->handle($driveRover);
    }
}
```

It's very similar to what we've done for `LandRoverHandler`, all we've done
is create and event specific to driving the rover with its instructions
and "logged" it in an `EventStore. Let's run the tests:

```
vendor/bin/phpspec run
```

They fail because `DriveRoverHandler` doesn't exists, but phpspec bootstrapped
it for us in the `src/MarsRover/Navigation/DriveRoverHandler.php` file:

```php
<?php

namespace MarsRover\Navigation;

use MarsRover\EventSourcing\AnEventHappened;
use MarsRover\EventSourcing\EventStore;

class DriveRoverHandler
{
    private $anEventHappened;

    private $eventStore;

    public function __construct(AnEventHappened $anEventHappened, EventStore $eventStore)
    {
        $this->anEventHappened = $anEventHappened;
        $this->eventStore = $eventStore;
    }

    public function handle(DriveRover $driveRover)
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

use MarsRover\EventSourcing\{
    AnEventHappened,
    EventStore
};

class DriveRoverHandler
{
    const EVENT_NAME = 'rover_driven';

    private $anEventHappened;
    private $eventStore;

    public function __construct(
        AnEventHappened $anEventHappened,
        EventStore $eventStore
    ) {
        $this->anEventHappened = $anEventHappened;
        $this->eventStore = $eventStore;
    }

    public function handle(DriveRover $driveRover)
    {
        $roverDriven = $this->anEventHappened->justNow(self::EVENT_NAME, [
            'instruction' => $driveRover->getInstruction()->get(),
        ]);
        $this->eventStore->log($roverDriven);
    }
}
```

Overall, the code looks very similar to the test. Let's run them again:

```
vendor/bin/phpspec run
```

All green! We're going to do a quick refactoring to move the event name in
the `src/MarsRover/Navigation/Events.php` file:

```php
<?php

namespace MarsRover\Navigation;

class Events
{
    const ROVER_LANDED = 'rover_landed';
    const ROVER_DRIVEN = 'rover_driven';
}
```

Then use it in the code:

```php
<?php

namespace MarsRover\Navigation;

use MarsRover\EventSourcing\{
    AnEventHappened,
    EventStore
};

class DriveRoverHandler
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

    public function handle(DriveRover $driveRover)
    {
        $roverDriven = $this->anEventHappened->justNow(Events::ROVER_DRIVEN, [
            'instruction' => $driveRover->getInstruction()->get(),
        ]);
        $this->eventStore->log($roverDriven);
    }
}
```

and finally in the test:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\EventSourcing\AnEventHappened;
use MarsRover\EventSourcing\Event;
use MarsRover\EventSourcing\EventStore;
use MarsRover\Navigation\DriveRover;
use MarsRover\Navigation\Events;
use MarsRover\Navigation\Instruction;
use PhpSpec\ObjectBehavior;

class DriveRoverHandlerSpec extends ObjectBehavior
{
    const DRIVING_INSTRUCTION = Instruction::MOVE_FORWARD;

    const EVENT_NAME = Events::ROVER_DRIVEN;
    const EVENT_DATA = [
        'instruction' => self::DRIVING_INSTRUCTION,
    ];

    function it_drives_a_rover_with_given_instruction(
        AnEventHappened $anEventHappened,
        Event $roverDriven,
        EventStore $eventStore
    ) {
        $this->beConstructedWith($anEventHappened, $eventStore);
        $driveRover = new DriveRover(
            self::DRIVING_INSTRUCTION
        );

        $anEventHappened->justNow(
            self::EVENT_NAME,
            self::EVENT_DATA
        )->willReturn($roverDriven);
        $eventStore->log($roverDriven)->shouldBeCalled();

        $this->handle($driveRover);
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
git commit -m '4: Created DriveRoverHandler'
git checkout master
git merge --no-ff 4-driving
```

## Conclusion

With Event Sourcing, the logic associated to our "Driving a Rover on Mars" use
case is quite simple: we just record it as an event.

## What's next?

In the next article, we'll create a new package to take care of the last use
case: "Requesting the Rover's location".
