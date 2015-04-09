---
layout: post
title: Master Symfony2 - part 2: Test Driven Development
tags:
    - Symfony
    - TDD
    - Master Symfony2 series
---

This is the second article of the series on mastering the
[Symfony2](http://symfony.com/) framework. Have a look at the first one:
{{ link('posts/2014-08-05-master-sf2-part-1-bootstraping.md', 'Bootstraping') }}.

In the first article we bootstraped our project with the following files:

    .
    ├── app
    │   ├── AppKernel.php
    │   ├── cache
    │   │   └── .gitkeep
    │   ├── config
    │   │   ├── config_prod.yml
    │   │   ├── config_test.yml
    │   │   ├── config.yml
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
    │           └── FortuneApplicationBundle.php
    └── web
        └── app.php

Here's the [repository where you can find the actual code](https://github.com/gnugat/mastering-symfony2).

In this one we'll implement the first User Story, by writing tests first.

**Note**: writing tests before writing any code is part of the
{{ link('posts/2014-02-19-test-driven-development.md', 'Test Driven Development (TDD) methodology') }}.

## Defining the User Story

With the help of our Scrum Master, our Product Owner (Nostradamus) managed to
write the following user story:

    As a User
    I want to be able to submit a new quote
    In order to make it available

## Writing the test

Our first reflex will be to write a functional test. First create the directory:

    mkdir -p src/Fortune/ApplicationBundle/Tests/Controller

Then the test class:

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

        public function testSubmitNewQuote()
        {
            $response = $this->post('/api/quotes', array('content' => '<KnightOfNi> Ni!'));

            $this->assertSame(Response::HTTP_CREATED, $response->getStatusCode());
        }
    }

## Configuring the route

Now we need to link the `/quotes` URL to a controller, so let's edit the
configuration:

    # File: app/config/routing.yml
    submit_quote:
        path: /api/quotes
        methods:
            - POST
        defaults:
            _controller: FortuneApplicationBundle:Quote:submit

## Creating the controller

There wasn't any controllers until now, so we create the directory:

    mkdir src/Fortune/ApplicationBundle/Controller

And finally the controller class:

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

            $answer['quote']['content'] = $postedValues['content'];

            return new JsonResponse($answer, Response::HTTP_CREATED);
        }
    }

Now let's run our tests:

    ./vendor/bin/phpunit -c app

[All green](https://www.youtube.com/watch?v=lFeLDc2CzOs)! This makes us
confident enough to commit our work:

    git add -A
    git commit -m 'Created submission of quotes'

## Testing bad cases

The submitted content shouldn't be empty. Let's add a test for the bad cases:

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
    }

## Checking bad cases

Now let's fix the new tests:

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
            $answer['quote']['content'] = $postedValues['content'];

            return new JsonResponse($answer, Response::HTTP_CREATED);
        }
    }

Finally run the tests:

    ./vendor/bin/phpunit -c app

All green! Let's call it a day and commit our work:

    git add -A
    git commit -m 'Managed submission of empty/no quotes'

## Conclusion

For those who didn't practice a lot with Symfony2, this article should have
demonstrated how quick and simple it is to implement the first User Story
(test and code alike).

In the next article, we'll learn how to work with services.

### Next articles

* {{ link('posts/2014-08-22-master-sf2-part-3-services.md', '3: Services') }}
* {{ link('posts/2014-08-27-master-sf2-part-4-doctrine.md', '4: Doctrine') }}
* {{ link('posts/2014-09-03-master-sf2-part-5-events.md', '5: Events') }}
* {{ link('posts/2014-09-10-master-sf2-part-6-annotations.md', '6: Annotations') }}
* {{ link('posts/2014-10-08-master-sf2-conclusion.md', 'Conclusion') }}

### Previous articles

* {{ link('posts/2014-08-05-master-sf2-part-1-bootstraping.md', '1: Bootstraping') }}
