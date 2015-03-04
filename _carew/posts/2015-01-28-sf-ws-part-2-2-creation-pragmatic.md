---
layout: post
title: Symfony / Web Services - part 2.2: Creation, the pragmatic way
tags:
    - Symfony
    - technical
    - Symfony / Web Services series
---

This is the third article of the series on managing Web Services in a
[Symfony](https://symfony.com) environment. Have a look at the two first ones:

* {{ link('posts/2015-01-14-sf-ws-part-1-introduction.md', '1. Introduction') }}.
* {{ link('posts/2015-01-21-sf-ws-part-2-1-creation-bootstrap.md', '2.1 Creation bootstrap') }}.

You can check the code in the [following repository](https://github.com/gnugat-examples/sf-ws).

In this post we'll see how to create profiles:

* [The controller](#creating-the-controller)
* [The profile entity](#the-profile-entity)
* [Linking with the database](#linking-with-the-database)
* [Managing errors](#managing-errors)
* [Conclusion](#conclusion)

## Creating the controller

First things first, we'll write a functional test:

```php
<?php
// File: tests/Controller/ProfileCreationControllerTest.php

namespace AppBundle\Tests\Controller;

use Symfony\Component\HttpFoundation\Request;

class ProfileCreationControllerTest extends \PHPUnit_Framework_TestCase
{
    private $app;

    protected function setUp()
    {
        $this->app = new \AppKernel('test', false);
        $this->app->boot();
    }

    public function testItCreatesProfiles()
    {
        $headers = array(
            'CONTENT_TYPE' => 'application/json',
            'PHP_AUTH_USER' => 'spanish_inquisition',
            'PHP_AUTH_PW' => 'NobodyExpectsIt!',
        );
        $body = json_encode(array('name' => 'Fawlty Towers'));
        $request = Request::create('/api/v1/profiles', 'POST', array(), array(), array(), $headers, $body);

        $response = $this->app->handle($request);

        $this->assertSame(201, $response->getStatusCode(), $response->getContent());
    }
}
```

The test should fail, because the route hasn't been found (`404 NOT FOUND`):

    phpunit -c app

Flabergast! The test fails with a `PHP Fatal error:  Class 'AppKernel' not found`!
Let's fix this by adding the forgotten PHP tag opening in the bootstrap file:

```php
<?php
// File: app/bootstrap.php

require __DIR__.'/bootstrap.php.cache';
require __DIR__.'/AppKernel.php';
```

Let's check how the tests react:

    phpunit -c app

Another failure: the database doesn't exist. We need to create it for the test
environment:

    php app/console doctrine:database:create --env=test

Let's run the tests once again:

    phpunit -c app

This time the test fails for the right reason: the page doesn't exist.
To fix this, we'll create an empty controller:

```php
<?php
// File: src/AppBundle/Controller/ProfileCreationController.php;

namespace AppBundle\Controller;

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
        $createdProfile = array();

        return new JsonResponse($createdProfile, 201);
    }
}
```

This should make the test pass:

    phpunit -c app

If an error occurs (404 not found), then it might be because of the cache:

    php app/console cache:clear --env=test
    phpunit -c app

Running tests is becoming cumbersome, let's make it easy using a Makefile:

```
# Makefile
test:
	php app/console cache:clear --env=test
	php app/console doctrine:database:create --env=test
	phpunit -c app
	php app/console doctrine:database:drop --force --env=test
```

> **Note**: mind the tabs, make doesn't support space indentation.

In order for this to work we'll need to drop the database (because it already exists):

    php app/console doctrine:database:drop --force --env=test

Tests can now be run using:

    make test

Everything's fine, we can commit our work:

    git add -A
    git commit -m 'Created profile creation endpoint'

## The profile entity

At this point, we'll need to store the profile in a database. For this purpose,
we'll use MySQL and Doctrine, so we'll need to create a profile entity.

We'll first generate a skeleton of its specification using [phpspec](http://phpspec.net):

    ./bin/phpspec describe 'AppBundle\Entity\Profile'

Then we'll edit the specification:

```php
<?php
// File: spec/AppBundle/Entity/ProfileSpec.php

namespace spec\AppBundle\Entity;

use PhpSpec\ObjectBehavior;

class ProfileSpec extends ObjectBehavior
{
    const NAME = 'Arthur Dent';

    function let()
    {
        $this->beConstructedWith(self::NAME);
    }

    function it_can_be_converted_to_array()
    {
        $this->toArray()->shouldBe(array(
            'id' => null,
            'name' => self::NAME,
        ));
    }
}
```

Since we're happy with this step, we'll generate a skeleton of the code:

    ./bin/phpspec run

Of course we need to edit it:

```php
<?php
// File: src/AppBundle/Entity/Profile.php

namespace AppBundle\Entity;

use Doctrine\ORM\Mapping as ORM;

/**
 * @ORM\Table(name="profile")
 * @ORM\Entity
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

Let's check if it satisfies our specification:

    ./bin/phpspec run

It does! With this we can generate our database:

    php app/console doctrine:database:create
    php app/console doctrine:schema:create

Let's update our Makefile:

```
# Makefile
prod:
	php app/console cache:clear --env=prod
	php app/console doctrine:database:create --env=prod
	php app/console doctrine:schema:create --env=prod

dev:
	php app/console cache:clear --env=dev
	php app/console doctrine:database:create --env=dev
	php app/console doctrine:schema:create --env=dev

test:
	php app/console cache:clear --env=test
	php app/console doctrine:database:create --env=test
	php app/console doctrine:schema:create --env=test
	phpunit -c app
	bin/phpspec run
	php app/console doctrine:database:drop --force --env=test
```

This allows us to also run phpspec for tests. Installing a project should be as
simple as:

    make

And for development we can use:

    make dev

> **Note**: trying to run a second time `make` or `make dev` will fail as the
> database already exists. We'll need to run respectively
> `php app/console doctrine:database:drop --force --env=prod` and
> `php app/console doctrine:database:drop --force --env=dev`, but we should really
> run those commands only once.

It is time to commit our progress:

    git add -A
    git commit -m 'Created Profile entity'

## Linking with the database

The only thing missing in our application is the actual creation of the profile.
Before doing anything with the code, we'll need to update our functional test:
we don't want the data to be actually persisted, as it would make the test fail
on a second run:

```
<?php
// File: tests/Controller/ProfileCreationControllerTest.php

namespace AppBundle\Tests\Controller;

use Symfony\Component\HttpFoundation\Request;

class ProfileCreationControllerTest extends \PHPUnit_Framework_TestCase
{
    private $app;
    private $em;

    protected function setUp()
    {
        $this->app = new \AppKernel('test', true);
        $this->app->boot();

        $this->em = $this->app->getContainer()->get('doctrine.orm.entity_manager');
        $this->em->beginTransaction();
    }

    public function testItCreatesProfiles()
    {
        $headers = array(
            'CONTENT_TYPE' => 'application/json',
            'PHP_AUTH_USER' => 'spanish_inquisition',
            'PHP_AUTH_PW' => 'NobodyExpectsIt!',
        );
        $body = json_encode(array('name' => 'Fawlty Towers'));
        $request = Request::create('/api/v1/profiles', 'POST', array(), array(), array(), $headers, $body);

        $response = $this->app->handle($request);

        $this->assertSame(201, $response->getStatusCode(), $response->getContent());
    }

    protected function tearDown()
    {
        $this->em->rollback();
        $this->em->close();
    }
}
```

Let's update the controller:

```php
<?php
// File: src/AppBundle/Controller/ProfileCreationController.php;

namespace AppBundle\Controller;

use AppBundle\Entity\Profile;
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
        $em = $this->get('doctrine.orm.entity_manager');

        $createdProfile = new Profile($request->request->get('name'));
        $em->persist($createdProfile);
        $em->flush();

        return new JsonResponse($createdProfile->toArray(), 201);
    }
}
```

Time to run the tests:

    make test

All green! We can commit:

    git add -A
    git commit -m 'Saved created profile in database'

## Managing errors

Our endpoint should return an error if the "name" parameter is missing. Let's add
a functional test for this:

```
<?php
// File: tests/Controller/ProfileCreationControllerTest.php

namespace AppBundle\Tests\Controller;

use Symfony\Component\HttpFoundation\Request;

class ProfileCreationControllerTest extends PHPUnit_Framework_TestCase
{
    private $app;
    private $em;

    protected function setUp()
    {
        $this->app = new \AppKernel('test', true);
        $this->app->boot();

        $this->em = $this->app->getContainer()->get('doctrine.orm.entity_manager');
        $this->em->beginTransaction();
    }

    public function testItCreatesProfiles()
    {
        $headers = array(
            'CONTENT_TYPE' => 'application/json',
            'PHP_AUTH_USER' => 'spanish_inquisition',
            'PHP_AUTH_PW' => 'NobodyExpectsIt!',
        );
        $body = json_encode(array('name' => 'Fawlty Towers'));
        $request = Request::create('/api/v1/profiles', 'POST', array(), array(), array(), $headers, $body);

        $response = $this->app->handle($request);

        $this->assertSame(201, $response->getStatusCode(), $response->getContent());
    }

    public function testItFailsIfNameIsMissing()
    {
        $headers = array(
            'CONTENT_TYPE' => 'application/json',
            'PHP_AUTH_USER' => 'spanish_inquisition',
            'PHP_AUTH_PW' => 'NobodyExpectsIt!',
        );
        $body = json_encode(array('no-name' => ''));
        $request = Request::create('/api/v1/profiles', 'POST', array(), array(), array(), $headers, $body);

        $response = $this->app->handle($request);

        $this->assertSame(422, $response->getStatusCode(), $response->getContent());
    }

    protected function tearDown()
    {
        $this->em->rollback();
        $this->em->close();
    }
}
```

It should make our tests fail:

    make test

We can make this test pass by adding a simple check:

```php
<?php
// File: src/AppBundle/Controller/ProfileCreationController.php;

namespace AppBundle\Controller;

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
        $em = $this->get('doctrine.orm.entity_manager');

        $name = $request->request->get('name');
        if (null === $name) {
            return new JsonResponse(array('error' => 'The "name" parameter is missing from the request\'s body'), 422);
        }
        $createdProfile = new Profile($name);
        $em->persist($createdProfile);
        $em->flush();

        return new JsonResponse($createdProfile->toArray(), 201);
    }
}
```

Let's see:

    php app/console doctrine:database:drop --force --env=test
    make test

> **Note**: Because our last test failed, the database hasn't been removed, so we
> need to do it manually.

Looks nice! Our endpoint should also fail when a profile with the same name
already exist:

```
<?php
// File: tests/Controller/ProfileCreationControllerTest.php

namespace AppBundle\Tests\Controller;

use Symfony\Component\HttpFoundation\Request;

class ProfileCreationControllerTest extends PHPUnit_Framework_TestCase
{
    private $app;
    private $em;

    protected function setUp()
    {
        $this->app = new \AppKernel('test', true);
        $this->app->boot();

        $this->em = $this->app->getContainer()->get('doctrine.orm.entity_manager');
        $this->em->beginTransaction();
    }

    public function testItCreatesProfiles()
    {
        $headers = array(
            'CONTENT_TYPE' => 'application/json',
            'PHP_AUTH_USER' => 'spanish_inquisition',
            'PHP_AUTH_PW' => 'NobodyExpectsIt!',
        );
        $body = json_encode(array('name' => 'Fawlty Towers'));
        $request = Request::create('/api/v1/profiles', 'POST', array(), array(), array(), $headers, $body);

        $response = $this->app->handle($request);

        $this->assertSame(201, $response->getStatusCode(), $response->getContent());
    }

    public function testItFailsIfNameIsMissing()
    {
        $headers = array(
            'CONTENT_TYPE' => 'application/json',
            'PHP_AUTH_USER' => 'spanish_inquisition',
            'PHP_AUTH_PW' => 'NobodyExpectsIt!',
        );
        $body = json_encode(array('no-name' => ''));
        $request = Request::create('/api/v1/profiles', 'POST', array(), array(), array(), $headers, $body);

        $response = $this->app->handle($request);

        $this->assertSame(422, $response->getStatusCode(), $response->getContent());
    }

    public function testItFailsIfNameAlreadyExists()
    {
        $headers = array(
            'CONTENT_TYPE' => 'application/json',
            'PHP_AUTH_USER' => 'spanish_inquisition',
            'PHP_AUTH_PW' => 'NobodyExpectsIt!',
        );
        $body = json_encode(array('name' => 'Provençal le Gaulois'));
        $request = Request::create('/api/v1/profiles', 'POST', array(), array(), array(), $headers, $body);

        $this->app->handle($request);
        $response = $this->app->handle($request);

        $this->assertSame(422, $response->getStatusCode(), $response->getContent());
    }

    protected function tearDown()
    {
        $this->em->rollback();
        $this->em->close();
    }
}
```

Our tests should be broken again:

    make test

Another check can fix this awful situation:

```php
<?php
// File: src/AppBundle/Controller/ProfileCreationController.php;

namespace AppBundle\Controller;

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

Are we there yet?

    php app/console doctrine:database:drop --force --env=test
    make test

Yes we are. Here's our last commit for this time:

    git add -A
    git commit -m 'Added error checks'

## Conclusion

Creating an endpoint with Symfony is pretty straighfoward: it all comes down to
HTTP knowledge.

Our codebase is very small due to the simplicity of our examples, but in a real
life application we'll need to add more complexity as new requirements appear.

The pragmatic approach is good for now, but at some point we'll need to refactor
our code by creating some services, each with their specific responsibilities,
to prevent our application from becoming a [big ball of mud](https://speakerdeck.com/richardmiller/atm)
where everything is hard to read, impossible to test and expensive to change.

This will the subject of {{ link('posts/2015-03-04-sf-ws-part-2-3-creation-refactoring.md', 'next week') }}'s article.
