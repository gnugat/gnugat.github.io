---
layout: post
title: Learn Symfony2 - part 3: Bundles
tags:
    - Symfony2
    - technical
    - Learn Symfony2 series
---

This is the third article of the series on learning
[the Symfony2 framework](http://symfony.com/).
Have a look at the two first ones:

* {{ link('posts/2014-06-18-learn-sf2-composer-part-1.md', '1: Composer') }}.
* {{ link('posts/2014-06-25-learn-sf2-empty-app-part-2.md', '2: Empty application') }}.

In the previous articles we began to create an empty application with the
following files:

    .
    ├── app
    │   ├── AppKernel.php
    │   ├── cache
    │   │   └── .gitkeep
    │   ├── config
    │   │   └── config.yml
    │   └── logs
    │       └── .gitkeep
    ├── composer.json
    ├── composer.lock
    ├── .gitignore
    └── web
        └── app.php

Running `composer install` should create a `vendor` directory, which we ignored
with git.

We'll now see what a bundle is.

## Creating the application bundle

We'll need some use case in order for our code snippets to make sense. So here
it is: the Knights Who Say 'Ni', demand a webservice! It shall say 'ni' if the
user do not appease it. To do so, the user should post a shrubbery!

Let's create our application bundle, in order to have a place where we can put
our code. To do so we need to create the directory:

    mkdir -p src/Knight/ApplicationBundle

Then the class extending `Symfony\Component\HttpKernel\Bundle\Bundle`:

    <?php
    // File: src/Knight/ApplicationBundle/KnightApplicationBundle.php

    namespace Knight\ApplicationBundle;

    use Symfony\Component\HttpKernel\Bundle\Bundle;

    class KnightApplicationBundle extends Bundle
    {
    }

Finally we register the bundle into our application:

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
                new Knight\ApplicationBundle\KnightApplicationBundle(), // <-- Here!
            );
        }

        public function registerContainerConfiguration(LoaderInterface $loader)
        {
            $loader->load(__DIR__.'/config/config.yml');
        }
    }

## Bundles allow you to extend the application's DIC

The `KnightApplicationBundle` class extends the following one:

    <?php

    namespace Symfony\Component\HttpKernel\Bundle;

    use Symfony\Component\DependencyInjection\ContainerAware;
    use Symfony\Component\Console\Application;

    abstract class Bundle extends ContainerAware implements BundleInterface
    {
        public function getContainerExtension();
        public function registerCommands(Application $application);
    }

*Note*: Only the part we're interested in is shown here.

Those two methods make the bundle capable of autodiscovering its commands and
its Dependency Injection Container's (DIC) extension, if the following directory
directory structure is used:

    .
    ├── Command
    │   └── *Command.php
    ├── DependencyInjection
    │   └── KnightApplicationExtension.php
    └── KnightApplicationBundle.php

*Note*: the only file required in a bundle is the `KnightApplicationBundle.php`
one.

The name of a bundle (in our example `KnightApplication`) is composed of:

* the vendor name (here our customer's name: `Knight`)
* the actual bundle name (`Application`)

For your own sake, choose a small one-word name for you vendor name and for your
bundle name (there's no hard rules but that's my advice).

The `KnightApplicationExtension` class allows you to manipulate the DIC (more
often you'll load a configuration file which can be located in
`Resources/config/services.xml`).

And that's precisely the purpose of bundles: registering services in the
application's DIC.

### Side note about DIC and services

We'll see later what is a service and the purpose of the DIC. However if you
want to discover early what it is all about, have a look at these two articles:

* {{ link('posts/2014-01-22-ioc-di-and-service-locator.md', 'Inversion of Control, Dependency Injection, Dependency Injection Container and Service Locator') }}
* {{ link('posts/2014-01-29-sf2-di-component-by-example.md', 'Symfony2 Dependency Injection component, by example') }}

*Note*: this is a kindly reminder about the nature of Symfony2 Components. Those
are third party libraries which can be used on their own outside of the
framework.

We'll see more about services in the next articles.

### Side note about commands

The Symfony2 Console Component allows you to create CLI applications. This
application can have one or many commands. To learn more about them, have a look
at this article:

* {{ link('posts/2014-04-09-sf2-console-component-by-example.md', 'Symfony2 Console component, by example') }}

*Note*: commands aren't in the scope of this article, but they're worth
mentioning.

## Two kinds of bundles

There's two kinds of bundle:

* third party application integration ones (reusable, shared between
  applications)
* application's ones (non reusable and dedicated to your business model)

Let's take the [KnpLabs snappy library](https://github.com/KnpLabs/snappy): it
allows you to generate a PDF from a HTML page and can be used in any
applications (non-symfony ones, and even framework-less ones).

The class allowing this generation is
`Knp\Bundle\SnappyBundle\Snappy\LoggableGenerator`: its construction is a bit
tiresome. To fix this, we can define its construction inside the DIC and
fortunately there's already a bundle doing it for us:
[KnpSnappyBundle](https://github.com/KnpLabs/KnpSnappyBundle).

That's a good example of the first kind of bundles.

Now about the second kind: in our Symfony2 application, we'll need to integrate
our own code to it, one day or another. We could go the long and painful way
(writing a lot of boilerplate code and configurations), or we could use a bundle
to do automatically the job for us!

Sometimes, we'll find applications which have many bundles in order to
categorize it into modules. This isn't necessary and it's a bit tiresome if we
ask me: we can simply create folders in a unique bundle to categorize our
modules.

The creation of many bundles necessitates some extra manual steps. It also makes
little sense as a bundle is supposed to be a decoupled unit: if we create a
UserBundle, FrontendBundle, BlogBundle and ForumBundle, we'll find ourselves
with bundles depending on one another, often with cyclic dependencies and we'll
waste time wondering where to put new classes (which can rely on 3 bundles).

My advice: create a single bundle for your application. If later on you find
that inside it you created a set of classes which make sense in other projects
(Symfony2 and non-Symfon2 ones alike), then maybe you can extract them to
create a third party library. And then you might create a bundle to integrate
it inside Symfony2 applications.

## Conclusion

Bundles are a way to extend the Dependency Injection Container: they're the glue
layer between your code and Symfony2 applications.

They follow conventions which aren't hard coded (you can override anything),
allowing them to autodiscover some convenient classes.

Thansk for reading, in the next article, we'll create controllers!

### Previous articles

* {{ link('posts/2014-06-18-learn-sf2-composer-part-1.md', '1: Composer') }}
* {{ link('posts/2014-06-25-learn-sf2-empty-app-part-2.md', '2: Empty application') }}

### Next articles

* {{ link('posts/2014-07-12-learn-sf2-controllers-part-4.md', '4: Controllers') }}

### Resources

Here's a good article about how reusable bundles should be created:

* [Use only infrastructural bundles in Symfony2, by Elnur Abdurrakhimov](http://elnur.pro/use-only-infrastructural-bundles-in-symfony/)

You don't like the conventions and you're ready to write a lot of boilerplate
code and configuration? Here you go (I'd not advise you to do so, though):

* [Should everything really be a bundle in Symfony2?](http://stackoverflow.com/questions/9999433/should-everything-really-be-a-bundle-in-symfony-2-x/10001019#10001019)
* [Yes, you can have low coupling in a Symfony2 application](http://danielribeiro.org/blog/yes-you-can-have-low-coupling-in-a-symfony-standard-edition-application/)
* [Symfony2 without bundles, by Elnur Abdurrakhimov, by Daniel Ribeiro](http://elnur.pro/symfony-without-bundles/)
* [Symfony2 some things I dont like about bundles, by Matthias Noback](http://php-and-symfony.matthiasnoback.nl/2013/10/symfony2-some-things-i-dont-like-about-bundles/)
* [Symfony2 console commands as services why, by Matthias Noback](http://php-and-symfony.matthiasnoback.nl/2013/10/symfony2-console-commands-as-services-why/)
* [Naked bundles, slides by Matthias Noback](http://www.slideshare.net/matthiasnoback/high-quality-symfony-bundles-tutorial-dutch-php-conference-2014)

I'm only putting these links because I like how they explain how Symfony2 works
behind the hood, but I wouldn't apply them in a real world application as it
makes too much fuss to no avail (that's my umble opinion anyway).
