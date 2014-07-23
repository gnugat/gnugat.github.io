---
layout: post
title: Learn Symfony2 - Conclusion
tags:
    - Symfony2
    - technical
    - Learn Symfony2 series
---

This is the conclusion of the series on learning
[the Symfony2 framework](http://symfony.com/).
Have a look at the five first ones:

1. {{ link('posts/2014-06-18-learn-sf2-composer-part-1.md', 'Composer') }}
2. {{ link('posts/2014-06-25-learn-sf2-empty-app-part-2.md', 'Empty application') }}
3. {{ link('posts/2014-07-02-learn-sf2-bundles-part-3.md', 'Bundles') }}
4. {{ link('posts/2014-07-12-learn-sf2-controllers-part-4.md', 'Controllers') }}
5. {{ link('posts/2014-07-20-learn-sf2-tests-part-5.md', 'Tests') }}

In the previous articles we created a tested application for the Knight of Ni
with the following files:

    .
    ├── app
    │   ├── AppKernel.php
    │   ├── cache
    │   │   └── .gitkeep
    │   ├── config
    │   │   ├── config_test.yml
    │   │   ├── config.yml
    │   │   └── routing.yml
    │   ├── logs
    │   │   └── .gitkeep
    │   └── phpunit.xml.dist
    ├── composer.json
    ├── composer.lock
    ├── src
    │   └── Knight
    │       └── ApplicationBundle
    │           ├── Controller
    │           │   └── ApiController.php
    │           ├── KnightApplicationBundle.php
    │           └── Tests
    │               └── Controller
    │                   └── ApiControllerTest.php
    ├── .gitignore
    └── web
        └── app.php

Running `composer install` should create a `vendor` directory, which we ignored
with git.

Here's the [repository where you can find the actual code](https://github.com/gnugat/learning-symfony2/tree/5-tests).

This article will be like a cheat sheet of what we saw in the previous ones.

## Composer

[Composer](https://getcomposer.org/) will help you install and update third
party libraries.

Download it once for all and install it in your global binaries:

    curl -sS https://getcomposer.org/installer | php
    sudo mv ./composer.phar /usr/local/bin/composer

It should then be executable like this: `composer`.

* install a third party library: `composer require [--dev] <vendor/name:version>`
* download the project's third party libraries: `composer install`
* update the project's third party libraries: `composer update`

The available third party libraries can be found on
[Packagist](https://packagist.org/).

Here's an explanation of [Composer version constraints by Igor](https://igor.io/2013/01/07/composer-versioning.html).

In these articles, we create a project from scratch, but the recommended way of
starting a Symfony2 application is to use the Composer bootstrap command:
`composer create-project <vendor/name> <path-to-install>`

You could use the [Symfony Standard Edition](https://github.com/symfony/symfony-standard)
(`symfony/framework-standard-edition`), or any other distribution.

I'd advise you to use an empty boilerplate with the
[Symfony Empty Edition](https://github.com/gnugat/symfony-empty):

    composer create-project gnugat/symfony-framework-empty-edition <path-to-install>

*Tip*: For the production server, use this command to install the project's
dependencies (the third party libraries):

    composer install --no-dev --optimize

## Bundles

They integrate your code with the framework. More specifically, they configure
the Kernel's dependency injection container.

*Note*: To learn more about Dependency Injection, have a look at the following
articles:

* {{ link('posts/2014-01-22-ioc-di-and-service-locator.md', 'Inversion of Control, Dependency Injection, Dependency Injection Container and Service Locator') }}
* {{ link('posts/2014-01-29-sf2-di-component-by-example.md', 'Symfony2 Dependency Injection component, by example') }}

The only bundle you'll need to create is the `ApplicationBundle`, where all your
code will be. Here's how to create a bundle:

1. create its directory: `mkdir -p src/<Vendor>/<Name>Bundle`
2. create its class: `$EDITOR src/<Vendor>/<Name>Bundle/<Vendor><Name>Bundle.php`
3. register it in the kernel: `$EDITOR app/AppKernel.php`

A Bundle class looks like this:

    <?php
    // File: src/Knight/ApplicationBundle/KnightApplicationBundle.php

    namespace Knight\ApplicationBundle;

    use Symfony\Component\HttpKernel\Bundle\Bundle;

    class KnightApplicationBundle extends Bundle
    {
    }

## Application

In your application, there's only a few files related to the Symfony2 framework.
Here's the list of the ones you'll usually edit.

### The application's kernel

The `app/AppKernel.php` file is where the bundles are registered and where the
configuration is loaded. You'll only need to edit it when you install a new
bundle.

Here's how we would proceed: first install the bundle via Composer:

    composer require [--dev] <vendor/name:version>

Then register it in the application's kernel:

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
                new Symfony\Bundle\AsseticBundle\AsseticBundle(),
                new Doctrine\Bundle\DoctrineBundle\DoctrineBundle(),
                new Sensio\Bundle\FrameworkExtraBundle\SensioFrameworkExtraBundle(),

                // Add your bundles here!
            );

            if (in_array($this->getEnvironment(), array('dev', 'test'))) {
                $bundles[] = new Symfony\Bundle\WebProfilerBundle\WebProfilerBundle();
                $bundles[] = new Sensio\Bundle\DistributionBundle\SensioDistributionBundle();
                $bundles[] = new Sensio\Bundle\GeneratorBundle\SensioGeneratorBundle();

                // Or here, if you want it to only be available in dev or test environment
            }

            return $bundles;
        }

        public function registerContainerConfiguration(LoaderInterface $loader)
        {
            $loader->load(__DIR__.'/config/config_'.$this->getEnvironment().'.yml');
        }
    }

### The routing configuration

The `app/config/routing.yml` file is where you will link a controller's action
to an URL. Here's an example:

    # File: app/config/routing.yml
    ni:
        path: /api/ni
        methods:
            - POST
        defaults:
            _controller: KnightApplicationBundle:Api:ni

    question_to_cross_the_bridge:
        path: /api/question/{number}
        methods:
            - GET
        defaults:
            _controller: KnightApplicationBundle:Api:question

As you can see, you can tell the routing to use placeholders, which will be then
available in the controller via the Request object:

    $request->query->get('number'); // query is an instance of ParameterBag

### Controllers, your entry point

Each route is associated to a controller's action.

A controller is a class located in `src/<Vendor>/ApplicationBundle/Controller`,
suffixed with `Controller`.

An action is a controller's public method, suffixed with `Action`, which takes
a `Request $request` parameter and must return an instance of the `Response`
object:

    <?php
    // File: src/Knight/ApplicationBundle/Controller/ApiController.php

    namespace Knight\ApplicationBundle\Controller;

    use Symfony\Bundle\FrameworkBundle\Controller\Controller;
    use Symfony\Component\HttpFoundation\Request;
    use Symfony\Component\HttpFoundation\Response;
    use Symfony\Component\HttpFoundation\JsonResponse;

    class ApiController extends Controller
    {
        public function niAction(Request $request)
        {
            $postedContent = $request->getContent();
            $postedValues = json_decode($postedContent, true);

            $answer = array('answer' => 'Ecky-ecky-ecky-ecky-pikang-zoop-boing-goodem-zoo-owli-zhiv');
            $statusCode = Response::HTTP_OK;
            if (!isset($postedValues['offering']) || 'shrubbery' !== $postedValues['offering']) {
                $answer['answer'] = 'Ni';
                $statusCode = Response::HTTP_UNPROCESSABLE_ENTITY;
            }

            return new JsonResponse($answer, $statusCode);
        }
    }

*Note*: you can create sub-directories in `src/<Vendor>/ApplicationBundle/Controller`,
allowing you to categorize your controllers. In the routing, this would look
like this: `KnightApplicationBundle:Subdirectory\Controller:action`.

### Functional tests

Of course you can use any test framework with a Symfony2 project. PHPUnit is one
of them, and a popular one, so we'll use it for our examples.

Functional tests mirror the controllers and check if the status code is
successful. If you're building an API, you can check more precisely the status
code:

    <?php
    // File: src/Knight/ApplicationBundle/Tests/Controller/ApiControllerTest.php

    namespace Knight\ApplicationBundle\Tests\Controller;

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

The `WebTestCase` class is provided by the framework: it creates an application
(just like we do in `web/app.php`), so you can send requests and test the
response.

### Where to put your own code

You can put your code anywhere in `src/<Vendor>/ApplicationBundle`.

Who said you needed to decouple your code from Symfony2? You can already write
decoupled code!

A convention is to create directories named after the type of objects it holds.
For example the `Controller` contains controller classes (which are suffixed
with `Controller`). You don't have to follow it though (except for controllers
and commands): use your best judgement!

## Conclusion

Symfony2 gets out of your way, the only class from the framework we need to use
is the controller, the request and the response.

The workflow is really simple:

1. Symfony2 converts the HTTP request into a `Request` object
2. the routing allows to execute a controller related to the current URL
3. the controller receives the `Request` object as a parameter and must return a
   `Response` object
4. Symfony2 converts the `Response` object into the HTTP response

### What should we do now?

Practice.

We now know the strict minimum about Symfony2, and the only way to learn more is
to practice, encounter new use cases, find answers in the
[documentation](http://symfony.com/doc/current/index.html) and ask questions on
[StackOverflow](http://stackoverflow.com/questions/tagged/symfony2) (if they
haven't been already asked).

If you really want to master Symfony2, then stay tuned: I'll start writing a new
series of articles!

### Previous articles

* {{ link('posts/2014-06-18-learn-sf2-composer-part-1.md', '1: Composer') }}
* {{ link('posts/2014-06-25-learn-sf2-empty-app-part-2.md', '2: Empty application') }}
* {{ link('posts/2014-07-02-learn-sf2-bundles-part-3.md', '3: Bundles') }}
* {{ link('posts/2014-07-12-learn-sf2-controllers-part-4.md', '4: Controllers') }}
* {{ link('posts/2014-07-20-learn-sf2-tests-part-5.md', '5: Tests') }}
