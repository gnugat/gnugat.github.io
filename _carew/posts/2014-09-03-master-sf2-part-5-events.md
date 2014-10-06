---
layout: post
title: Master Symfony2 - part 5: Events
tags:
    - Symfony2
    - technical
    - Master Symfony2 series
---

This is the fifth article of the series on mastering the
[Symfony2](http://symfony.com/) framework. Have a look at the four first ones:

* {{ link('posts/2014-08-05-master-sf2-part-1-bootstraping.md', '1: Bootstraping') }}
* {{ link('posts/2014-08-13-master-sf2-part-2-tdd.md', '2: TDD') }}
* {{ link('posts/2014-08-22-master-sf2-part-3-services.md', '3: Services') }}
* {{ link('posts/2014-08-27-master-sf2-part-4-doctrine.md', '4: Doctrine') }}

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

In this one we'll learn how to extend the framework using events.

## EventDispatcher Component

The [Event Dispatcher](http://symfony.com/doc/current/components/event_dispatcher/introduction.html)
is another standalone component which can be summed up as follow:

    <?php

    class EventDispatcher
    {
        private $events = array();

        public function addListener($event, $listener)
        {
            $this->events[$event][] = $listener;
        }

        public function dispatch($event)
        {
            foreach ($this->events[$event] as $listener) {
                $listener();
            }
        }
    }

You can register listeners (which are callables) and then call them by
dispatching the subscribed event:

    $dispatcher = new EventDispatcher();
    $dispatcher->addListener('before.boyard', function () { echo 'Ultimate Challenge'; });
    $dispatcher->dispatch('before.boyard'); // Prints "Ultimate Challenge".

Here's the actual API:

    <?php

    namespace Symfony\Component\EventDispatcher;

    interface EventDispatcherInterface
    {
        public function dispatch($eventName, Event $event = null);

        public function addListener($eventName, $listener, $priority = 0);
        public function removeListener($eventName, $listener);
        public function getListeners($eventName = null);
        public function hasListeners($eventName = null);

        public function addSubscriber(EventSubscriberInterface $subscriber);
        public function removeSubscriber(EventSubscriberInterface $subscriber);
    }

The Component handles priorities, and contrary to our previous example it needs
an `Event` object when dispatching events, allowing us to provide a context.

Subscribers are listeners which have a `getSubscribedEvents` method.

**Note**: If you want to learn more about this component, have a look at
[Raul Fraile](https://twitter.com/raulfraile)'s [article](http://blog.servergrove.com/2013/10/23/symfony2-components-overview-eventdispatcher/).

## In the fullstack framework

The [Symfony2 HttpKernel Component](http://symfony.com/doc/current/components/http_kernel/introduction.html)
dispatches events to provide extension points, we can:

* modify the Request when it has just been received: [kernel.request](http://symfony.com/doc/current/components/http_kernel/introduction.html#the-kernel-request-event)
* change the controller when it has been guessed: [kernel.controller](http://symfony.com/doc/current/components/http_kernel/introduction.html#the-kernel-controller-event)
* use the value returned by the controller: [kernel.view](http://symfony.com/doc/current/components/http_kernel/introduction.html#the-kernel-view-event)
* change the Response when it has been created: [kernel.response](http://symfony.com/doc/current/components/http_kernel/introduction.html#the-kernel-response-event)
* [handle global state and cleanup](https://github.com/symfony/symfony/pull/8904): kernel.finish_request
* handle exceptions: [kernel.exception](http://symfony.com/doc/current/components/http_kernel/introduction.html#handling-exceptions-the-kernel-exception-event)

**Note**: exceptions are caught by default, but this can be disabled.

Here's the [full list of kernel events](http://symfony.com/doc/current/components/http_kernel/introduction.html#component-http-kernel-event-table).

**Note**: If you want to learn more about those events, have a look at
[Matthias Noback](https://twitter.com/matthiasnoback)'s book:
[A year with Symfony](https://leanpub.com/a-year-with-symfony?utm_campaign=a-year-with-symfony&utm_medium=embed&utm_source=gnugat.github.io).

The FrameworkBundle takes care of registering the listeners using the
Dependency Injection Container (DIC): we declare our listener as a service in
the configuration, with a specific tag.

**Note**: the DIC can retrieve all the services with the given tag using
`findTaggedServiceIds`, making it easier to register listeners for example
(this is done in `Symfony\Component\EventDispatcher\DependencyInjection\RegisterListenersPass`
which is called in the [FrameworkBundle](https://github.com/symfony/symfony/blob/f940d92a32e4d70cbe045ab8e1b3c70d3eb6061e/src/Symfony/Bundle/FrameworkBundle/FrameworkBundle.php#L71)).

## Submitted JSON

In `QuoteController::submitAction`, we need to get the request's content and
convert it from JSON. This is a generic task which should be executed before
every controller: we can move it in an event listener.

First create the directory:

    mkdir src/Fortune/ApplicationBundle/EventListener

Then we create the actual listener:

    <?php
    // File: src/Fortune/ApplicationBundle/EventListener/SubmitJsonListener.php

    namespace Fortune\ApplicationBundle\EventListener;

    use Symfony\Component\HttpKernel\Event\GetResponseEvent;

    class SubmitJsonListener
    {
        public function onKernelRequest(GetResponseEvent $event)
        {
            $request = $event->getRequest();
            $content = $request->getContent();
            $data = json_decode($content, true);
            $request->request->add($data ?: array());
        }
    }

Next we register it in the Dependency Injection Container:

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
            <service id="fortune_application.submit_json_listener"
                class="Fortune\ApplicationBundle\EventListener\SubmitJsonListener"
            >
                <tag name="kernel.event_listener" event="kernel.request" method="onKernelRequest" />
            </service>
        </services>
    </container>

And finally we update the controller:

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
            $postedValues = $request->request->all();
            if (empty($postedValues['content'])) {
                $answer = array('message' => 'Missing required parameter: content');

                return new JsonResponse($answer, Response::HTTP_UNPROCESSABLE_ENTITY);
            }
            $quoteRepository = $this->container->get('fortune_application.quote_repository');
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

We can now run the tests:

    ./vendor/bin/phpunit -c app

No regression detected! We can commit our work:

    git add -A
    git ci -m 'Used event'

**Note**: The [FOSRestBundle](https://github.com/FriendsOfSymfony/FOSRestBundle)
provides such an event listener. We're only creating it manually here to learn
about events.

## Managing errors in a listener

If someone submits a malformed JSON, our listener can stop the execution and
return a proper response:

    <?php
    // File: src/Fortune/ApplicationBundle/EventListener/SubmitJsonListener.php

    namespace Fortune\ApplicationBundle\EventListener;

    use Symfony\Component\HttpFoundation\Response;
    use Symfony\Component\HttpFoundation\JsonResponse;
    use Symfony\Component\HttpKernel\Event\GetResponseEvent;

    class SubmitJsonListener
    {
        public function onKernelRequest(GetResponseEvent $event)
        {
            $request = $event->getRequest();
            $content = $request->getContent();
            $data = json_decode($content, true);
            if (JSON_ERROR_NONE !== json_last_error()) {
                $data = array('message' => 'Invalid or malformed JSON');
                $response = new JsonResponse($data, Response::HTTP_BAD_REQUEST);
                $event->setResponse($response);
                $event->stopPropagation();
            }
            $request->request->add($data ?: array());
        }
    }

By setting a response in the event, the `HttpKernel` will almost stop (it
dispatches a `kernel.response` event and an extra `kernel.finish_request` event)
and return it.

By using `stopPropagation`, we prevent further `kernel.request` listeners from
being executed.

Have a look at [HttpKernel::handleRaw](https://github.com/symfony/symfony/blob/f940d92a32e4d70cbe045ab8e1b3c70d3eb6061e/src/Symfony/Component/HttpKernel/HttpKernel.php#L120)
to discover what's going on.

Let's run the tests one last time:

    ./vendor/bin/phpunit -c app

All green, we can commit our work:

    git add -A
    git ci -m 'Handled errors'

## Conclusion

Events are a powerful way to extend the framework: you create a listener,
register it on a specific event and you're done.

Kernel events aren't the only ones available:
[Doctrine provides its own](http://doctrine-orm.readthedocs.org/en/latest/reference/events.html),
(it uses its own event dispatcher library)
[the Symfony2 Form Component uses them](http://symfony.com/doc/current/components/form/form_events.html)
and we could even [create our own events](http://isometriks.com/symfony2-custom-events)!

The only drawback is that they're sort of hidden: by looking at the controller's
code we cannot know that submitted JSON has been handled, we lose explicitness.

The next article will be about annotations.

### Next articles

* {{ link('posts/2014-09-10-master-sf2-part-6-annotations.md', '6: Annotations') }}
* {{ link('posts/2014-10-08-master-sf2-conclusion.md', 'Conclusion') }}

### Previous articles

* {{ link('posts/2014-08-05-master-sf2-part-1-bootstraping.md', '1: Bootstraping') }}
* {{ link('posts/2014-08-13-master-sf2-part-2-tdd.md', '2: TDD') }}
* {{ link('posts/2014-08-22-master-sf2-part-3-services.md', '3: Services') }}
* {{ link('posts/2014-08-27-master-sf2-part-4-doctrine.md', '4: Doctrine') }}
