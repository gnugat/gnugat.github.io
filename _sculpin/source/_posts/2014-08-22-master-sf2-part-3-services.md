---
layout: post
title: Master Symfony2 - part 3: Services
tags:
    - symfony
    - master symfony2 series
---

This is the third article of the series on mastering the
[Symfony2](http://symfony.com/) framework. Have a look at the two first ones:

* [1: Bootstraping](/2014/08/05/master-sf2-part-1-bootstraping.html)
* [2: TDD](/2014/08/13/master-sf2-part-2-tdd.html)

In the previous articles we created an API allowing us to submit new quotes:

    .
    ├── app
    │   ├── AppKernel.php
    │   ├── cache
    │   │   └── .gitkeep
    │   ├── config
    │   │   ├── config_prod.yml
    │   │   ├── config_test.yml
    │   │   ├── config.yml
    │   │   ├── parameters.yml
    │   │   ├── parameters.yml.dist
    │   │   └── routing.yml
    │   ├── logs
    │   │   └── .gitkeep
    │   └── phpunit.xml.dist
    ├── composer.json
    ├── composer.lock
    ├── src
    │   └── Fortune
    │       └── ApplicationBundle
    │           ├── Controller
    │           │   └── QuoteController.php
    │           ├── FortuneApplicationBundle.php
    │           └── Tests
    │               └── Controller
    │                   └── QuoteControllerTest.php
    └── web
        └── app.php

Here's the [repository where you can find the actual code](https://github.com/gnugat/mastering-symfony2).

In this one we'll list the existing quotes and learn about entities, services,
the repository design pattern and dependency injection.

## Defining the second User Story

By the time we finished to implement the first User Story, Nostradamus (our
customer and product owner) wrote the second one:

    As a User
    I want to be able to read the available quotes
    In order to find interesting ones

Currently we don't persist our quotes, but now we will need to. However I'd like
to dedicate a separate article to database persistence, so we will save our
quotes in a file and concentrate on services.

## The quote entity

Until now we wrote our code in the controller and it was ok, as there wasn't
much code. But now our application will grow, so we need to put the code
elsewhere: in the services.

Basically a service is just a class which does one thing (and does it well).
They are stateless, which means that calling a method many times with the same
parameter should always return the same value.

They manipulate entities which are classes representing the data. Those don't
have any behavior. Let's create the `Entity` directory:

    mkdir src/Fortune/ApplicationBundle/Entity

And now we'll write the `Quote` entity:

    <?php
    // File: src/Fortune/ApplicationBundle/Entity/Quote.php

    namespace Fortune\ApplicationBundle\Entity;

    class Quote
    {
        private $id;
        private $content;

        public function __construct($id, $content)
        {
            $this->id = $id;
            $this->content = $content;
        }

        public function getId()
        {
            return $this->id;
        }

        public function getContent()
        {
            return $this->content;
        }
    }

There's no need to write a unit test for it: it doesn't contain any logic. The
tests of its services (which manipulate it) will be enough.

## The repository service

We'll create a persistence service which will follow the
[Repository design pattern](http://code.tutsplus.com/tutorials/the-repository-design-pattern--net-35804):
the repository calls a gateway to retreive some raw data and transforms it using
a factory.

Before creating it, we will write a unit test which will help us to specify how
it should work. Here's its directory:

    mkdir src/Fortune/ApplicationBundle/Tests/Entity

And its code:

    <?php
    // File: src/Fortune/ApplicationBundle/Tests/Entity/QuoteRepositoryTest.php

    namespace Fortune\ApplicationBundle\Tests\Entity;

    use Fortune\ApplicationBundle\Entity\QuoteFactory;
    use Fortune\ApplicationBundle\Entity\QuoteGateway;
    use Fortune\ApplicationBundle\Entity\QuoteRepository;

    class QuoteRepositoryTest extends \PHPUnit_Framework_TestCase
    {
        const CONTENT = '<KnightOfNi> Ni!';

        private $repository;

        public function setUp()
        {
            $filename = '/tmp/fortune_database_test.txt';
            $gateway = new QuoteGateway($filename);
            $factory = new QuoteFactory();
            $this->repository = new QuoteRepository($gateway, $factory);
        }

        public function testItPersistsTheQuote()
        {
            $quote = $this->repository->insert(self::CONTENT);
            $id = $quote['quote']['id'];
            $quotes = $this->repository->findAll();
            $foundQuote = $quotes['quotes'][$id];

            $this->assertSame(self::CONTENT, $foundQuote['content']);
        }
    }

Now we can create the class which should make the test pass:

    <?php
    // File: src/Fortune/ApplicationBundle/Entity/QuoteRepository.php

    namespace Fortune\ApplicationBundle\Entity;

    class QuoteRepository
    {
        private $gateway;
        private $factory;

        public function __construct(QuoteGateway $gateway, QuoteFactory $factory)
        {
            $this->gateway = $gateway;
            $this->factory = $factory;
        }

        public function insert($content)
        {
            $quote = $this->gateway->insert($content);

            return $this->factory->makeOne($quote);
        }

        public function findAll()
        {
            $quotes = $this->gateway->findAll();

            return $this->factory->makeAll($quotes);
        }
    }

See what we've done in the constructor? That's dependency injection (passing
arguments on which the class relies).

**Note**: for more information about the Dependency Injection,
[you can read this article](/2014/01/22/ioc-di-and-service-locator.html).

### The gateway service

The gateway is the class where the actual persistence is done:

    <?php
    // File: src/Fortune/ApplicationBundle/Entity/QuoteGateway.php

    namespace Fortune\ApplicationBundle\Entity;

    class QuoteGateway
    {
        private $filename;

        public function __construct($filename)
        {
            $this->filename = $filename;
        }

        public function insert($content)
        {
            $content = trim($content);
            $line = $content."\n";
            file_put_contents($this->filename, $line, FILE_APPEND);
            $lines = file($this->filename);
            $lineNumber = count($lines) - 1;

            return new Quote($lineNumber, $content);
        }

        public function findAll()
        {
            $contents = file($this->filename);
            foreach ($contents as $id => $content) {
                $quotes[$id] = new Quote($id, trim($content));
            }

            return $quotes;
        }
    }

Wait a minute, we didn't write any test for this class! Well, that's because
`QuoteRepositoryTest` already covers it.

## The factory service

The factroy converts the object returned by the gateway to something usable by
the controller (a JSONable array):

    <?php
    // File: src/Fortune/ApplicationBundle/Entity/QuoteFactory.php

    namespace Fortune\ApplicationBundle\Entity;

    class QuoteFactory
    {
        public function makeOne(Quote $rawQuote)
        {
            return array('quote' => $this->make($rawQuote));
        }

        public function makeAll(array $rawQuotes)
        {
            foreach ($rawQuotes as $rawQuote) {
                $quotes['quotes'][$rawQuote->getId()] = $this->make($rawQuote);
            }

            return $quotes;
        }

        private function make(Quote $rawQuote)
        {
            return array(
                'id' => $rawQuote->getId(),
                'content' => $rawQuote->getContent(),
            );
        }
    }

No unit test for this factory: the one for the repository already covers it.
Now that the code is written, we can check that the test pass:

    ./vendor/bin/phpunit -c app

## Using the service in the controller

The controller responsibility is to retrieve the parameters from the request,
inject them in a service and then use its return value to create a response.
We won't construct directly the `QuoteRepository` service in the controller:
Symfony2 comes with a [Dependency Injection Container](http://symfony.com/doc/current/components/dependency_injection/introduction.html) (DIC).
In a nutshell when you ask the container a service, it will construct it for
you.

The first thing we need is to prepare the bundle by creating the following
directories:

    mkdir src/Fortune/ApplicationBundle/DependencyInjection
    mkdir -p src/Fortune/ApplicationBundle/Resources/config

Then we need to create a class which will load the bundle's services into the
DIC:

    <?php
    // File: src/Fortune/ApplicationBundle/DependencyInjection/FortuneApplicationExtension.php

    namespace Fortune\ApplicationBundle\DependencyInjection;

    use Symfony\Component\DependencyInjection\ContainerBuilder;
    use Symfony\Component\Config\FileLocator;
    use Symfony\Component\HttpKernel\DependencyInjection\Extension;
    use Symfony\Component\DependencyInjection\Loader\XmlFileLoader;

    class FortuneApplicationExtension extends Extension
    {
        public function load(array $configs, ContainerBuilder $container)
        {
            $fileLocator = new FileLocator(__DIR__.'/../Resources/config');
            $loader = new XmlFileLoader($container, $fileLocator);

            $loader->load('services.xml');
        }
    }

As you can see, we told the extension to look for a configuration file. Here it
is:

    <?xml version="1.0" ?>
    <!-- File: src/Fortune/ApplicationBundle/Resources/config/services.xml -->

    <container xmlns="http://symfony.com/schema/dic/services"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://symfony.com/schema/dic/services http://symfony.com/schema/dic/services/services-1.0.xsd">
        <services>
            <service id="fortune_application.quote_factory"
                class="Fortune\ApplicationBundle\Entity\QuoteFactory"
            >
            </service>
            <service id="fortune_application.quote_gateway"
                class="Fortune\ApplicationBundle\Entity\QuoteGateway"
            >
                <argument>/tmp/fortune_database.txt</argument>
            </service>
            <service id="fortune_application.quote_repository"
                class="Fortune\ApplicationBundle\Entity\QuoteRepository"
            >
                <argument type="service" id="fortune_application.quote_gateway" />
                <argument type="service" id="fortune_application.quote_factory" />
            </service>
        </services>
    </container>

Now `QuoteRepository` is available in the controller:

    <?php
    // File: src/Fortune/ApplicationBundle/Controller/QuoteController.php

    namespace Fortune\ApplicationBundle\Controller;

    use Symfony\Bundle\FrameworkBundle\Controller\Controller;
    use Symfony\Component\HttpFoundation\Request;
    use Symfony\Component\HttpFoundation\Response;
    use Symfony\Component\HttpFoundation\JsonResponse;

    class QuoteController extends Controller
    {
        public function submitAction(Request $request)
        {
            $postedContent = $request->getContent();
            $postedValues = json_decode($postedContent, true);
            if (empty($postedValues['content'])) {
                $answer = array('message' => 'Missing required parameter: content');

                return new JsonResponse($answer, Response::HTTP_UNPROCESSABLE_ENTITY);
            }
            $quoteRepository = $this->container->get('fortune_application.quote_repository');
            $quote = $quoteRepository->insert($postedValues['content']);

            return new JsonResponse($quote, Response::HTTP_CREATED);
        }
    }

We can now make sure that everything is fine by running the tests:

    ./vendor/bin/phpunit -c app

**Note**: for more information about Symfony2 Dependency Injection Component
[you can read this article](/2014/01/29/sf2-di-component-by-example.html).

## Listing quotes

It's now time to fulfill the second user story, starting with a functional test:

    <?php
    // File: src/Fortune/ApplicationBundle/Tests/Controller/QuoteControllerTest.php

    namespace Fortune\ApplicationBundle\Tests\Controller;

    use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;
    use Symfony\Component\HttpFoundation\Response;

    class QuoteControllerTest extends WebTestCase
    {
        private function post($uri, array $data)
        {
            $headers = array('CONTENT_TYPE' => 'application/json');
            $content = json_encode($data);
            $client = static::createClient();
            $client->request('POST', $uri, array(), array(), $headers, $content);

            return $client->getResponse();
        }

        private function get($uri)
        {
            $headers = array('CONTENT_TYPE' => 'application/json');
            $client = static::createClient();
            $client->request('GET', $uri, array(), array(), $headers);

            return $client->getResponse();
        }

        public function testSubmitNewQuote()
        {
            $response = $this->post('/api/quotes', array('content' => '<KnightOfNi> Ni!'));

            $this->assertSame(Response::HTTP_CREATED, $response->getStatusCode());
        }

        public function testSubmitEmptyQuote()
        {
            $response = $this->post('/api/quotes', array('content' => ''));

            $this->assertSame(Response::HTTP_UNPROCESSABLE_ENTITY, $response->getStatusCode());
        }

        public function testSubmitNoQuote()
        {
            $response = $this->post('/api/quotes', array());

            $this->assertSame(Response::HTTP_UNPROCESSABLE_ENTITY, $response->getStatusCode());
        }

        public function testListingAllQuotes()
        {
            $response = $this->get('/api/quotes');

            $this->assertSame(Response::HTTP_OK, $response->getStatusCode());
        }
    }

The next step is to update the configuration:

    # File: app/config/routing.yml
    submit_quote:
        path: /api/quotes
        methods:
            - POST
        defaults:
            _controller: FortuneApplicationBundle:Quote:submit

    list_quotes:
        path: /api/quotes
        methods:
            - GET
        defaults:
            _controller: FortuneApplicationBundle:Quote:list

Then we write the action:

    <?php
    // File: src/Fortune/ApplicationBundle/Controller/QuoteController.php

    namespace Fortune\ApplicationBundle\Controller;

    use Symfony\Bundle\FrameworkBundle\Controller\Controller;
    use Symfony\Component\HttpFoundation\Request;
    use Symfony\Component\HttpFoundation\Response;
    use Symfony\Component\HttpFoundation\JsonResponse;

    class QuoteController extends Controller
    {
        public function submitAction(Request $request)
        {
            $quoteRepository = $this->container->get('fortune_application.quote_repository');
            $postedContent = $request->getContent();
            $postedValues = json_decode($postedContent, true);

            if (empty($postedValues['content'])) {
                $answer = array('message' => 'Missing required parameter: content');

                return new JsonResponse($answer, Response::HTTP_UNPROCESSABLE_ENTITY);
            }
            $quote = $quoteRepository->insert($postedValues['content']);

            return new JsonResponse($quote, Response::HTTP_CREATED);
        }

        public function listAction(Request $request)
        {
            $quoteRepository = $this->container->get('fortune_application.quote_repository');
            $quotes = $quoteRepository->findAll();

            return new JsonResponse($quotes, Response::HTTP_OK);
        }
    }

And finally we run the tests:

    ./vendor/bin/phpunit -c app

Everything is fine, we can commit:

    git add -A
    git ci -m 'Added listing of quotes'

## Conclusion

Services is where the logic should be. Those manipulate entities, which carry
the data. We used the repository design pattern which is very handy for APIs:
it calls a gateway which retrieves raw data and then convert it using a factory,
so the controller only needs to comunicate with the repository. Finally, we saw
that "Dependency Injection" is just a fancy term for "passing arguments".

In the next article, we'll learn use database persistence, using
[Doctrine2 ORM](http://www.doctrine-project.org/projects/orm.html).
