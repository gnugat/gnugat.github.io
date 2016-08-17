---
layout: post
title: Mars Rover, Driving
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

We just finished developing the first use case, so we can now get cracking on
the second one, Driving the rover:

> Once a rover has been landed on Mars it is possible to drive them, using
> instructions such as `move_forward` (keeps orientation, but moves along the
> `x` or `y` axis) or `turn_left` / `turn_right` (keeps the same coordinates,
> but changes the orientation).

## Drive Rover

Again, we start by creating a class with the name of our use case. It will
take care of doing a simple validation on the input provided by the user:

```
cd packages/navigation
git checkout -b 4-driving
```

Using [phpspec](http://www.phpspec.net/en/stable/), we bootstrap the test
class:

```
vendor/bin/phpspec describe 'MarsRover\Navigation\DriveRover'
```

This should generate this `spec/MarsRover/Navigation/DriveRoverSpec.php` class: 

```php
<?php

namespace spec\MarsRover\Navigation;

use MarsRover\Navigation\DriveRover;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class DriveRoverSpec extends ObjectBehavior
{
    function it_is_initializable()
    {
        $this->shouldHaveType(DriveRover::class);
    }
}
```

This leaves us the task of editing it to start describing input parameters:

```php
<?php

namespace spec\MarsRover\Navigation;

use PhpSpec\ObjectBehavior;

class DriveRoverSpec extends ObjectBehavior
{
    const DRIVING_INSTRUCTION = 'move_forward';

    function it_has_a_driving_instruction()
    {
        $this->beConstructedWith(
            self::DRIVING_INSTRUCTION
        );

        $this->getInstruction()->shouldBe(self::DRIVING_INSTRUCTION);
    }
}
```

We can now run the tests:

```
vendor/bin/phpspec run
```

This will generate the `src/MarsRover/Navigation/DriveRover.php` file:

```php
<?php

namespace MarsRover\Navigation;

class DriveRover
{
    private $argument;

    public function __construct($argument)
    {
        $this->argument = $argument;
    }

    public function getInstruction()
    {
    }
}
```

All we need to do is to edit it:

```php
<?php

namespace MarsRover\Navigation;

class DriveRover
{
    private $instruction;

    public function __construct($instruction)
    {
        $this->instruction = $instruction;
    }

    public function getInstruction() : string
    {
        return $this->instruction;
    }
}
```

Let's check the tests:

```
vendor/bin/phpspec run
```

All green! Now let's add some unhappy scenarios to our tests:

```php
<?php

namespace spec\MarsRover\Navigation;

use PhpSpec\ObjectBehavior;

class DriveRoverSpec extends ObjectBehavior
{
    const DRIVING_INSTRUCTION = 'move_forward';
    const INVALID_DRIVING_INSTRUCTION = 'wake_up_polly_parrot';

    function it_has_a_driving_instruction()
    {
        $this->beConstructedWith(
            self::DRIVING_INSTRUCTION
        );

        $this->getInstruction()->shouldBe(self::DRIVING_INSTRUCTION);
    }

    function it_cannot_have_invalid_instruction()
    {
        $this->beConstructedWith(
            self::INVALID_DRIVING_INSTRUCTION
        );

        $this->shouldThrow(
            \InvalidArgumentException::class
        )->duringInstantiation();
    }
}
```

We can run the tests:

```
vendor/bin/phpspec run
```

They fail! So let's complete the code:

```php
<?php

namespace MarsRover\Navigation;

class DriveRover
{
    const VALID_INSTRUCTIONS = [
        'move_forward',
        'turn_left',
        'turn_right',
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

    public function getInstruction() : string
    {
        return $this->instruction;
    }
}
```

And re-run the tests:

```
vendor/bin/phpspec run
```

All green! We can now commit our work:

```
git add -A
git commit -m '4: Created DriveRover'
```

## Conclusion

We've followed again the TDD methodology: write the test, then the code. We
took care of decribing first the happy scenario and then unhappy scenarios to
cover all the cases.

We've also used the same twist on the Command Bus pattern: we created a Command
class that describes the use case (drive the rover) and does a simple
validation on the input.

## What's next

In the next article, we'll proceed to the third step of TDD: refactoring
`DriveRover` by extracting `instruction` in its own class.
