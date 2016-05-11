---
layout: post
title: Towards CQRS, Command Bus
tags:
    - cqrs
    - command bus
---

> **TL;DR**: The `Command Bus` pattern can help you get the CQRS "Command" part right.

By following the [Command / Query Responsibility Segregation](http://martinfowler.com/bliki/CQRS.html)
(CQRS) principle, we separate "write" logic from "read" logic.
This can be applied on many levels, for example on the macro one we can have a
single "Publisher" server (write) with many "Subscribers" servers (read), and on
a micro level we can use this principle to keep our controllers small.

However, transitioning from a regular mindset to a CQRS one can be difficult.

In this article, we'll explore the "Command Bus" pattern, to help us to get the
Command (write) part right.

## Starting Example

Let's take the following code for our example:

```php
<?php
// File: src/AppBundle/Controller/ProfileCreationController.php;

namespace AppBundle\Controller;

use AppBundle\Entity\Profile;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Method;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;

class ProfileCreationController extends Controller
{
    /**
     * @Route("/api/v1/profiles")
     * @Method({"POST"})
     */
    public function createProfileAction(Request $request)
    {
        $em = $this->get('doctrine.orm.entity_manager');

        $name = $request->request->get('name');
        if (null === $name) {
            return new JsonResponse(array('error' => 'The "name" parameter is missing from the request\'s body'), 422);
        }
        if (null !== $em->getRepository('AppBundle:Profile')->findOneByName($name)) {
            return new JsonResponse(array('error' => 'The name "'.$name.'" is already taken'), 422);
        }
        $createdProfile = new Profile($name);
        $em->persist($createdProfile);
        $em->flush();

        return new JsonResponse($createdProfile->toArray(), 201);
    }
}
```

It's an endpoint allowing us to create new "profiles". All the logic is done in
the Controller:

* we get a `name` parameter from the `Request`
* we validate it (is it missing? Does it duplicate an existing name?)
* we create a new `Profile` out of it
* we persist it
* we return it as JSON in the `Response`

## Command Bus

The Command Bus pattern relies on 3 types of classes:

* `Command`: encapsulate our input, does simple validation on it
* `CommandHandler`: dedicated to a single `Command`, does the actual logic

Finally there's a `CommandBus` interface allowing us to build `Middlewares`:

1. we can have a `CommandBus` that calls the appropriate `CommandHandle` for the given `Command`
2. we can have a `CommandBus` that wraps the above one in a database transaction
3. we can have a `CommandBus` that wraps the above ones to logs all incoming commands
4. we can have a `CommandBus` that wraps the above ones to check permissions
5. etc

`Middlewares` can do any action we want before and/or after the wrapped `CommandBus`.
They can be nested in a specific order, allowing us a fine grained control over
how the `Command` will be handled.

## Using Command Bus in the controller

Using our previous example, we're going to create the `Command` first. It needs
to contain all the input parameters, do a simple validation on it and have an
intention revealing name describing the action we'd like to do:

```php
<?php
// File: src/AppBundle/Profile/CreateNewProfile.php;

namespace AppBundle\Profile;

class CreateNewProfile
{
    public $name;

    public function __construct($name)
    {
        if (null === $name) {
            throw new \DomainException('Missing required "name" parameter');
        }
        $this->name = (string) $name;
    }
}
```

Unit tests can be created for Commands, to document their input requirements:

```php
<?php
// File: tests/AppBundle/Profile/CreateNewProfileTest.php;

namespace tests\AppBundle\Profile;

use AppBundle\Profile\CreateNewProfile;

class CreateNewProfileTest extends \PHPUnit_Framework_TestCase
{
    const NAME = 'Arthur Dent';

    private $checkProfileNameDuplicates;
    private $saveNewProfile;
    private $createNewProfileHandler;

    /**
     * @test
     */
    public function it_has_a_name()
    {
        $createNewProfile = new CreateNewProfile(self::NAME);

        self::assertSame(self::NAME, $createNewProfile->name);
    }

    /**
     * @test
     */
    public function it_cannot_miss_a_name()
    {
        $this->expectException(\DomainException::class);
        $createNewProfile = new CreateNewProfile(null);
    }
}
```

The second step is to create the `CommandHandler`. It needs to do more complex
validation, and the actual logic associated to the `Command`'s intention:

```php
<?php
// File: src/AppBundle/Profile/CreateNewProfileHandler.php;

namespace AppBundle\Profile;

use AppBundle\Entity\Profile;
use Doctrine\ORM\EntityManager;

class CreateNewProfileHandler
{
    private $entityManager;

    public function __construct(EntityManager $entityManager)
    {
        $this->entityManager = $entityManager;
    }

    public function handle(CreateNewProfile $createNewProfile)
    {
        if (null !== $this->entityManager->getRepository('AppBundle:Profile')->findOneByName($createNewProfile->name)) {
            throw new \DomainException("Invalid \"name\" parameter: \"$name\" already exists and duplicates are not allowed");
        }
        $createdProfile = new Profile($name);
        $em->persist($createdProfile);
        $em->flush();

        return $createdProfile
    }
}
```

> **Note**: a unit test can be created for CommandHandlers, to document use cases
> and their edge cases (happy and unhappy scenario).

Finally we can use the Command Bus in our controller:

```php
<?php
// File: src/AppBundle/Controller/ProfileCreationController.php;

namespace AppBundle\Controller;

use AppBundle\Profile\CreateNewProfile;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Method;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;

class ProfileCreationController extends Controller
{
    /**
     * @Route("/api/v1/profiles")
     * @Method({"POST"})
     */
    public function createProfileAction(Request $request)
    {
        try {
            $createdProfile = $this->get('command_bus')->handle(new CreateNewProfile(
                $request->request->get('name')
            ));
        } catch (\DomainException $e) {
            return new JsonResponse(array('error' => $e->getMessage()), 422);
        }

        return new JsonResponse($createdProfile->toArray(), 201);
    }
}
```

> **Note**: Exceptions could be handled in an event listener.

## Refactoring the Command Handler

Our Command Handler is tightly coupled to Doctrine. We can [decouple from libraries](/2015/10/12/decouple-from-libraries.html)
by introducing interfaces:

```php
<?php
// File: src/AppBundle/Profile/CreateNewProfileHandler.php;

namespace AppBundle\Profile;

use AppBundle\Profile\Service\CheckProfileNameDuplicates;
use AppBundle\Profile\Service\SaveNewProfile;

class CreateNewProfileHandler
{
    private $checkProfileNameDuplicates;
    private $saveNewProfile;

    public function __construct(
        CheckProfileNameDuplicates $checkProfileNameDuplicates,
        SaveNewProfile $saveNewProfile
    ) {
        $this->checkProfileNameDuplicates = $checkProfileNameDuplicates;
        $this->saveNewProfile = $saveNewProfile;
    }

    public function handle(CreateNewProfile $createNewProfile)
    {
        if (true !== $this->checkProfileNameDuplicates->check($createNewProfile->name)) {
            throw new \DomainException("Invalid \"name\" parameter: \"$name\" already exists and duplicates are not allowed");
        }
        $newProfile = new Profile($name); // Entity moved to Profile namespace
        $this->saveNewProfile->save($newProfile);

        return $newProfile
    }
}
```

In this way, it becomes much easier to write a unit test:

```php
<?php
// File: tests/AppBundle/Profile/CreateNewProfileHandlerTest.php;

namespace tests\AppBundle\Profile;

use AppBundle\Profile\CreateNewProfile;
use AppBundle\Profile\CreateNewProfileHandler;
use AppBundle\Profile\Profile;
use AppBundle\Profile\Service\CheckProfileNameDuplicates;
use AppBundle\Profile\Service\SaveNewProfile;
use Prophecy\Argument;

class CreateNewProfileHandlerTest extends \PHPUnit_Framework_TestCase
{
    const NAME = 'Arthur Dent';

    private $checkProfileNameDuplicates;
    private $saveNewProfile;
    private $createNewProfileHandler;

    protected function setUp()
    {
        $this->checkProfileNameDuplicates = $this->prophesize(CheckProfileNameDuplicates::class);
        $this->saveNewProfile = $this->prophesize(SaveNewProfile::class);

        $this->createNewProfileHandler = new CreateNewProfileHandler(
            $this->checkProfileNameDuplicates,
            $this->saveNewProfile
        );
    }

    /**
     * @test
     */
    public function it_creates_new_profiles()
    {
        $createNewProfile = new CreateNewProfile(self::NAME);

        $this->checkProfileNameDuplicates->check(self::NAME)->willReturn(false);
        $this->saveNewProfile->save(Argument::type(Profile::class))->shouldBeCalled();

        self::assertType(
            Profile::class,
            $this->createNewProfileHandler->handle($createNewProfile)
        );
    }

    /**
     * @test
     */
    public function it_cannot_create_profiles_with_duplicated_name()
    {
        $createNewProfile = new CreateNewProfile(self::NAME);

        $this->checkProfileNameDuplicates->check(self::NAME)->willReturn(true);
        $this->saveNewProfile->save(Argument::type(Profile::class))->shouldNotBeCalled();

        $this->expectException(\DomainException::class);
        $this->createNewProfileHandler->handle($createNewProfile);
    }
}
```

Doctrine implementations are easy to write, for example `CheckProfileNameDuplicates`:

```php
<?php

namespace AppBundle\Profile\Bridge;

use AppBundle\Profile\Service\CheckProfileNameDuplicates;
use Doctrine\ORM\EntityManager;

class DoctrineCheckProfileNameDuplicates implements CheckProfileNameDuplicates
{
    private $entityManager;

    public function __construct($entityManager)
    {
        $this->entityManager = $entityManager;
    }

    public function check(name)
    {
        return null === $this->entityManager->getRepository('AppBundle:Profile')->findOneByName($name));
    }
}
```

## To sum up

With the Command Bus pattern, we've reduced our controller to the following
repsonsibilities:

* Create a Command by extracting input parameters from the Request
* Create a Response by using the Command Handler returned value (via the Command Bus)

Our Command allows us to make explicit all input parameters and their requirements
(thanks to its unit tests, and by doing a simple validation on them).

Our Command Handler allows us to make explicit the actual logic with and to
highlight its edge cases in tests.

While refactoring our controller, we took the opportunity to use the Dependency
Inversion Principle to decouple our code from thrid party libraries (Doctrine).
This was simply done by introducing interfaces, which have the benefit to provide
more explicit names.

## Conclusion

The best way to learn how to get the Command part in CQRS right is to start using
the Command Bus pattern. And to abuse it, by using it everywhere and returning
values from Command Handlers.

Once we feel more at ease with the Command Bus pattern, we can start considering
alternative uses:

* do we really need a Command Bus? For example do we use any Middlewares?
* do we really need to return a value from the Command Handler? For example with asynchronous commands?
* do we really need to use it everywhere? For example in "read" endpoints?

We might realize that ditching the Command Bus and keeping the Command Handler
and the Command can still be beneficial. We also might realize that Commands don't
solve our "read" logic...

In the next article, we'll experiment with a "Search Engine" pattern to try to
get the Query part of CQRS right!

In the meantime, here's some resources related to Command Bus and CQRS:

* [CommandBus](http://shawnmc.cool/command-bus)
  by [Shawn McCool](https://twitter.com/ShawnMcCool)
* [What am I missing with this whole command bus (reddit question)](https://www.reddit.com/r/PHP/comments/29a6qz/what_am_i_missing_with_this_whole_command_bus/)
* [A wave of command buses (series)](http://php-and-symfony.matthiasnoback.nl/tags/SimpleBus/)
  by [Matthias Noback](https://twitter.com/matthiasnoback)
* [Avoid the Mud (slides)](https://speakerdeck.com/richardmiller/avoiding-the-mud)
  by [Richard Miller](https://twitter.com/mr_r_miller)
* [Messaging Flavours](http://verraes.net/2015/01/messaging-flavours/)
  and [Form, Command, Model validation](http://verraes.net/2015/02/form-command-model-validation/)
  and also [Functional Foundation for CQRS/ES](http://verraes.net/2014/05/functional-foundation-for-cqrs-event-sourcing/)
  by [Mathias Verraes](https://twitter.com/mathiasverraes)
* [Tactician](http://tactician.thephpleague.com/), a simple Command Bus library for PHP
* [Clarified CQRS](http://www.udidahan.com/2009/12/09/clarified-cqrs/)
  by [Udi Dahan](https://twitter.com/UdiDahan)
