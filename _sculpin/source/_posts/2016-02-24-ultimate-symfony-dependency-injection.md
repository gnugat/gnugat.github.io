---
layout: post
title: The Ultimate Developer Guide to Symfony - Dependency Injection
tags:
    - symfony
    - ultimate symfony series
    - reference
---

> **Reference**: This article is intended to be as complete as possible and is
> kept up to date.

> **TL;DR**: Make Dependency Injection easy by moving class construction in
> configuration files.

In this guide we explore the standalone libraries (also known as "Components")
provided by [Symfony](http://symfony.com) to help us build applications.

We've already seen:

* [HTTP Kernel and HTTP Foundation](/2016/02/03/ultimate-symfony-http-kernel.html)
* [Event Dispatcher](/2016/02/10/ultimate-symfony-event-dispatcher.html)
* [Routing and YAML](/2016/02/17/ultimate-symfony-routing.html)

We're now about to check Dependency Injection, then the next article we'll have
a look at [Console](/2016/03/02/ultimate-symfony-console.html).

We'll also see how HttpKernel enables reusable code with [Bundles](/2016/03/09/ultimate-symfony-bundle.html),
and the different ways to organize our application [tree directory](/2016/03/16/ultimate-symfony-skeleton.html).

Finally we'll finish by putting all this knowledge in practice by creating a
"fortune" project with:

* [an endpoint that allows us to submit new fortunes](/2016/03/24/ultimate-symfony-api-example.html)
* [a page that lists all fortunes](/2016/03/30/ultimate-symfony-web-example.html)
* [a command that prints the last fortune](/2016/04/06/ultimate-symfony-cli-example.html)

## Introduction to the design pattern

When first creating a class, we tend to keep it small and tidy. Then overtime it
can grow out of control and the next thing we know it became this multi thousand
line monster:

```php
<?php

class CheckApiStatus
{
    public function check($url)
    {
        $curl = curl_init();
        curl_setopt_array($curl, array(
            CUROPT_RETURNTRANSFER => true,
            CURLOPT_HEADER => true,
            CUROPT_URL => $url,
        ));
        $response = curl_exec($curl);
        $headerSize = curl_getinfo($curl, CURLINFO_HEADER_SIZE);
        $statusCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        curl_close($curl);
        $headers = array_map(function($line) {
            return explode(': ', trim($line));
        }, explode("\n", substr($response, 0, $size)));
        array_pop($headers);array_pop($headers);array_shift($headers);
        $body = substr($response, $headerSize);

        return 200 >= $statusCode && $statusCode < 400;
    }
}
```

A nice way to shrink it back to an acceptable level is to identify the many
"responsibilities" it bears and split those in sub classes. This process is called
refactoring:

```php
<?php

class Request
{
    private $uri;

    public function __construct($uri)
    {
        $this->uri;
    }

    public function getUri()
    {
        return $this->uri;
    }
}

class Response
{
    private $statusCode;
    private $headers;
    private $body;

    public function __construct($statusCode, $headers, $body)
    {
        $this->statusCode = $statusCode;
        $this->headers = $headers;
        $this->body = $body;
    }

    public function getStatusCode()
    {
        return $this->statusCode;
    }

    public function getHeaders()
    {
        return $this->headers;
    }

    public function getBody()
    {
        return $this->body;
    }
}

interface HttpClient
{
    /**
     * @return Response
     */
    public function sendRequest(Request $request);
}

class CurlHttpClient implements HttpClient
{
    public function sendRequest(Request $request)
    {
        $curl = curl_init();
        curl_setopt_array($curl, array(
            CUROPT_RETURNTRANSFER => true,
            CURLOPT_HEADER => true,
            CUROPT_URL => $request->getUri(),
        ));
        $response = curl_exec($curl);
        $headerSize = curl_getinfo($curl, CURLINFO_HEADER_SIZE);
        $statusCode = curl_getinfo($curl, CURLINFO_HTTP_CODE);
        curl_close($curl);
        $headers = array_map(function($line) {
            return explode(': ', trim($line));
        }, explode("\n", substr($response, 0, $size)));
        array_pop($headers);array_pop($headers);array_shift($headers);
        $body = substr($response, $headerSize);
        $body = substr($response, $headerSize);

        return new Response($statusCode, $headers, $body);
    }
}

class CheckApiStatus
{
    public function check($url)
    {
        $httpClient = new CurlHttpClient();
        $statusCode = $httpClient->sendRequest(new Request($url))->getStatusCode();

        return 200 >= $statusCode && $statusCode < 400;
    }
}
```

> **Note**: for more refactoring examples, check:
>
> * [Refactoring external service](http://martinfowler.com/articles/refactoring-external-service.html) by Martin Fowler
> * [Extract till you drop](http://verraes.net/2013/09/extract-till-you-drop/) by Mathias Verreas
> * Refactoring the cat API
>   [part 1](http://php-and-symfony.matthiasnoback.nl/2015/07/refactoring-the-cat-api-client-part-1/)
>   [part 2](http://php-and-symfony.matthiasnoback.nl/2015/07/refactoring-the-cat-api-client-part-2/)
>   [part 3](http://php-and-symfony.matthiasnoback.nl/2015/07/refactoring-the-cat-api-client-part-3/)
>   by Matthias Noback

Our original class then has to call those sub classes to "delegate" the work. But
how does it access those sub classes? Should it instantiate them in its methods?
A better place could be the constructor, where the instances are stored in the class
properties so it can be shared between two calls.

Or even better we can instantiate them out of the class, and then pass them as
arguments to the original class constructor, so we can share it with other classes:

```php
<?php

class CheckApiStatus
{
    private $httpClient;

    public function __construct(HttpClient $httpClient)
    {
        $this->httpClient = $httpClient;
    }

    public function check($url)
    {
        $statusCode = $this->httpClient->sendRequest(new Request($url))->getStatusCode();

        return 200 >= $statusCode && $statusCode < 400;
    }
}

$httpClient = new CurlHttpClient();
$checkApiStatus = new CheckApiStatus($httpClient);
```

> **Note**: Now `CheckApiStatus` is decoupled from the remote request logic.
>
> The refactoring steps might seem like producing more code just for the "beauty"
> of principles, but it actually enables us to completly remove it: by using [PSR-7](http://www.php-fig.org/psr/psr-7/)
> interfaces instead of our own we can easily switch to [Guzzle](http://docs.guzzlephp.org/en/latest/)
> or any HTTP client library.

And that's what [Dependency Injection](http://www.martinfowler.com/articles/injection.html)
is all about: taking parameters (also known as dependencies) our class (also known as service)
needs and pass them as arguments (also known as injection), to allow more decoupling.

The downside of this design pattern is that we now have a cascade of instantiations.

> **Note**: Classes can be shared if they are stateless which means calling a method
> shouldn't change their attributes.

## The component

Symfony provides a [Dependency Injection component](http://symfony.com/doc/current/components/dependency-injection/introduction.html)
which allows us to set up how our classes are constructed:

```php
<?php

use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Reference;

$container = new ContainerBuilder();

$container
    ->register('http_client','CurlHttpClient')
;
$container
    ->register('check_api_status', 'CheckApiStatus')
    ->addArgument(new Reference('http_client'))
;

$checkApiStatus = $container->get('check_api_status');
```

It can even be set up using configuration:

```
# /tmp/services/api.yml
services:
    http_client:
        class: CurlHttpClient

    check_api_status:
        class: CheckApiStatus
        arguments:
            - '@http_client'
```

> **Note**: Some string values must be escaped using single quotes because YAML
> has a list of [reserved characters](http://stackoverflow.com/a/22235064), including:
> `@`, `%`, `\`, `-`, `:` `[`, `]`, `{` and `}`.

Here's how we can load this configuration:

```php
<?php

use Symfony\Component\Config\FileLocator;
use Symfony\Component\Config\Loader\LoaderResolver;
use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Loader\DirectoryLoader;
use Symfony\Component\DependencyInjection\Loader\YamlFileLoader;

$container = new ContainerBuilder();

// Load recursively all YAML configuration files in services directories
$fileLocator = new FileLocator(__DIR__);
$loader = new DirectoryLoader($container, $fileLocator);
$loader->setResolver(new LoaderResolver(array(
    new YamlFileLoader($container, $fileLocator),
    $loader,
)));
$loader->load('/services/');

$checkApiStatus = $container->get('check_api_status');
```

Calling methods on a created service to complete its initialization is possible:

```
services:
    my_event_listener:
        class: MyEventListener

    event_dispatcher:
        class: 'Symfony\Component\EventDispatcher\EventDispatcher'
        calls:
            - [ addListener, [ kernel.request, '@my_event_listener', 42 ] ]
```

> **Note**: There's a better way to add listeners to the EventDispatcher, keep
> reading to find out how.

Finally it might be useful to create aliases:

```
services:
    http_client:
        alias: curl_http_client

    curl_http_client:
        class: CurlHttpClient

    check_api_status:
        class: checkApiStatus
        arguments:
            - "@http_client"
```

In the example above `http_client` is set to be `curl_http_client`, it could be
changed later to use another implementation of `HttpClient`.

## Parameters

In addition to class instances, we can also inject parameters:

```php
<?php

use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Parameter;
use Symfony\Component\DependencyInjection\Reference;

$container = new ContainerBuilder();

$container->setParameter('username', 'arthur.dent@example.com');
$container->setParameter('password', 42);

$container
    ->register('http_client','CurlHttpClient')
;
$container
    ->register('check_api_status', 'CheckApiStatus')
    ->addArgument(new Reference('http_client'))
    ->addArgument(new Parameter('username'))
    ->addArgument(new Parameter('password'))
;

$checkApiStatus = $container->get('check_api_status');
```

> **Note**: For the example's sake we're pretending that `CheckApiStatus`'s constructor
> now takes 3 arguments.

Here's the equivalent in YAML:

```
# /tmp/services/api.yml
parameters:
    username: 'arthur.dent@example.com'
    password: 42

services:
    http_client:
        class: CurlHttpClient

    check_api_status:
        class: CheckApiStatus
        arguments:
            - '@http_client'
            - '%username%'
            - '%password%'
```

> **Note**: services are prefixed with `@`, and parameters are surrounded with `%`.

The value of a parameter can be anything:

* null (`~`)
* a boolean (`true` or `false`)
* an integer (e.g. `42`)
* a float (e.g. `44.23`)
* a string (e.g. `hello world`, or escaped `'arthur.dent@example.com'`)
* an array (e.g. `[ apples, oranges ]`)
* an associative array (e.g. `{ first_name: Arthur, last_name: Dent }`)

> **Note**: The examples above for arrays are inline ones. They could also be on many lines:
>
> ```
> parameters:
>     fruits:
>         - apples
>         - oranges
>
>     identity:
>         first_name: Arthur
>         last_name: Dent
>
>     # We can even have multi dimension arrays:
>     five_a_day:
>         -
>             - apples
>             - oranges
>         -
>             - carrots
> ```

## Extension

By creating a class that extends `Extension`, we can provide reusable Dependency
Injection configuration:

```php
<?php

use Symfony\Component\Config\FileLocator;
use Symfony\Component\Config\Loader\LoaderResolver;
use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Loader\DirectoryLoader;
use Symfony\Component\DependencyInjection\Loader\YamlFileLoader;
use Symfony\Component\HttpKernel\DependencyInjection\Extension;

class AppExtension extends Extension
{
    public function load(array $configs, ContainerBuilder $container)
    {
        $fileLocator = new FileLocator(__DIR__);
        $loader = new DirectoryLoader($container, $fileLocator);
        $loader->setResolver(new LoaderResolver(array(
            new YamlFileLoader($container, $fileLocator),
            $loader,
        )));
        $loader->load('/services/');
    }
}

$container = new ContainerBuilder();
$appExtension = new AppExtension();
$appExtension->load(array(), $container);

$checkApiStatus = $container->get('check_api_status');
```

## CompilerPass and tags

The `Container` implementation provides a `compile` method that resolves parameters
(replace `%parameter%` placeholders by the parameter value) and freezes them
(calling `setParameter` will result in an exception).

The `ContainerBuilder` implementations also has a `compile` method which is going
to execute all registered `CompilerPassInterface` implementations.

For example, we can retrieve all services "tagged" `kernel.event_listener` and
add them to the `EventDispatcher` with the following one:

```php
<?php

use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Compiler\CompilerPassInterface;
use Symfony\Component\DependencyInjection\Reference;

class EventListenerCompilerPass implements CompilerPassInterface
{
    public function process(ContainerBuilder $container)
    {
        if (false === $container->hasDefinition('event_dispatcher')) {
            return;
        }
        $eventDispatcher = $container->getDefinition('event_dispatcher');
        $taggedServices = $container->findTaggedServiceIds('kernel.event_listener');
        foreach ($taggedServices as $id => $attributes) {
            $eventDispatcher->addMethodCall('addListener', array(
                $attributes['event'],
                array(new Reference($id), $attributes['method']),
                $attributes['priority'],
            ));
        }
    }
}
```

> **Note**: The EventDispatcher component already provides a `RegisterListenersPass`.

The configuration for a "tagged" service looks like this:

```
services:
    my_event_listener:
        class MyEventListener
        tags:
            - { name: kernel.event_listener, event: kernel.request, method: onKernelRequest, priority: 42 }
```

> **Note**: With this, it is no longer required to call `addListener` in `event_dispatcher`'s
> configuration.

## Conclusion

By providing a configurable way to define service construction, the DependencyInjection
component allows us to use the design pattern of the same name in our projects.

The HttpKernel component provides two `HttpKernelInterface` implementations:

* `HttpKernel` which does the HTTP logic
* `Kernel` which sets up a DependencyInjection container and then use `HttpKernel`

Just like for the Routing component, there's a `PhpDumper` which can generate an
implementation of `ContainerInterface` with all configuration in an optimized way.
It might look like this:

```php
<?php

use Symfony\Component\DependencyInjection\ContainerInterface;
use Symfony\Component\DependencyInjection\Container;
use Symfony\Component\DependencyInjection\Exception\InvalidArgumentException;
use Symfony\Component\DependencyInjection\Exception\LogicException;
use Symfony\Component\DependencyInjection\Exception\RuntimeException;
use Symfony\Component\DependencyInjection\ParameterBag\FrozenParameterBag;

class appDevDebugProjectContainer extends Container
{
    private $parameters;
    private $targetDirs = array();

    public function __construct()
    {
        $dir = __DIR__;
        for ($i = 1; $i <= 5; ++$i) {
            $this->targetDirs[$i] = $dir = dirname($dir);
        }
        $this->parameters = $this->getDefaultParameters();

        $this->services = array();
        $this->methodMap = array(
            'http_client' => 'getHttpClientService',
            'check_api_status' => 'getCheckApiStatusService',
        );
        $this->aliases = array(
        );
    }

    public function compile()
    {
        throw new LogicException('You cannot compile a dumped frozen container.');
    }

    protected function getHttpClientService()
    {
        return $this->services['http_client'] = new \CurlHttpClient();
    }

    protected function getCheckApiStatusService()
    {
        return $this->services['check_api_status'] = new \CheckApiStatus($this->get('http_client'), 'arthur.dent@example.com', 42);
    }

    public function getParameter($name)
    {
        $name = strtolower($name);
        if (!(isset($this->parameters[$name]) || array_key_exists($name, $this->parameters))) {
            throw new InvalidArgumentException(sprintf('The parameter "%s" must be defined.', $name));
        }

        return $this->parameters[$name];
    }

    public function hasParameter($name)
    {
        $name = strtolower($name);

        return isset($this->parameters[$name]) || array_key_exists($name, $this->parameters);
    }

    public function setParameter($name, $value)
    {
        throw new LogicException('Impossible to call set() on a frozen ParameterBag.');
    }

    public function getParameterBag()
    {
        if (null === $this->parameterBag) {
            $this->parameterBag = new FrozenParameterBag($this->parameters);
        }

        return $this->parameterBag;
    }

    protected function getDefaultParameters()
    {
        return array(
            'username' => 'arthur.dent@example.com',
            'password' => 42,
        );
    }
}
```

> **Note**: Dependencies that are used by only one service can be marked as "private"
> they'll be hard coded in the service instantiation (but they won't be available
> anymore from `$container->get()`).
>
> In our example we could mark `http_client` as private, so the dumped Container
> wouldn't have a `getHttpClientService` method:
>
> ```
> service:
>     http_client:
>         class: CurlHttpClient
>         public: false
> ```

It is also worth noting that services are by default only initialized once and on demand,
so the number of services doesn't impact the performances of the application.
