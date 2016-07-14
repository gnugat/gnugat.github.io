---
layout: post
title: Mars Rover, Event Sourcing code
tags:
    - mars rover series
    - TDD
    - phpspec
    - event sourcing
    - mono repo
---

In this series we're building the software of a Mars Rover, according to the
[following specifications](/2016/06/15/mars-rover-introduction.html).
It will allow us to practice the followings:

* Monolithic Repositories (MonoRepo)
* Command / Query Responsibility Segregation (CQRS)
* Event Sourcing (ES)
* Test Driven Development (TDD)

Up until now, we've implemented the first use case, "Landing a rover on Mars":

> Mars Rovers need first to be landed at a given position. A position is
> composed of coordinates (`x` and `y`, which are both integers) and an
> orientation (a string being one of `north`, `east`, `west` or `south`).

We've also created an `event-sourcing` package with the following interfaces:

* `Event`, a Data Transfer Object (DTO) that contains the name and the data
* `AnEventHappened`, which is actually an `Event` factory
* `EventStore`, a service responsible for "logging" `Event`s

In this article, we're going to implement them.

## Event

Let's start by asking [phpspec](http://phpspec.net/) to generate the test
class:

```
vendor/bin/phpspec describe 'MarsRover\EventSourcing\Event'
```

It should have generated the following
`spec/MarsRover/EventSourcing/EventSpec.php` file:

```php
<?php

namespace spec\MarsRover\EventSourcing;

use MarsRover\EventSourcing\Event;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class EventSpec extends ObjectBehavior
{
    function it_is_initializable()
    {
        $this->shouldHaveType(Event::class);
    }
}
```

We're going to start writing test methods that describe what kind of data this
DTO holds:

```php
<?php

namespace spec\MarsRover\EventSourcing;

use PhpSpec\ObjectBehavior;

class EventSpec extends ObjectBehavior
{
    const NAME = 'something_happened';
    const DATA = [
        'message' => 'We are the knights who say Ni!',
    ];

    function let(\DateTime $receivedAt)
    {
        $this->beConstructedWith(
            self::NAME,
            self::DATA,
            $receivedAt
        );
    }

    function it_has_a_name()
    {
        $this->getName()->shouldBe(self::NAME);
    }

    function it_has_data()
    {
        $this->getData()->shouldBe(self::DATA);
    }

    function it_has_been_received_at_a_date_and_time(\DateTime $receivedAt)
    {
        $this->getReceivedAt()->shouldBe($receivedAt);
    }
}
```

We can now run the tests to bootstrap the class:

```
vendor/bin/phpspec run
```

It will overwrite the existing `src/MarsRover/EventSourcing/Event.php` file:

```php
<?php

namespace MarsRover\EventSourcing;

use DateTimeInterface;

class Event
{
    public function __construct($argument1, array $argument2, DateTimeInterface $dateTime)
    {
    }

    public function getName()
    {
    }

    public function getData()
    {
    }

    public function getReceivedAt()
    {
    }
}
```

We can edit it to make the tests pass:

```php
<?php

namespace MarsRover\EventSourcing;

class Event
{
    private $name;
    private $data;
    private $receivedAt;

    public function __construct(
        string $name,
        array $data,
        \DateTimeInterface $receivedAt
    ) {
        $this->name = $name;
        $this->data = $data;
        $this->receivedAt = $receivedAt;
    }

    public function getName() : string
    {
        return $this->name;
    }

    public function getData() : array
    {
        return $this->data;
    }

    public function getReceivedAt() : \DateTimeInterface
    {
        return $this->receivedAt;
    }
}
```

Let's check if everything is alright:

```
vendor/bin/phpspec run
```

And it is! Time to commit our work:

```
git add -A
git commit -m '3: Created Event'
```

## AnEventHappened

The next class to implement is `AnEventHappened`. Let's create its test:

```
vendor/bin/phpspec describe 'MarsRover\EventSourcing\AnEventHappened'
```

It should generate the `spec/MarsRover/EventSourcing/AnEventHappenedSpec.php`
file:

```php
<?php

namespace spec\MarsRover\EventSourcing;

use MarsRover\EventSourcing\AnEventHappened;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class AnEventHappenedSpec extends ObjectBehavior
{
    function it_is_initializable()
    {
        $this->shouldHaveType(AnEventHappened::class);
    }
}
```

We can start describing this factory by writing test methods:

```php
<?php

namespace spec\MarsRover\EventSourcing;

use MarsRover\EventSourcing\Event;
use PhpSpec\ObjectBehavior;

class AnEventHappenedSpec extends ObjectBehavior
{
    const NAME = 'something_happened';
    const DATA = [
        'message' => 'And now for something completly different',
    ];

    function it_can_create_events()
    {
        $this->justNow(self::NAME, self::DATA)->shouldHaveType(Event::class);
    }
}
```

Running the tests will generate the class:

```
vendor/bin/phpspec run
```

It should have overwritten the
`src/MarsRover/EventSourcing/AnEventHappened.php` file with:

```php
<?php

namespace MarsRover\EventSourcing;

class AnEventHappened
{
    public function justNow($argument1, $argument2)
    {
    }
}
```

We can now complete it:

```php
<?php

namespace MarsRover\EventSourcing;

class AnEventHappened
{
    public function justNow(string $name, array $data) : Event
    {
        return new Event($name, $data, new \DateTime());
    }
}
```

Let's run the tests:

```
vendor/bin/phpspec run
```

All green! Time to commit:

```
git add -A
git commit -m 'Created AnEventHappened'
```

## Conclusion

We replaced the generated interfaces for `AnEventHappened` and `Event` with
classes, which have been tested.

`EventStore` could log events in a log file, or in a database, or send them as
messages to a queue to be treated later... For that reason we'll keep the
interface.

We're going to delay its implementations for later, when the rover will be
almost done.

If we run the tests from the project's root, we'll see that it runs tests for
both `navigation` and `event-sourcing` in one go. This is one advantage of
MonoRepo: it makes it easy to make sure that changes in a package don't break
the other that depend on it.

We can now merge our branch:

```
cd ../../
git checkout master
git merge --no-ff 3-event-sourcing
```

## What's next

In the next article we'll start developing the second use case: Driving the
rover. 
