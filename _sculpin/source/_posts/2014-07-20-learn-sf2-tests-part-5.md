---
layout: post
title: Learn Symfony2 - part 5: Tests
tags:
    - Symfony
    - Learn Symfony2 series
---

This is the fifth article of the series on learning
[the Symfony2 framework](http://symfony.com/).
Have a look at the four first ones:

1. [Composer](/2014/06/18/learn-sf2-composer-part-1.html)
2. [Empty application](/2014/06/25/learn-sf2-empty-app-part-2.html)
3. [Bundles](/2014/07/02/learn-sf2-bundles-part-3.html)
4. [Controllers](/2014/07/12/learn-sf2-controllers-part-4.html)

In the previous articles we created an application for the Knight of Ni with the
following files:

    .
    ├── app
    │   ├── AppKernel.php
    │   ├── cache
    │   │   └── .gitkeep
    │   ├── config
    │   │   ├── config.yml
    │   │   └── routing.yml
    │   └── logs
    │       └── .gitkeep
    ├── composer.json
    ├── composer.lock
    ├── src
    │   └── Knight
    │       └── ApplicationBundle
    │           ├── Controller
    │           │   └── ApiController.php
    │           └── KnightApplicationBundle.php
    ├── .gitignore
    └── web
        └── app.php

Running `composer install` should create a `vendor` directory, which we ignored
with git.

Here's the [repository where you can find the actual code](https://github.com/gnugat/learning-symfony2/tree/4-controllers).

In this article, we'll create functional tests using PHPUnit.

## Installing PHPUnit

[PHPUnit](http://phpunit.de/) is a popular test framework.
Its name is deceptive: you can write any kind of test with it (unit, functional,
end to end, anything).

Let's install it in our project:

    composer require --dev "phpunit/phpunit:~4.1"

The `--dev` options will prevent Composer from installing PHPUnit when running
`composer install --no-dev`: this is use in production (download is costly).

We will need to create a configuration file to tell PHPUnit to execute the tests
found in `src/Knight/ApplicationBundle/Tests`, and to use Composer as an
autoloader:

    <?xml version="1.0" encoding="UTF-8"?>
    <!-- File: app/phpunit.xml.dist -->

    <!-- http://phpunit.de/manual/current/en/appendixes.configuration.html -->
    <phpunit
        backupGlobals="false"
        colors="true"
        syntaxCheck="false"
        bootstrap="../vendor/autoload.php">

        <testsuites>
            <testsuite name="Functional Test Suite">
                <directory>../src/Knight/ApplicationBundle/Tests</directory>
            </testsuite>
        </testsuites>

    </phpunit>

*Note*: [By convention](http://symfony.com/doc/current/cookbook/bundles/best_practices.html#directory-structure)
you should put your tests in `src/Knight/ApplicationBundle/Tests`. It's not hard
coded though, but if you want people to find things where they expect them to be
you better follow them ;) .

This file is suffixed with `.dist` because we intend to allow developer to
override the configuration by creating a `app/phpunit.xml` file. Only the
distribution file should be commited, though:

    echo '/app/phpunit.xml' >> .gitignore
    git add -A
    git commit -m 'Installed PHPUnit'

## Environments

For our functional tests, we will be using the `WebTestCase` class: it
instanciates our `AppKernel` with the `test` environment. It also uses a
`test.client` service, which is disabled by default.

In order to enable this service, we must change the configuration:

    # File: app/config/config.yml
    framework:
        secret: "Three can keep a secret, if two of them are dead."
        router:
            resource: %kernel.root_dir%/config/routing.yml

        # test: ~

Sometimes, you don't want your configuration to be the same for your tests and
your production server. That's what environments are for. Let's put this test
specific configuration in a different file:

    # File: app/config/config_test.yml
    imports:
        - { resource: config.yml }

    framework:
        test: ~

*Note*: the `imports` parameter allows you to include other configuration files.
You can then overwrite the included parameters, or add new ones.

We should also change the `registerContainerConfiguration` method of the
`AppKernel` class in order to load the test configuration, depending on the
environment:

    <?php
    // File: app/AppKernel.php

    use Symfony\Component\HttpKernel\Kernel;
    use Symfony\Component\Config\Loader\LoaderInterface;

    class AppKernel extends Kernel
    {
        public function registerBundles()
        {
            return array(
                new Symfony\Bundle\FrameworkBundle\FrameworkBundle(),
                new Knight\ApplicationBundle\KnightApplicationBundle(),
            );
        }

        public function registerContainerConfiguration(LoaderInterface $loader)
        {
            $file = 'config';
            if ('test' === $this->getEnvironment()) {
                $file .= '_test';
            }
            $loader->load(__DIR__."/config/$file.yml");
        }
    }

Let's commit our work:

    git add -A
    git commit -m 'Added test configuration'

## Functional tests

Our test must check that the application behaves as expected. We won't be
checking that it actually fulfills our business expectations. This means that
checking the HTTP status code is entirely sufficient.

Let's create the directory:

    mkdir -p src/Knight/ApplicationBundle/Tests/Controller

*Note*: Again, [by convention](http://symfony.com/doc/current/book/testing.html#unit-tests),
your test directory structure must mirror the one found in the bundle.

And then our first functional test:

    <?php
    // File: src/Knight/ApplicationBundle/Tests/Controller/ApiControllerTest.php

    namespace Knight/ApplicationBundle/Tests/Controller;

    use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

    class ApiControllerTest extends WebTestCase
    {
        public function testOfferingTheRightThing()
        {
            $method = 'POST';
            $uri = '/api/ni';
            $parameters = array();
            $files = array();
            $server = array();
            $content = json_encode(array(
                'offering' => 'shrubbery',
            ));

            $client = static::createClient();
            $client->request($method, $uri, $parameters, $files, $server, $content);
            $response = $client->getResponse();

            $this->assertTrue($response->isSuccessful());
        }
    }

To make sure the test pass, run the following command:

    ./vendor/bin/phpunit -c app

Composer has installed a binary in `vendor/bin`, and the `-c` option allows you
to tell PHPUnit where the configuration is (in `./app`).

This looks a bit long because of the content parameter... We can improve this
with helper methods:

    <?php
    // File: src/Knight/ApplicationBundle/Tests/Controller/ApiControllerTest.php

    namespace Knight/ApplicationBundle/Tests/Controller;

    use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

    class ApiControllerTest extends WebTestCase
    {
        private function post($uri, array $data)
        {
            $content = json_encode($data);
            $client = static::createClient();
            $client->request('POST', $uri, array(), array(), array(), $content);

            return $client->getResponse();
        }

        public function testOfferingTheRightThing()
        {
            $response = $this->post('/api/ni', array('offering' => 'shrubbery'));

            $this->assertTrue($response->isSuccessful());
        }
    }

Make sure the test still pass:

    ./vendor/bin/phpunit -c app

The Response's `isSuccessful` method only checks that the status code is 200ish.

Here's a test for failure cases:

    <?php
    // File: src/Knight/ApplicationBundle/Tests/Controller/ApiControllerTest.php

    namespace Knight/ApplicationBundle/Tests/Controller;

    use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;

    class ApiControllerTest extends WebTestCase
    {
        private function post($uri, array $data)
        {
            $content = json_encode($data);
            $client = static::createClient();
            $client->request('POST', $uri, array(), array(), array(), $content);

            return $client->getResponse();
        }

        public function testOfferingTheRightThing()
        {
            $response = $this->post('/api/ni', array('offering' => 'shrubbery'));

            $this->assertTrue($response->isSuccessful());
        }

        public function testOfferingTheWrongThing()
        {
            $response = $this->post('/api/ni', array('offering' => 'hareng'));

            $this->assertFalse($response->isSuccessful());
        }
    }

Run the tests:

    ./vendor/bin/phpunit -c app

*Note*: At this point running the tests should become a habit. Make sure to run
them whenever you finish a change, and to run them before commiting anything.

## Rest API functional tests

In my humble opinion, checking if the status code is 200ish and not checking the
response content is entirely sufficient for functional tests.

When creating REST API, it can prove useful to test more precisely the status
code. Our application is a REST API, so let's do this:

    <?php
    // File: src/Knight/ApplicationBundle/Tests/Controller/ApiControllerTest.php

    namespace Knight/ApplicationBundle/Tests/Controller;

    use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;
    use Symfony\Component\HttpFoundation\Response;

    class ApiControllerTest extends WebTestCase
    {
        private function post($uri, array $data)
        {
            $content = json_encode($data);
            $client = static::createClient();
            $client->request('POST', $uri, array(), array(), array(), $content);

            return $client->getResponse();
        }

        public function testOfferingTheRightThing()
        {
            $response = $this->post('/api/ni', array('offering' => 'shrubbery'));

            $this->assertSame(Response::HTTP_OK , $response->getStatusCode());
        }

        public function testOfferingTheWrongThing()
        {
            $response = $this->post('/api/ni', array('offering' => 'hareng'));

            $this->assertSame(Response::HTTP_UNPROCESSABLE_ENTITY , $response->getStatusCode());
        }
    }

Run the tests:

    ./vendor/bin/phpunit -c app

All green! That's comforting enough for us to commit our work and call it a day!

    git add -A
    git commit -m 'Added tests'

## Conclusion

Running `./vendor/bin/phpunit -c app` is less cumbersome than having to run
manually HTTPie (like in the previous article)!

Writing functional tests is easy and quick, the only thing you need to do is
check if the HTTP response's status code is successful (and for REST API you
need to check the precise HTTP response's status code).

The next article will be the conclusion of this series, I hope you enjoyed it!
