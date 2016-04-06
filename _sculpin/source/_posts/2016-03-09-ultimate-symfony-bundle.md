---
layout: post
title: The Ultimate Developer Guide to Symfony - Bundle
tags:
    - symfony
    - ultimate symfony series
    - reference
---

> **Reference**: This article is intended to be as complete as possible and is
> kept up to date.

> **TL;DR**: Configure services from a third party library in a Bundle.

In this guide we've explored the main standalone libraries (also known as "Components")
provided by [Symfony](http://symfony.com) to help us build applications:

* [HTTP Kernel and HTTP Foundation](/2016/02/03/ultimate-symfony-http-kernel.html)
* [Event Dispatcher](/2016/02/10/ultimate-symfony-event-dispatcher.html)
* [Routing and YAML](/2016/02/17/ultimate-symfony-routing.html)
* [Dependency Injection](/2016/02/24/ultimate-symfony-dependency-injection.html)
* [Console](/2016/03/02/ultimate-symfony-console.html)

In this article, we're going to have a closer look at how HttpKernel enables reusable code.

Then in the next article we'll see the different ways to organize our application
[tree directory](/2016/03/16/ultimate-symfony-skeleton.html).

Finally we'll finish by putting all this knowledge in practice by creating a
"fortune" project with:

* [an endpoint that allows us to submit new fortunes](/2016/03/24/ultimate-symfony-api-example.html)
* [a page that lists all fortunes](/2016/03/30/ultimate-symfony-web-example.html)
* [a command that prints the last fortune](/2016/04/06/ultimate-symfony-cli-example.html)

## HttpKernel vs Kernel

The HttpKernel component provides two implementations for `HttpKernelInterface`.

The first one, `HttpKernel`, relies on Event Dispatcher and Routing to execute
the appropriate controller for the given Request.

And the second one, `Kernel`, relies on Dependency Injection and `HttpKernel`:

```php
<?php

namespace Symfony\Component\HttpKernel;

use Symfony\Component\HttpFoundation\Request;

class Kernel implements HttpKernelInterface
{
    public function handle(Request $request, $type = HttpKernelInterface::MASTER_REQUEST, $catch = true)
    {
        if (false === $this->booted) {
            $this->boot();
        }

        return $this->container->get('http_kernel')->handle($request, $type, $catch);
    }

    public function boot()
    {
        // Initializes the container
    }

    abstract public function registerBundles();
}
```

> **Note**: For brevity's sake, `Kernel` has been heavily truncated.

Initialization of the container includes:

1. retrieving all "bundles"
2. creating a `ContainerBuilder`
3. for each bundles:
    1. registering its `ExtensionInterface` implementations in the container
    2. registering its `CompilerPassInterface` implementations in the container
4. dumping the container in an optimized implementation

Once the container is initialized, `Kernel` expects it to contain a `http_kernel`
service to which it will delegate the actual HTTP work.

## Bundle

A bundle is a package that contains `ExtensionInterface` and `CompilerPassInterface`
implementations, to configure a Dependency Injection container. It can be summed
up by this interface:

```php
<?php

namespace Symfony\Component\HttpKernel\Bundle;

use Symfony\Component\DependencyInjection\ContainerBuilder;

interface BundleInterface
{
    // Adds CompilerPassInterface implementations to the container
    public function build(ContainerBuilder $container);

    // Returs an ExtensionInterface implementation, which will be registered in the container
    public function getContainerExtension();
}
```

> **Note**: Once again, this interface has been truncated for brevity's sake.

Bundles are usually created for one of the following purposes:

* define a third party library's classes as Dependency Injection services (e.g.
  [TacticianBundle](https://github.com/thephpleague/tactician-bundle)
  for [Tactician](https://tactician.thephpleague.com/)
  which provides a [CommandBus](http://shawnmc.cool/command-bus),
  [MonologBundle](https://github.com/symfony/monolog-bundle)
  for [Monolog](https://github.com/Seldaek/monolog)
  which provides a [PSR-3](http://www.php-fig.org/psr/psr-3/) compliant logger,
  etc)
* define an application's classes as Dependency Injection services (usually named AppBundle)
* create a framework (e.g.
  user management with [FOSUserBundle](https://github.com/FriendsOfSymfony/FOSUserBundle),
  admin generator with [SonataAdminBundle](https://sonata-project.org/bundles/admin/2-3/doc/index.html),
  etc)

> **Note**: the last category is considered bad practice, as explained in the
> following, articles:
>
> * [composer require technical-debt-bundle](http://jolicode.com/blog/do-not-use-fosuserbundle).
> * [Use only infrastructural bundles in Symfony2, by Elnur Abdurrakhimov](http://elnur.pro/use-only-infrastructural-bundles-in-symfony/)
> * [Should everything really be a bundle in Symfony2?](http://stackoverflow.com/questions/9999433/should-everything-really-be-a-bundle-in-symfony-2-x/10001019#10001019)
> * [Yes, you can have low coupling in a Symfony2 application](http://danielribeiro.org/blog/yes-you-can-have-low-coupling-in-a-symfony-standard-edition-application/)
> * [Symfony2 without bundles, by Elnur Abdurrakhimov, by Daniel Ribeiro](http://elnur.pro/symfony-without-bundles/)
> * [Symfony2 some things I dont like about bundles, by Matthias Noback](http://php-and-symfony.matthiasnoback.nl/2013/10/symfony2-some-things-i-dont-like-about-bundles/)
> * [Symfony2 console commands as services why, by Matthias Noback](http://php-and-symfony.matthiasnoback.nl/2013/10/symfony2-console-commands-as-services-why/)
> * [Naked bundles, slides by Matthias Noback](http://www.slideshare.net/matthiasnoback/high-quality-symfony-bundles-tutorial-dutch-php-conference-2014)

Bundles follow [by convention](http://symfony.com/doc/current/cookbook/bundles/best_practices.html)
the following directory tree:

```
.
├── Command
├── Controller
├── DependencyInjection
│   └── CompilerPass
├── EventListener
├── Resources
│   └── config
│       └── services
│           └── some_definitions.yml
├── Tests
└── VendorProjectBundle.php
```

## NanoFrameworkBundle example

Since HttpKernel component is a third party library, we're going to create a
bundle to provide its classes as Dependency Injection services. This is also a
good opportunity to have a look at how a Symfony application works behind the hood.

NanoFrameworkBundle's purpose is to provides a `http_kernel` service that can be
used by `Kernel`. First let's create a directory:

```
mkdir nano-framework-bundle
cd nano-framework-bundle
```

Then we can create an implementation of `BundleInterface`:

```php
<?php
// VendorNanoFrameworkBundle.php

namespace Vendor\NanoFrameworkBundle;

use Symfony\Component\HttpKernel\Bundle\Bundle;

class VendorNanoFrameworkBundle extends Bundle
{
}
```

### Bundle extension

To be able to load Dependency Injection configuration, we'll create an
implementation of `ExtensionInterface`:

```php
<?php
// DependencyInjection/VendorNanoFrameworkExtension.php

namespace Vendor\NanoFrameworkBundle\DependencyInjection;

use Symfony\Component\Config\FileLocator;
use Symfony\Component\Config\Loader\LoaderResolver;
use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Loader\DirectoryLoader;
use Symfony\Component\DependencyInjection\Loader\YamlFileLoader;
use Symfony\Component\HttpKernel\DependencyInjection\Extension;

class VendorNanoFrameworkExtension extends Extension
{
    public function load(array $configs, ContainerBuilder $container)
    {
        $fileLocator = new FileLocator(__DIR__.'/../Resources/config');
        $loader = new DirectoryLoader($container, $fileLocator);
        $loader->setResolver(new LoaderResolver(array(
            new YamlFileLoader($container, $fileLocator),
            $loader,
        )));
        $loader->load('services/');
    }
}
```

Once done, we can create the configuration:

```
# Resources/config/services/http_kernel.yml
services:
    http_kernel:
        class: Symfony\Component\HttpKernel\HttpKernel
        arguments:
            - "@event_dispatcher"
            - "@controller_resolver"
            - "@request_stack"

    event_dispatcher:
        class: Symfony\Component\EventDispatcher\EventDispatcher

    controller_resolver:
        class: Symfony\Component\HttpKernel\Controller\ControllerResolver
        public: false

    request_stack:
        class: Symfony\Component\HttpFoundation\RequestStack
```

### Bundle compiler pass

In order to register event listeners in EventDispatcher in a way that doesn't
require us to edit `Resources/config/services/http_kernel.yml`, we're going to
create an implementation of `CompilerInterface`:

```php
<?php
// DependencyInjection/CompilerPass/AddListenersPass.php

namespace Vendor\NanoFrameworkBundle\DependencyInjection;

use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Compiler\CompilerPassInterface;
use Symfony\Component\DependencyInjection\Reference;

class AddListenersPass implements CompilerPassInterface
{
    public function process(ContainerBuilder $container)
    {
        $eventDispatcher = $container->findDefinition('event_dispatcher');
        $eventListeners = $container->findTaggedServiceIds('kernel.event_listener');
        foreach ($eventListeners as $id => $events) {
            foreach ($events as $event) {
                $eventDispatcher->addMethodCall('addListener', array(
                    $event['event'],
                    array(new Reference($id), $event['method']),
                    isset($event['priority']) ? $event['priority'] : 0;
                ));
            }
        }
    }
}
```

With this, we only need to add a tag with:

* a `kernel.event_listener` name
* an event to listen to (e.g. `kernel.request`)
* a method to call (e.g. `onKernelRequest`)
* optionally a priority (default to `0`, the greater the sooner it will be executed)

To complete the step, we need to register it in our bundle:

```php
<?php
// VendorNanoFrameworkBundle.php

namespace Vendor\NanoFrameworkBundle;

use Symfony\Component\HttpKernel\Bundle\Bundle;
use Vendor\NanoFrameworkBundle\DependencyInjection\CompilerPass\AddListenersPass;

class VendorNanoFrameworkBundle extends Bundle
{
    public function build(ContainerBuilder $container)
    {
        parent::build($container);

        $container->addCompilerPass(new AddListenersPass());
    }
}
```

> **Note**: While `CompilerPassInterface` implementations need to be registered
> explicitly, there is no need to do anything for `ExtensionInterface` implementations
> as `Bundle` contains a method able to locate it, based on the following conventions:
>
> * it needs to be in `DependencyInjection` directory
> * it needs to be named after the bundle name (replace `Bundle` suffix by `Extension`)
> * it needs to implement `ExtensionInterface`

### More configuration

HttpKernel relies on event listeners for the routing, in order to enable it we
need to add the following configuration:

```
# Resources/config/services/routing.yml
services:
    router_listener:
        class: Symfony\Component\HttpKernel\EventListener\RouterListener
        arguments:
            - "@router"
            - "@request_stack"
            - "@router.request_context"
        tags:
            - { name: kernel.event_listener, event: kernel.request, method: onKernelRequest, priority: 32 }

    router:
        class: Symfony\Component\Routing\Router
        public: false
        arguments:
            - "@routing.loader"
            - "%kernel.root_dir%/config/routings"
            - "%router.options%"
            - "@router.request_context"
        calls:
            - [setConfigCacheFactory, ["@config_cache_factory"]]

    routing.loader:
        class: Symfony\Component\Config\Loader\DelegatingLoader
        public: false
        arguments:
            - "@routing.resolver"

    routing.resolver:
        class: Symfony\Component\Config\Loader\LoaderResolver
        public: false
        calls:
            - [addLoader, ["@routing.loader.yml"]]

    router.request_context:
        class: Symfony\Component\Routing\RequestContext
        public: false

    config_cache_factory:
        class: Symfony\Component\Config\ResourceCheckerConfigCacheFactory
        public: false

    routing.loader.yml:
        class: Symfony\Component\Routing\Loader\YamlFileLoader
        public: false
        arguments:
            - "@file_locator"
```

## Usage

Since `Kernel` is an abstract class, we need to create an implementation (usually
called AppKernel):

```php
<?php
// Tests/app/AppKernel.php

use Symfony\Component\HttpKernel\Kernel;

class AppKernel extends Kernel
{
    public function registerBundles()
    {
        return array(
            new Vendor\NanoFrameworkBundle\VendorNanoFrameworkBundle(),
        );
    }

    public function getRootDir()
    {
        return __DIR__;
    }

    public function getCacheDir()
    {
        return dirname(__DIR__).'/var/cache/'.$this->getEnvironment();
    }

    public function getLogDir()
    {
        return dirname(__DIR__).'/var/logs';
    }
}
```

Finally we need to create a "Front Controller" (a fancy name for `index.php`):

```php
<?php
// Tests/web/index.php

<?php

use Symfony\Component\HttpFoundation\Request;

$kernel = new AppKernel('prod', false);
$request = Request::createFromGlobals();
$response = $kernel->handle($request);
$response->send();
$kernel->terminate($request, $response);
```

## Conclusion

Bundles enable us to define classes as Dependency Injection services, for our
applications and third part libraries in a reusable way.

In the example above we've created a bundle that provides a `http_kernel` service,
which can then be used to create Symfony applications. Here are some existing
bundles that do it for us:

* [FrameworkBundle](https://github.com/symfony/framework-bundle), the official one
  provided by Symfony. It comes with many services out of the box, mainly targeted
  at full stack applications (it follows a "solve 80% of use cases" philosohpy)
* [MicroFrameworkBundle](http://gnugat.github.io/micro-framework-bundle/), an unofficial
  one. It comes with the bare minimum (it follows a "add what you need" philosohpy)

There are many bundles available, you can find them by checking
[symfony-bundle in Packagist](https://packagist.org/search/?q=symfony-bundle).
