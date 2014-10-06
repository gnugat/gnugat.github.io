---
layout: post
title: Master Symfony2 - part 6: Annotations
tags:
    - Symfony2
    - technical
    - Master Symfony2 series
---

This is the sixth article of the series on mastering the
[Symfony2](http://symfony.com/) framework. Have a look at the four first ones:

* {{ link('posts/2014-08-05-master-sf2-part-1-bootstraping.md', '1: Bootstraping') }}
* {{ link('posts/2014-08-13-master-sf2-part-2-tdd.md', '2: TDD') }}
* {{ link('posts/2014-08-22-master-sf2-part-3-services.md', '3: Services') }}
* {{ link('posts/2014-08-27-master-sf2-part-4-doctrine.md', '4: Doctrine') }}
* {{ link('posts/2014-09-03-master-sf2-part-5-events.md', '5: Events') }}

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
    │   │   ├── doctrine.yml
    │   │   ├── parameters.yml
    │   │   ├── parameters.yml.dist
    │   │   └── routing.yml
    │   ├── console
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
    │           ├── EventListener
    │           │   └── SubmitJsonListener.php
    │           ├── FortuneApplicationBundle.php
    │           ├── Resources
    │           │   └── config
    │           │       ├── doctrine
    │           │       │   └── Quote.orm.yml
    │           │       └── services.xml
    │           └── Tests
    │               ├── Controller
    │               │   └── QuoteControllerTest.php
    │               └── Entity
    │                   └── QuoteRepositoryTest.php
    └── web
        └── app.php

Here's the [repository where you can find the actual code](https://github.com/gnugat/mastering-symfony2).

In this article, we'll discover annotations.

## Doctrine Annotations

Inspired by [Python Decorators](http://legacy.python.org/dev/peps/pep-0318/) and
[Java Annotations](http://docs.oracle.com/javase/tutorial/java/annotations/),
the [Doctrine Project](http://www.doctrine-project.org/) created a convenient
library allowing to put in the same file: information (like configuration) and
source code.

In concrete terms, [Annotations](http://docs.doctrine-project.org/projects/doctrine-common/en/latest/reference/annotations.html)
are comments which are read by `AnnotationReader` and can then be cached in any
format (generally PHP) to make things faster afterwards.

It's main strength is the possibility to avoid having a configuration file in a
path too far from the source code which uses it. For example intead of having
the schema definition in `src/Fortune/ApplicationBundle/Resources/config/doctrine/Quote.orm.yml`
we could have it directly in the `QuoteEntity`.

## Installing Sensio FrameworkExtra Bundle

The [Sensio FrameworkExtra Bundle](http://symfony.com/doc/current/bundles/SensioFrameworkExtraBundle/index.html)
provides controller annotations, amongst them lies `@Route` allowing us to move
the routing configuration from `app/config/routing.yml` directly to the actions.

Let's download the bundle:

    composer require sensio/framework-extra-bundle:~3.0

Then register it:

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
                new Sensio\Bundle\FrameworkExtraBundle\SensioFrameworkExtraBundle(),
            );
        }

        public function registerContainerConfiguration(LoaderInterface $loader)
        {
            $loader->load(__DIR__.'/config/config_'.$this->getEnvironment().'.yml');
        }
    }

Finally, we need to tell Doctrine's Annotation library  where to find the
classes by registering Composer's autoloader:

    <?php
    // File: app/autoload.php

    use Doctrine\Common\Annotations\AnnotationRegistry;

    $loader = require __DIR__.'/../vendor/autoload.php';

    AnnotationRegistry::registerLoader(array($loader, 'loadClass'));

    return $loader;

This file should be used in our front controller:

    <?php

    use Symfony\Component\HttpFoundation\Request;

    require_once __DIR__.'/app/autoload.php';
    require_once __DIR__.'/../app/AppKernel.php';

    $kernel = new AppKernel('prod', false);
    $request = Request::createFromGlobals();
    $response = $kernel->handle($request);
    $response->send();
    $kernel->terminate($request, $response);

But also in our test suite:

    <?xml version="1.0" encoding="UTF-8"?>
    <!-- http://phpunit.de/manual/current/en/appendixes.configuration.html -->
    <phpunit
        backupGlobals="false"
        colors="true"
        syntaxCheck="false"
        bootstrap="autoload.php">

        <testsuites>
            <testsuite name="Functional Test Suite">
                <directory>../src/*/*/Tests</directory>
            </testsuite>
        </testsuites>
    </phpunit>

## Using the @Route annotation

We can now empty the `routing.yml` file and tell it to import the configuration
from the `QuoteController` using its annotations:

    # File: app/config/routing.yml
    fortune_application:
        resource: @FortuneApplicationBundle/Controller
        type: annotation

The controller itself will look like this:

    <?php
    // File: src/Fortune/ApplicationBundle/Controller/QuoteController.php

    namespace Fortune\ApplicationBundle\Controller;

    use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
    use Symfony\Bundle\FrameworkBundle\Controller\Controller;
    use Symfony\Component\HttpFoundation\Request;
    use Symfony\Component\HttpFoundation\Response;
    use Symfony\Component\HttpFoundation\JsonResponse;

    class QuoteController extends Controller
    {
        /**
         * @Route("/api/quotes", methods={"POST"})
         */
        public function submitAction(Request $request)
        {
            $postedValues = $request->request->all();
            if (empty($postedValues['content'])) {
                $answer = array('message' => 'Missing required parameter: content');

                return new JsonResponse($answer, Response::HTTP_UNPROCESSABLE_ENTITY);
            }
            $quoteRepository = $this->container->get('fortune_application.quote_repository');
            $quote = $quoteRepository->insert($postedValues['content']);

            return new JsonResponse($quote, Response::HTTP_CREATED);
        }

        /**
         * @Route("/api/quotes", methods={"GET"})
         */
        public function listAction(Request $request)
        {
            $quoteRepository = $this->container->get('fortune_application.quote_repository');
            $quotes = $quoteRepository->findAll();

            return new JsonResponse($quotes, Response::HTTP_OK);
        }
    }

And now annotations are ready to be used, as the tests prove it:

    ./vendor/bin/phpunit -c app

That's green enough for us to commit:

    git add -A
    git commit -m 'Used annotations'

## Conclusion

Annotations allow us to remove the distance between configuration and code.

 > **Note**: You should know that annotations can
 > [raise concerns about tight coupling](https://r.je/php-annotations-are-an-abomination.html),
 > but it doesn't seem to be [relevant when used as configuration](http://marekkalnik.tumblr.com/post/34047514685/are-annotations-really-bad).
 >
 > The best thing to do is to minimize their use to the classes which are
 > already coupled to our tools (for example the controllers) and do some
 > research on the subject to make your own opinion.

If the concept seduced you, have a look a [ControllerExtraBundle](https://github.com/mmoreram/ControllerExtraBundle).

The next artile will be the conclusion, I hope you enjoy this series!

## Next articles

* {{ link('posts/2014-10-08-master-sf2-conclusion.md', 'Conclusion') }}

### Previous articles

* {{ link('posts/2014-08-05-master-sf2-part-1-bootstraping.md', '1: Bootstraping') }}
* {{ link('posts/2014-08-13-master-sf2-part-2-tdd.md', '2: TDD') }}
* {{ link('posts/2014-08-22-master-sf2-part-3-services.md', '3: Services') }}
* {{ link('posts/2014-08-27-master-sf2-part-4-doctrine.md', '4: Doctrine') }}
* {{ link('posts/2014-09-03-master-sf2-part-5-events.md', '5: Events') }}
