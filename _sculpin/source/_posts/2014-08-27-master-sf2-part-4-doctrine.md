---
layout: post
title: Master Symfony2 - part 4: Doctrine
tags:
    - symfony
    - master symfony2 series
    - deprecated
---

> **Deprecated**: This series has been re-written - see
> [The Ultimate Developer Guide to Symfony](/2016/02/03/ultimate-symfony-http-kernel.html)

This is the fourth article of the series on mastering the
[Symfony2](http://symfony.com/) framework. Have a look at the three first ones:

* [1: Bootstraping](/2014/08/05/master-sf2-part-1-bootstraping.html)
* [2: TDD](/2014/08/13/master-sf2-part-2-tdd.html)
* [3: Services](/2014/08/22/master-sf2-part-3-services.html)

In the previous articles we created an API allowing us to submit and list
quotes:

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
    │           ├── DependencyInjection
    │           │   └── FortuneApplicationExtension.php
    │           ├── Entity
    │           │   ├── QuoteFactory.php
    │           │   ├── QuoteGateway.php
    │           │   ├── Quote.php
    │           │   └── QuoteRepository.php
    │           ├── FortuneApplicationBundle.php
    │           ├── Resources
    │           │   └── config
    │           │       └── services.xml
    │           └── Tests
    │               ├── Controller
    │               │   └── QuoteControllerTest.php
    │               └── Entity
    │                   └── QuoteRepositoryTest.php
    └── web
        └── app.php

Here's the [repository where you can find the actual code](https://github.com/gnugat/mastering-symfony2).

In this one we'll use real database persistence using
[Doctrine ORM](http://www.doctrine-project.org/projects/orm.html), a third party
bundle, the command line console and a mocking library.

**Note**: Symfony2 isn't coupled to any ORM or database library. We could use
anything else like [PDO](http://php.net/manual/en/book.pdo.php),
[Propel ORM](http://propelorm.org/), [POMM](http://www.pomm-project.org/), or
anything you want!

## Installing DoctrineBundle

Just like Symfony, Doctrine is composed of many libraries which can be used
separately. The two main ones are:

* the DataBase Abstraction Layer (DBAL), provides a unique API for many database
  vendors (MySQL, PostgreSQL, Oracle, etc)
* the Object Relation Mapping (ORM), provides an object oriented way to depict
  the data (which are usually relational)

DoctrineBundle registers the library's services into our Dependency Injection
Container. It can be installed quickly:

    composer require 'doctrine/doctrine-bundle:~1.2'

The bundle doesn't force you to use the ORM (you can simply use the DBAL), so we
need to explicitly install it:

    composer require 'doctrine/orm:~2.2,>=2.2.3'

The bundle has to be registered in our application:

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
                new Fortune\ApplicationBundle\FortuneApplicationBundle(),
                new Doctrine\Bundle\DoctrineBundle\DoctrineBundle(),
            );
        }

        public function registerContainerConfiguration(LoaderInterface $loader)
        {
            $loader->load(__DIR__.'/config/config_'.$this->getEnvironment().'.yml');
        }
    }

Its services depend on some configuration parameters, which we will add:

    # File: app/config/config.yml
    imports:
        - { resource: parameters.yml }
        - { resource: doctrine.yml }

    framework:
        secret: %secret%
        router:
            resource: %kernel.root_dir%/config/routing.yml

Next we create the actual configuration:

    # File: app/config/doctrine.yml
    doctrine:
        dbal:
            driver: pdo_mysql
            host: 127.0.0.1
            port: ~
            dbname: %database_name%
            user: %database_user%
            password: %database_password%
            charset: UTF8

        orm:
            auto_generate_proxy_classes: %kernel.debug%
            auto_mapping: true

**Note**: the `~` value is equivalent to `null` in PHP.

The values surrounded by `%` will be replaced by parameters coming from the DIC.
For example, `kernel.debug` is set by the FrameworkBundle. We'll set the values
of the database ones in the following file:

    # File: app/config/parameters.yml
    parameters:
        secret: hazuZRqYGdRrL8ATdB8kAqBZ

        database_name: fortune
        database_user: root
        database_password: ~

For security reason, this file is not commited. You can update the distributed
file though, so your team will know that they need to set a value:

    # File: app/config/parameters.yml.dist
    parameters:
        secret: ChangeMePlease

        database_name: fortune
        database_user: root
        database_password: ~

## Configuring the schema

The first thing we need is to define the schema (tables with their fields), so
we'll create this directory:

    mkdir src/Fortune/ApplicationBundle/Resources/config/doctrine

And then the configuration file for the `Quote` entity:

    # src/Fortune/ApplicationBundle/Resources/config/doctrine/Quote.orm.yml
    Fortune\ApplicationBundle\Entity\Quote:
        type: entity
        repositoryClass: Fortune\ApplicationBundle\Entity\QuoteGateway
        table: quote
        id:
            id:
                type: integer
                generator:
                    strategy: AUTO
        fields:
            content:
                type: text
            createdAt:
                type: datetime
                column: created_at

**Note**: Doctrine uses the word "Repository" with a different meaning than the
Repository design pattern (the one with gateway and factory). In our case it
corresponds to the gateway.

As you can see, we've added a `createdAt` attribute to our entity. Let's update
its code:

    <?php
    // File: src/Fortune/ApplicationBundle/Entity/Quote.php

    namespace Fortune\ApplicationBundle\Entity;

    class Quote
    {
        private $id;
        private $content;
        private $createdAt;

        public function __construct($id, $content)
        {
            $this->id = $id;
            $this->content = $content;
            $this->createdAt = new \DateTime();
        }

        public static function fromContent($content)
        {
            return new Quote(null, $content);
        }

        public function getId()
        {
            return $this->id;
        }

        public function getContent()
        {
            return $this->content;
        }

        public function getCreatedAt()
        {
            return $this->createdAt;
        }
    }

**Note**: We've added [a named constructor](http://verraes.net/2014/06/named-constructors-in-php/)
which will prove usefull with the gateway.

## Creating the console

Symfony2 provides a powerful [Console Component](http://symfony.com/doc/current/components/console/introduction.html)
allowing you to create command line utilities. It can be used standalone, or
in the full stack framework thanks to the FrameworkBundle. To create the
console, we just need to create the following file:

    #!/usr/bin/env php
    <?php
    // File: app/console

    set_time_limit(0);

    require_once __DIR__.'/../vendor/autoload.php';
    require_once __DIR__.'/AppKernel.php';

    use Symfony\Bundle\FrameworkBundle\Console\Application;
    use Symfony\Component\Console\Input\ArgvInput;

    $input = new ArgvInput();
    $kernel = new AppKernel('dev', true);
    $application = new Application($kernel);
    $application->run($input);

The object `ArgvInput` contains the input given by the user (command name,
arguments and options). Bundles can register commands in the application by
fetching them from their `Command` directory.

We can now create the database and schema easily:

    php app/console doctrine:database:create
    php app/console doctrine:schema:create

**Note**: Those are useful when developing the application, but shouldn't be used in
production.

**Note**: If you want to learn more about the Symfony2 Console Component,
[you can read this article](/2014/04/09/sf2-console-component-by-example.html).

## Adapting the Gateway

Until now, our `QuoteGateway` was saving and retrieving the quotes from a file.
We'll update it to be a Doctrine Repository:

    <?php
    // File: src/Fortune/ApplicationBundle/Entity/QuoteGateway.php

    namespace Fortune\ApplicationBundle\Entity;

    use Doctrine\ORM\EntityRepository;

    class QuoteGateway extends EntityRepository
    {
        public function insert($content)
        {
            $entityManager = $this->getEntityManager();

            $quote = Quote::fromContent($content);
            $entityManager->persist($quote);
            $entityManager->flush();

            return $quote;
        }
    }

The `EntityManager` object does the actual persistence and will set the quote's
ID. The `EntityRepository` already has a `findAll` method, so we can remove it.

The last thing we need is to update the DIC's configuration:

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
                factory-service="doctrine"
                factory-method="getRepository">
                <argument>FortuneApplicationBundle:Quote</argument>
            </service>
            <service id="fortune_application.quote_repository"
                class="Fortune\ApplicationBundle\Entity\QuoteRepository"
            >
                <argument type="service" id="fortune_application.quote_gateway" />
                <argument type="service" id="fortune_application.quote_factory" />
            </service>
        </services>
    </container>

The `doctrine` service manages the Doctrine Repositories. To manually get a
repository you'd need to do somethig like
`$container->get('doctrine')->getRepository('FortuneApplicationBundle:QuoteGateway')`,
the `factory-service` and `factory-method` attributes allow us to simply call
container->get('fortune_application.quote_gateway')`.

## Mocking the database

Database operations can be slow however we want our tests to run as fast as
possible: [this is a good opportunity to use a test double](http://blog.8thlight.com/uncle-bob/2014/05/10/WhenToMock.html).

PHPUnit comes with its own mocking library, but we'll use a less verbose and
more one: [Prophecy](https://github.com/phpspec/prophecy). First we install
the PHPUnit integration of Prophecy:

    composer require --dev 'phpspec/prophecy-phpunit:~1.0'

Then we update our test:

    <?php
    // File: src/Fortune/ApplicationBundle/Tests/Entity/QuoteRepositoryTest.php

    namespace Fortune\ApplicationBundle\Tests\Entity;

    use Fortune\ApplicationBundle\Entity\Quote;
    use Fortune\ApplicationBundle\Entity\QuoteFactory;
    use Fortune\ApplicationBundle\Entity\QuoteGateway;
    use Fortune\ApplicationBundle\Entity\QuoteRepository;
    use Prophecy\PhpUnit\ProphecyTestCase;

    class QuoteRepositoryTest extends ProphecyTestCase
    {
        const ID = 42;
        const CONTENT = '<KnightOfNi> Ni!';

        private $gateway;
        private $repository;

        public function setUp()
        {
            parent::setUp();
            $gatewayClassname = 'Fortune\ApplicationBundle\Entity\QuoteGateway';
            $this->gateway = $this->prophesize($gatewayClassname);
            $factory = new QuoteFactory();
            $this->repository = new QuoteRepository($this->gateway->reveal(), $factory);
        }

        public function testItPersistsTheQuote()
        {
            $quote = new Quote(self::ID, self::CONTENT);
            $this->gateway->insert(self::CONTENT)->willReturn($quote);
            $this->repository->insert(self::CONTENT);

            $this->gateway->findAll()->willReturn(array($quote));
            $quotes = $this->repository->findAll();
            $foundQuote = $quotes['quotes'][self::ID];

            $this->assertSame(self::CONTENT, $foundQuote['content']);
        }
    }

We created a mock of `QuoteGateway` which returns a quote we created beforehand.

Our changes are finished, let's run the tests:

    ./vendor/bin/phpunit -c app

No regression detected! We can commit our work:

    git add -A
    git ci -m 'Added doctrine'

## Conclusion

Doctrine allows us to persist the data, its bundle integrates it smoothly into
our application and provides us with handy command line tools.

You can have a look at [Doctrine Migration](http://docs.doctrine-project.org/projects/doctrine-migrations/en/latest/reference/introduction.html),
a standalone library allowing you to deploy database changes, it even has
[a bundle](http://symfony.com/doc/current/bundles/DoctrineMigrationsBundle/index.html).

In the next article, we'll talk about how to extend the framework using events.
