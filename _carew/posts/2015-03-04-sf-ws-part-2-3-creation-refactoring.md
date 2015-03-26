---
layout: post
title: Symfony / Web Services - part 2.3: Creation, refactoring
tags:
    - Symfony
    - technical
    - Symfony / Web Services series
---

This is the fourth article of the series on managing Web Services in a
[Symfony](https://symfony.com) environment. Have a look at the three first ones:

* {{ link('posts/2015-01-14-sf-ws-part-1-introduction.md', '1. Introduction') }}
* {{ link('posts/2015-01-21-sf-ws-part-2-1-creation-bootstrap.md', '2.1 Creation bootstrap') }}
* {{ link('posts/2015-01-28-sf-ws-part-2-2-creation-pragmatic.md', '2.2 Creation, the pragmatic way') }}

You can check the code in the [following repository](https://github.com/gnugat-examples/sf-ws).

In the previous post we've created a first endpoint by taking a few shortcuts.
As we wouldn't want to get technical debt, we're going to refactor it.

## The controller responsibility

In order to [avoid the mud](https://speakerdeck.com/richardmiller/avoiding-the-mud),
we need to remove the logic from the controller. But which logic?

In [Symfony](https://symfony.com), controllers receive a Request and return a Response
(this follows the HTTP protocol). It is also the glue between the framework and our application.

From this we can assume that its responsibility is to:

1. extract the parameters from the Request
2. give it to our application
3. get a result and build the Response with it

The request's parameters could be legion, we woudln't like to have a method with too many arguments.
A way to solve this would be to create a Data Transfer Object (DTO): we would put all those parameters
in it and give it to the appropriate service.

## Command Bus

The Command Bus pattern is very fitting for this purpose: the DTO is called a Command, its name should
communicate our intention (in our example `CreateProfile`). It also has the responsibility of
validating user's input (for example converting IDs into integers).

Each Command is associated to only one CommandHandler service which do the actual logic.

Finally, there's the CommandBus: it finds the appropriate CommandHandler for the given Command
and executes it. It also executes some routines before and after the call (for example we can flush doctrine
after each commands).

> **Note**: CommandHandlers don't return anything.

If you want to find out more on the Command Bus pattern, I'd recommend you to
have a look at this series by Matthias Noback:

1. [a wave of command buses](http://php-and-symfony.matthiasnoback.nl/2015/01/a-wave-of-command-buses/)
2. [responsibilities of the command bus](http://php-and-symfony.matthiasnoback.nl/2015/01/responsibilities-of-the-command-bus/)
3. [from commands to events](http://php-and-symfony.matthiasnoback.nl/2015/01/from-commands-to-events/)
4. [some questions about the command bus](http://php-and-symfony.matthiasnoback.nl/2015/01/some-questions-about-the-command-bus/)
5. [collectiong events and the event dispatching comand bus](http://php-and-symfony.matthiasnoback.nl/2015/01/collecting-events-and-the-events-aware-command-bus/)

Since commands are all about sending a message, you can also read Mathias Verraes article on
[Messaging flavours](http://verraes.net/2015/01/messaging-flavours). He also wrote a nice
article on [Form, Command and Model validation](http://verraes.net/2015/02/form-command-model-validation/).

## SimpleBus

[SimpleBus](http://simplebus.github.io/MessageBus) is a small library that fits our purpose:

    composer require simple-bus/doctrine-orm-bridge
    composer require simple-bus/symfony-bridge

> **Note**: It requires at least PHP 5.4.

You need to register the bundle in our application's kernel:

```php
<?php
// File: app/AppKernel.php

use Symfony\Component\HttpKernel\Kernel;
use Symfony\Component\Config\Loader\LoaderInterface;

class AppKernel extends Kernel
{
    public function registerBundles()
    {
        $bundles = array(
            new Symfony\Bundle\FrameworkBundle\FrameworkBundle(),
            new Symfony\Bundle\SecurityBundle\SecurityBundle(),
            new Symfony\Bundle\TwigBundle\TwigBundle(),
            new Symfony\Bundle\MonologBundle\MonologBundle(),
            new Symfony\Bundle\SwiftmailerBundle\SwiftmailerBundle(),
            new Symfony\Bundle\AsseticBundle\AsseticBundle(),
            new Doctrine\Bundle\DoctrineBundle\DoctrineBundle(),
            new Sensio\Bundle\FrameworkExtraBundle\SensioFrameworkExtraBundle(),
            new SimpleBus\SymfonyBridge\SimpleBusCommandBusBundle(),
            new SimpleBus\SymfonyBridge\SimpleBusEventBusBundle(),
            new SimpleBus\SymfonyBridge\DoctrineOrmBridgeBundle(),
            new AppBundle\AppBundle(),
        );

        if (in_array($this->getEnvironment(), array('dev', 'test'))) {
            $bundles[] = new Symfony\Bundle\DebugBundle\DebugBundle();
            $bundles[] = new Symfony\Bundle\WebProfilerBundle\WebProfilerBundle();
            $bundles[] = new Sensio\Bundle\DistributionBundle\SensioDistributionBundle();
            $bundles[] = new Sensio\Bundle\GeneratorBundle\SensioGeneratorBundle();
        }

        return $bundles;
    }

    public function registerContainerConfiguration(LoaderInterface $loader)
    {
        $loader->load(__DIR__.'/config/config_'.$this->getEnvironment().'.yml');
    }
}
```

Let's commit this installation:

    git add -A
    git commit -m 'Installed SimpleBus'

## Create Profile

We didn't create a `ProfileRepository` earlier, but we're going to need it now:

```php
<?php
// File: src/AppBundle/Entity/ProfileRepository.php

namespace AppBundle\Entity;

use Doctrine\ORM\EntityRepository;

class ProfileRepository extends EntityRepository
{
}
```

We should name the Command after the action we want to do. In our case we want
to create a profile:

```php
<?php
// File: src/AppBundle\CommandBus/CreateProfile.php

namespace AppBundle\CommandBus;

use SimpleBus\Message\Message;

class CreateProfile implements Message
{
    public $name;

    public function __construct($name)
    {
        $this->name = $name;
    }
}
```

We then need a CommandHandler to do the actual creation. Since there will be some logic,
let's create a specification:

    ./bin/phpspec describe 'AppBundle\CommandBus\CreateProfileHandler'

And now we can describe it:

```php
<?php
// File: spec/AppBundle/CommandBus/CreateProfileHandlerSpec.php

namespace spec\AppBundle\CommandBus;

use AppBundle\CommandBus\CreateProfile;
use AppBundle\Entity\ProfileRepository;
use Doctrine\Common\Persistence\ObjectManager;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class CreateProfileHandlerSpec extends ObjectBehavior
{
    const NAME = 'John Cleese';

    function let(ObjectManager $objectManager, ProfileRepository $profileRepository)
    {
        $this->beConstructedWith($objectManager, $profileRepository);
    }

    function it_creates_a_profile(ObjectManager $objectManager, ProfileRepository $profileRepository)
    {
        $profileRepository->findOneBy(array('name' => self::NAME))->willReturn(null);
        $createdProfile = Argument::type('AppBundle\Entity\Profile');
        $objectManager->persist($createdProfile)->shouldBeCalled();

        $this->handle(new CreateProfile(self::NAME));
    }
}
```

This allows us to generate the code's skeleton:

    ./bin/phpspec run

And to finally write the code to make the test pass:

```php
<?php
// File: src/AppBundle/CommandBus/CreateProfileHandler.php

namespace AppBundle\CommandBus;

use AppBundle\Entity\Profile;
use AppBundle\Entity\ProfileRepository;
use Doctrine\Common\Persistence\ObjectManager;
use SimpleBus\Message\Handler\MessageHandler;
use SimpleBus\Message\Message;

class CreateProfileHandler implements MessageHandler
{
    private $objectManager;
    private $profileRepository;

    public function __construct(ObjectManager $objectManager, ProfileRepository $profileRepository)
    {
        $this->objectManager = $objectManager;
        $this->profileRepository = $profileRepository;
    }

    public function handle(Message $message)
    {
        $profile = $this->profileRepository->findOneBy(array('name' => $message->name));
        $newProfile = new Profile($message->name);
        $this->objectManager->persist($newProfile);
    }
}
```

Let's check the tests:

    ./bin/phpspec run

All green, we can commit:

    git add -A
    git commit -m 'Created CreateProfileHandler'

## Name duplication

Domain validation (e.g. name duplication check) should be handled by the CommandHandler
(previously it was done in the controller):

```php
<?php
// File: spec/AppBundle/CommandBus/CreateProfileHandlerSpec.php

namespace spec\AppBundle\CommandBus;

use AppBundle\CommandBus\CreateProfile;
use AppBundle\Entity\ProfileRepository;
use Doctrine\Common\Persistence\ObjectManager;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class CreateProfileHandlerSpec extends ObjectBehavior
{
    const NAME = 'John Cleese';

    function let(ObjectManager $objectManager, ProfileRepository $profileRepository)
    {
        $this->beConstructedWith($objectManager, $profileRepository);
    }

    function it_creates_a_profile(ObjectManager $objectManager, ProfileRepository $profileRepository)
    {
        $profileRepository->findOneBy(array('name' => self::NAME))->willReturn(null);
        $createdProfile = Argument::type('AppBundle\Entity\Profile');
        $objectManager->persist($createdProfile)->shouldBeCalled();

        $this->handle(new CreateProfile(self::NAME));
    }

    function it_cannot_create_the_profile_if_the_name_has_already_been_registered(ProfileRepository $profileRepository)
    {
        $profile = Argument::type('AppBundle\Entity\Profile');
        $profileRepository->findOneBy(array('name' => self::NAME))->willReturn($profile);

        $domainException = '\DomainException';
        $this->shouldThrow($domainException)->duringHandle(new CreateProfile(self::NAME));
    }
}
```

> **Note**: We try to be as descriptive as necessary in the test methods (a bad example
> would have been `testThrowsDomainException`).

Here's the code to make the test pass:

```php
<?php
// File: src/AppBundle/CommandBus/CreateProfileHandler.php

namespace AppBundle\CommandBus;

use AppBundle\Entity\Profile;
use AppBundle\Entity\ProfileRepository;
use Doctrine\Common\Persistence\ObjectManager;
use SimpleBus\Message\Handler\MessageHandler;
use SimpleBus\Message\Message;

class CreateProfileHandler implements MessageHandler
{
    private $objectManager;
    private $profileRepository;

    public function __construct(ObjectManager $objectManager, ProfileRepository $profileRepository)
    {
        $this->objectManager = $objectManager;
        $this->profileRepository = $profileRepository;
    }

    public function handle(Message $message)
    {
        $profile = $this->profileRepository->findOneBy(array('name' => $message->name));
        if (null !== $profile) {
            throw new \DomainException(sprintf('The name "%s" is already taken', $message->name));
        }
        $newProfile = new Profile($message->name);
        $this->objectManager->persist($newProfile);
    }
}
```

Let's check the tests:

    ./bin/phpspec run

They pass!

    git add -A
    git commit -m 'Added check on name duplication'

## Input validation

Input validation (e.g. presence of name parameter) should be done in the Command
(previously it was done in the controller):

```php
<?php
// File: src/AppBundle\CommandBus/CreateProfile.php

namespace AppBundle\CommandBus;

use SimpleBus\Message\Message;

class CreateProfile implements Message
{
    public $name;

    public function __construct($name)
    {
        if (null === $name) {
            throw new \DomainException('The "name" parameter is missing from the request\'s body');
        }
        $this->name = $name;
    }
}
```

Let's commit it:

    git add -A
    git commit -m 'Added check on name presence in the request'

## DomainExceptionListener

Our Command and CommandHandler both throw a DomainException, we can catch it in an
exception listener and create a nice response:

```php
<?php
// File: src/AppBundle/EventListener/DomainExceptionListener.php

namespace AppBundle\EventListener;

use DomainException;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpKernel\Event\GetResponseForExceptionEvent;

class DomainExceptionListener
{
    /**
     * @param GetResponseForExceptionEvent $event
     */
    public function onKernelException(GetResponseForExceptionEvent $event)
    {
        $exception = $event->getException();
        if (!$exception instanceof DomainException) {
            return;
        }
        $error = $exception->getMessage();
        $event->setResponse(new JsonResponse(array('error' => $error), 422));
    }
}
```

It needs to be registerd in the Dependency Injection Container:

```
# File: app/config/services.yml
services:
    app.submit_json_listener:
        class: AppBundle\EventListener\SubmitJsonListener
        tags:
            - { name: kernel.event_listener, event: kernel.request, method: onKernelRequest }

    app.forbidden_exception_listener:
        class: AppBundle\EventListener\ForbiddenExceptionListener
        tags:
            - { name: kernel.event_listener, event: kernel.exception, method: onKernelException, priority: 10 }

    app.domain_exception_listener:
        class: AppBundle\EventListener\DomainExceptionListener
        tags:
            - { name: kernel.event_listener, event: kernel.exception, method: onKernelException, priority: 10 }
```

We can save it:

    git add -A
    git commit -m 'Created DomainExceptionListener'

## Using the command

Now that our CommandHandler is ready, we'll define it as a service with its repository:

```
# File: app/config/services.yml
services:
    app.submit_json_listener:
        class: AppBundle\EventListener\SubmitJsonListener
        tags:
            - { name: kernel.event_listener, event: kernel.request, method: onKernelRequest }

    app.forbidden_exception_listener:
        class: AppBundle\EventListener\ForbiddenExceptionListener
        tags:
            - { name: kernel.event_listener, event: kernel.exception, method: onKernelException, priority: 10 }

    app.domain_exception_listener:
        class: AppBundle\EventListener\DomainExceptionListener
        tags:
            - { name: kernel.event_listener, event: kernel.exception, method: onKernelException, priority: 10 }

    app.profile_repository:
        class: AppBundle\Entity\ProfileRepository
        factory_service: doctrine.orm.default_entity_manager
        factory_method: getRepository
        arguments: ['AppBundle:Profile']

    app.create_profile_handler:
        class: AppBundle\CommandBus\CreateProfileHandler
        arguments:
            - "@doctrine.orm.entity_manager"
            - "@app.profile_repository"
        tags:
            - { name: command_handler, handles: AppBundle\CommandBus\CreateProfile }
```

And call it in the controller:

```php
<?php
// File: src/AppBundle/Controller/ProfileCreationController.php;

namespace AppBundle\Controller;

use AppBundle\CommandBus\CreateProfile;
use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Method;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
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
        $name = $request->request->get('name');

        $this->get('command_bus')->handle(new CreateProfile($name));
        $createdProfile = $this->get('app.profile_repository')->findOneBy(array('name' => $name));

        return new JsonResponse($createdProfile->toArray(), 201);
    }
}
```

> **Note**: Since the CommandHandler doesn't return anything, we need to call the repository
> to get the created profile.

As it happens, we've forgotten to set `ProfileRepository` in `Profile`'s `Entity` annotation.
Let's fix it now:

```php
<?php
// File: src/AppBundle/Entity/Profile.php

namespace AppBundle\Entity;

use Doctrine\ORM\Mapping as ORM;

/**
 * @ORM\Table(name="profile")
 * @ORM\Entity(repositoryClass="AppBundle\Entity\ProfileRepository")
 */
class Profile
{
    /**
     * @ORM\Column(name="id", type="integer")
     * @ORM\Id
     * @ORM\GeneratedValue(strategy="AUTO")
     */
    private $id;

    /**
     * @ORM\Column(name="name", type="string", unique=true)
     */
    private $name;

    public function __construct($name)
    {
        $this->name = $name;
    }

    public function toArray()
    {
        return array(
            'id' => $this->id,
            'name' => $this->name,
        );
    }
}
```

Did we break anything?

    make test

No, all tests are super green!

    git add -A
    git commit -m 'Used CreateProfileHandler in controller'

## Conclusion

Technical debt is something we should be able to manage. When the time comes to refactor,
design patterns can be a helpful tool.

CommandBus is a nice pattern which allows us to remove imperative logic from the controllers.
It's easy to write unit test for CommandHandlers, and they can be reused
(creating a profile is surely something we can need elsewhere in our application).

This article concludes the second part of this series on web services in a Symfony environment.
In the {{ link('posts/2015-03-11-sf-ws-part-3-1-consuming-request-handler.md', 'next one') }},
we'll start a new application which consumes the one we just created.

> **Note**: The web service we described also had a removal endpoint. Since there's not much else
> to learn, it won't be created in this series.

### Going further

A lot of things can be improved in the current application, here's some tips for those
who'd like to practice:

* name duplication is actually a "Conflict" type of error, not "Unprocessable Entity"
* we could use Symfony's validation component (use `validator` in the CommandHandler and set annotations in the Command)
* we could create a CommandBus that always validate the Command using Symfony's validation component
* we can create our own DomainException to avoid catching ones that could be thrown by third party libraries
