---
layout: post
title: Mars Rover, Driving instruction
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
and we've started the second one about driving it:

> Once a rover has been landed on Mars it is possible to drive them, using
> instructions such as `move_forward` (keeps orientation, but moves along the
> `x` or `y` axis) or `turn_left` / `turn_right` (keeps the same coordinates,
> but changes the orientation).

In this article we're going to refactor `DriveRover`:

```
cd packages/navigation
git checkout -b 4-driving
```

## Responsibilities

By having a look at `DriveRover`, we can guess that it has 1 reason to change:
the list of instruction might grow bigger.

This hints toward one new class: `Instruction`. Let's get cracking!

## Instruction

First let's bootstrap the test class using [phpspec](http://phpspec.net):

```
vendor/bin/phpspec describe 'MarsRover\Navigation\Instruction'
```

This will create the following `spec/MarsRover/Navigation/InstructionSpec.php`
file:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\Instruction;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class InstructionSpec extends ObjectBehavior
{
    function it_is_initializable()
    {
        $this->shouldHaveType(Instruction::class);
    }
}
```

We can edit it reusing what we've done in `DriveRover` test class, only with
more information about the possible instruction:

```php
<?php

namespace spec\MarsRover\Navigation;

use PhpSpec\ObjectBehavior;

class InstructionSpec extends ObjectBehavior
{
    const MOVE_FORWARD = 'move_forward';
    const TURN_LEFT = 'turn_left';
    const TURN_RIGHT = 'turn_right';

    const INVALID_INSTRUCTION = 'wake_up_polly_parrot';

    function it_can_be_move_forward()
    {
        $this->beConstructedWith(self::MOVE_FORWARD);

        $this->get()->shouldBe(self::MOVE_FORWARD);
    }

    function it_can_be_turn_left()
    {
        $this->beConstructedWith(self::TURN_LEFT);

        $this->get()->shouldBe(self::TURN_LEFT);
    }

    function it_can_be_turn_right()
    {
        $this->beConstructedWith(self::TURN_RIGHT);

        $this->get()->shouldBe(self::TURN_RIGHT);
    }

    function it_cannot_be_anything_else()
    {
        $this->beConstructedWith(self::INVALID_INSTRUCTION);

        $this->shouldThrow(
            \InvalidArgumentException::class
        )->duringInstantiation();
    }
}
```

Since this test is dedicated to instructions, we feel more free than in
`DriveRover` to describe all the possible instructions. If we run the tests
now, phpspec will bootstrap the `Instruction` class for us:

```
vendor/bin/phpspec run
```

Indeed, it created the `src/MarsRover/Navigation/Instruction.php` file:

```php
<?php

namespace MarsRover\Navigation;

class Instruction
{
    public function __construct($argument)
    {
    }

    public function get()
    {
    }
}
```

All that's left for us to do is complete it, we can reuse the code in
`DriveRover`:

```php
<?php

namespace MarsRover\Navigation;

class Instruction
{
    const MOVE_FORWARD = 'move_forward';
    const TURN_LEFT = 'turn_left';
    const TURN_RIGHT = 'turn_right';

    const VALID_INSTRUCTIONS = [
        self::MOVE_FORWARD,
        self::TURN_LEFT,
        self::TURN_RIGHT,
    ];

    private $instruction;

    public function __construct($instruction)
    {
        if (false === in_array($instruction, self::VALID_INSTRUCTIONS, true)) {
            throw new \InvalidArgumentException(
                'Instruction should be one of: '
                .implode(', ', self::VALID_INSTRUCTIONS)
            );
        }
        $this->instruction = $instruction;
    }

    public function get() : string
    {
        return $this->instruction;
    }
}
```

We can now run the tests:

```
vendor/bin/phpspec run
```

All green! `Instruction` is ready to be used in `DriveRover`, so let's update
its test:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\Instruction;
use PhpSpec\ObjectBehavior;

class DriveRoverSpec extends ObjectBehavior
{
    const DRIVING_INSTRUCTION = Instruction::MOVE_FORWARD;

    function it_has_a_driving_instruction()
    {
        $this->beConstructedWith(
            self::DRIVING_INSTRUCTION
        );

        $this->getInstruction()->get()->shouldBe(self::DRIVING_INSTRUCTION);
    }
}
```

We no longer need to check for invalid instructions as we trust `Instruction`
to take care of it for us. Now let's update its code:

```php
<?php

namespace MarsRover\Navigation;

class DriveRover
{
    private $instruction;

    public function __construct($instruction)
    {
        $this->instruction = new Instruction($instruction);
    }

    public function getInstruction() : Instruction
    {
        return $this->instruction;
    }
}
```

And that should make our tests pass:

```
vendor/bin/phpspec run
```

All green! We can refactor `Instruction` test class a bit, by reusing
`Instruction` constants:

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\Instruction;
use PhpSpec\ObjectBehavior;

class InstructionSpec extends ObjectBehavior
{
    const MOVE_FORWARD = Instruction::MOVE_FORWARD;
    const TURN_LEFT = Instruction::TURN_LEFT;
    const TURN_RIGHT = Instruction::TURN_RIGHT;

    const INVALID_INSTRUCTION = 'wake_up_polly_parrot';

    function it_can_be_move_forward()
    {
        $this->beConstructedWith(self::MOVE_FORWARD);

        $this->get()->shouldBe(self::MOVE_FORWARD);
    }

    function it_can_be_turn_left()
    {
        $this->beConstructedWith(self::TURN_LEFT);

        $this->get()->shouldBe(self::TURN_LEFT);
    }

    function it_can_be_turn_right()
    {
        $this->beConstructedWith(self::TURN_RIGHT);

        $this->get()->shouldBe(self::TURN_RIGHT);
    }

    function it_cannot_be_anything_else()
    {
        $this->beConstructedWith(self::INVALID_INSTRUCTION);

        $this->shouldThrow(
            \InvalidArgumentException::class
        )->duringInstantiation();
    }
}
```

Let's run the tests one last time:

```
vendor/bin/phpspec run
```

All *grin* ;) . That's enough for us to commit our work:

```
git add -A
git commit -m '4: Created Instruction'
```

## Conclusion

We've refactored `DriveRover` by extracting an `Instruction` value object. It
allowed us to write more tests to describe all the possible values.

## What's next

In the next article, we'll write the actual driving logic.
