---
layout: post
title:  Inversion of Control, Dependency Injection, Dependency Injection Container and Service Locator
tags:
    - design pattern
---

If you don't want to read this article, just jump to the [conclusion](#conclusion)
which sums it up in 44 words.

If you've never heard of those (or one of those), this article will teach you
what they are.

If you know what are those, but don't know what's the difference between them,
this article will teach you what it is.

If you know what are those and what's the difference between them... Well read
this article and tell me what you think about it on
[Twitter](https://twitter.com/epiloic) ;) .

Those big names actually refer to simple design patterns and principles which
might help you in your projects. Maybe you've been using them without knowing it!

## Inversion of Control

This principle is very abstract, as it is based on the way you use objects
rather than specifying how to write them.

To keep things short: IoC (Inversion of Control) is all about relationship
between higher level classes and detail classes. Higher level classes shouldn't
depend on detail classes, but rather the contrary.

In order to ensure this, higher level classes should depend on abstractions
(like interfaces) instead of depending on concrete classes. Also, you should
make sure that higher level classes own detail classes.

While I understand this principle, I cannot make a better explanation than this
which is really a shame. But I know a good article which can:
[Dependency Injection is NOT the same as the Dependency Inversion Principle, by Derick Bailey](http://lostechies.com/derickbailey/2011/09/22/dependency-injection-is-not-the-same-as-the-dependency-inversion-principle/).

I really encourage you to read it as it explains very well the problem IoC tries
to solve, with some good (and graphical) examples.

## Dependency Injection

Let's explain each words:

* a dependency is an object used by your class
* an injection is the fact of passing an argument to a function

Some people instanciate those dependencies inside the class which use them, for
example:

    <?php

    namespace Gnugat\Fossil\MarkdownFile;

    use Symfony\Component\Filesystem\Filesystem;

    class DocumentationWriter
    {
        public function write($absolutePathname, $content)
        {
            $filesystem = new Filesystem();
            if (!$filesystem->exists($absolutePathname)) {
                $filesystem->dumpFile($absolutePathname, $content);
            }
        }
    }

    $documentationWriter = new DocumentationWriter();
    $documentationWriter->write('/tmp/example.txt', 'Hello world');

There's nothing wrong with this code, but it could be improved.

First of all, it happens that `Filesystem` is "stateless": you can call every
methods it has, in the order you want, it won't change the way it behaves. Which
means you could create a single instance for your whole application: it would
save some precious memory.

Second of all, this class cannot be tested: if anything, you would be testing
`Filesystem` itself by checking if the file was written with the same name and
content.

DI (Dependency Injection) is used to solve these two problems: you should first
create the instance of `Filesystem` and then pass it to (inject it into)
`DocumentationWriter`:

    <?php

    namespace Gnugat\Fossil\MarkdownFile;

    use Symfony\Component\Filesystem\Filesystem;

    class DocumentationWriter
    {
        public function write(Filesystem $filesystem, $absolutePathname, $content)
        {
            if (!$filesystem->exists($absolutePathname)) {
                $filesystem->dumpFile($absolutePathname, $content);
            }
        }
    }

    $filesystem = new Filesystem();

    $documentationWriter = new DocumentationWriter();
    $documentationWriter->write($filesystem, '/tmp/example.txt', 'Hello world');

The dependency can now be shared throughout your application, and you can pass
a mock of it which will be able to tell you which method was called.

Injection is usually done via the constructor:

    <?php

    namespace Gnugat\Fossil\MarkdownFile;

    use Symfony\Component\Filesystem\Filesystem;

    class DocumentationWriter
    {
        private $filesystem;

        public function __construct(Filesystem $filesystem)
        {
            $this->filesystem = $filesystem;
        }

        public function write($absolutePathname, $content)
        {
            if (!$this->filesystem->exists($absolutePathname)) {
                $this->filesystem->dumpFile($absolutePathname, $content);
            }
        }
    }

    $filesystem = new Filesystem();

    $documentationWriter = new DocumentationWriter($filesystem);
    $documentationWriter->write('/tmp/example.txt', 'Hello world');

Time to time, injection will be done via setters:

    <?php

    namespace Gnugat\Fossil\MarkdownFile;

    use Symfony\Component\Filesystem\Filesystem;

    class DocumentationWriter
    {
        private $filesystem;

        public function setFilesystem(Filesystem $filesystem)
        {
            $this->filesystem = $filesystem;
        }

        public function write($absolutePathname, $content)
        {
            if (!$this->filesystem->exists($absolutePathname)) {
                $this->filesystem->dumpFile($absolutePathname, $content);
            }
        }
    }

    $filesystem = new Filesystem();

    $documentationWriter = new DocumentationWriter();
    $documentationWriter->setFilesystem($filesystem);
    $documentationWriter->write('/tmp/example.txt', 'Hello world');

Setter injection is used when you have no control on the object construction,
and can be dangerous: if the setter isn't called, a runtime error will occur.

To help debug this kind of error, you can do this:

    <?php

    namespace Gnugat\Fossil\MarkdownFile;

    use Symfony\Component\Filesystem\Filesystem;

    class DocumentationWriter
    {
        private $filesystem;

        public function setFilesystem(Filesystem $filesystem)
        {
            $this->filesystem = $filesystem;
        }

        public function write($absolutePathname, $content)
        {
            if (!$this->getFilesystem()->exists($absolutePathname)) {
                $this->getFilesystem()->dumpFile($absolutePathname, $content);
            }
        }

        private function getFilesystem()
        {
            if (!($this->filesystem instanceof Filesystem)) {
                $msg = 'The Filesystem dependency is missing.';
                $msg .= ' Did you forgot to call setFilesystem?';
                throw new \LogicException($msg);
            }

            return $this->filesystem;
        }
    }

    $documentationWriter = new DocumentationWriter();
    // Will throw an exception with a helpful message.
    $documentationWriter->write('/tmp/example.txt', 'Hello world');

You shouldn't need to use setter injection in your own class, but rather on
classes which extend third party library.

For example Doctrine's repositories can only be retrieved using its
`EntityManager`, which mean you don't have the control on its construction. If
you need to pass dependencies to it, you'll have to use setter injection.

### Dependency Injection and Inversion of Control

The subject of [the article previously quoted](http://lostechies.com/derickbailey/2011/09/22/dependency-injection-is-not-the-same-as-the-dependency-inversion-principle/)
is the relation between DI and IoC: some people confuse them and think they're
the same by simply deducing that IoC is injecting interfaces instead of concrete
classes.

While combining them is possible, you should remember that IoC is first a matter
of higher level classes owning their detail classes. The principle (IoC) and the
design pattern (DI) are really different things.

## Dependency Injection Container

The flaw of DI is the manual construction of all those objects: some classes
might have dependencies which themselves have dependencies. And even without
deep dependencies, manually creating a large number of classes is never
pleasant.

The biggest risk is to scatter object construction in the whole application and
losing track of it: if you don't know that an object has already been
constructing you might accidently construct it again.

Let's add a dependency on [Monolog](https://github.com/Seldaek/monolog) to our
`DocumentationWriter` (plus some custom configuration to spice it up):

    <?php

    use Gnugat\Fossil\ApplicationLayer\OutputFormatter;
    use Gnugat\Fossil\MarkdownFile\DocumentationWriter;
    use Monolog\Logger;
    use Symfony\Bridge\Monolog\Handler\ConsoleHandler;
    use Symfony\Component\Console\Output\ConsoleOutput;
    use Symfony\Component\Console\Output\OutputInterface;
    use Symfony\Component\Filesystem\Filesystem;

    $verbosityLevelMap = array(
        'OutputInterface::VERBOSITY_NORMAL' => Logger::NOTICE,
        'OutputInterface::VERBOSITY_VERBOSE' => Logger::INFO,
        'OutputInterface::VERBOSITY_VERY_VERBOSE' => Logger::DEBUG,
        'OutputInterface::VERBOSITY_DEBUG' => Logger::DEBUG,
    );

    $consoleOutput = new ConsoleOutput();
    $outputFormatter = new OutputFormatter();
    $consoleHandler = new ConsoleHandler(
        $consoleOutput,
        true,
        $verbosityLevelMap
    );
    $consoleHandler->setFormatter($outputFormatter);

    $logger = new Logger('default.logger');
    $logger->pushHandler($consoleHandler);

    $filesystem = new Filesystem();

    $documentationWritter = new DocumentationWriter(
        $filesystem,
        $logger
    );
    $documentationWriter->write('/tmp/example.txt', 'Hello world');

It's quite a burden isn't it?

The DIC (Dependency Injection Container) solves this problem by taking the
responsibility of creating them for you. technically, you still write all of
these lines, but instead of putting them mixed with business logic code you put
it in a separate file.

DIC can be found in many languages:

* java, for example with [Spring](http://docs.spring.io/spring/docs/2.5.6/reference/beans.html)
* PHP, for example with [Zend\Di](http://framework.zend.com/manual/2.0/en/modules/zend.di.introduction.html)
* js, for example in [AngularJs](http://angularjs.org/)

To better understand what is a DIC, we'll take a look at [Pimple](pimple.sensiolabs.org),
a small DIC for PHP using a javascript-like syntax.

Pimple can be considered as an array in which you can put parameters and
"factories": an anonymous function which creates an instance of the class.

Here's the code sample:

    <?php

    // File: dic.php

    use Gnugat\Fossil\ApplicationLayer\OutputFormatter;
    use Gnugat\Fossil\MarkdownFile\DocumentationWriter;
    use Monolog\Logger;
    use Symfony\Bridge\Monolog\Handler\ConsoleHandler;
    use Symfony\Component\Console\Output\ConsoleOutput;
    use Symfony\Component\Console\Output\OutputInterface;
    use Symfony\Component\Filesystem\Filesystem;

    $dic = new Pimple();

    // This is a parameter definition
    $dic['verbosity_level_map'] = array(
        'OutputInterface::VERBOSITY_NORMAL' => Logger::NOTICE,
        'OutputInterface::VERBOSITY_VERBOSE' => Logger::INFO,
        'OutputInterface::VERBOSITY_VERY_VERBOSE' => Logger::DEBUG,
        'OutputInterface::VERBOSITY_DEBUG' => Logger::DEBUG,
    );

    // Thess are a factory definition
    $dic['console_output'] = $dic->share(function($dic) {
        return new ConsoleOutput();
    });
    $dic['output_formatter'] = $dic->share(function($dic) {
        return new OutputFormatter();
    });

    // You can inject dependencies which have been declared previously
    $dic['console_handler'] = $dic->share(function($dic) {
        $consoleHandler = new ConsoleHandler(
            $dic['console_output'],
            true,
            $dic['verbosity_level_map']
        );
        $consoleHandler->setFormatter($dic['output_formatter']);

        return $consoleHandler
    });

    $dic['logger'] = $dic->share(function($dic) {
        $logger = new Logger('default.logger');
        $logger->pushHandler($dic['console_handler']);

        return $logger
    });

    $dic['filesystem'] = $dic->share(function($dic) {
        return new Filesystem();
    });

    $dic['documentation_writer'] = $dic->share(function($dic) {
        return new DocumentationWriter(
            $dic['filesystem'],
            $dic['logger']
        );
    });

So, what's the big difference between this and the previous code sample? Well
now you centralized all your instances into a single container, the definition
of your object is done in a central place (you can move it into a file
`dic.php` for example) and the best of all: classes will be instanciated lazily,
which means as long as you don't aks for them they won't be created, and once
you created them they won't be created a second time.

In your application, you just need to pass the DIC and use it:

    <?php

    // File: front_controller.php

    require_once __DIR__.'/dic.php';

    // Now you can retrieve instances from the DIC
    $documentationWriter = $dic['documentation_writer'];

    $documentationWriter->write('/tmp/example.txt', 'Hello world');

I must stress on the fact that object creation is now centralized: the code
from the first example (the one without DIC) could be scattered into different
places of your application.

### Dependency Injection Container and IoC

Again, people often mixep up those two for the same reason they mix up DI and
IoC. There's a lot of [DIC libraries which have been falsely called ioc](https://github.com/rande/python-simple-ioc).

Please, don't make the same mistake.

### Dependency Injection Container and Singleton

Singleton is a design pattern saying that a given object should only be
instanciated once and that it should be guarded from being instanciated a second
time.

Here's an implementation example of a singleton:

    <?php

    // Code from https://github.com/domnikl/DesignPatternsPHP/blob/master/Singleton/Singleton.php

    class Singleton
    {
        protected static $instance;

        public static function getInstance()
        {
            if (null === static::$instance) {
                static::$instance = new static;
            }

            return static::$instance;
        }

        private function __construct()
        {
            // is not allowed to call from outside: private!
        }
    }

While in our example the DIC makes sure our objects are constructed only once,
we can't call them singletons as nobody prevents you from creating them a second
time manually.

Keep in mind that DIC aren't always making sure of this: in our example we've
used [the special share method](https://github.com/fabpot/Pimple/blob/1.1/lib/Pimple.php#L116)
of Pimple to ensure it, but you can also retrieve a new instance on every call:

    <?php

    use Symfony\Component\Finder\Finder;

    $dic['finder'] = function($dic) {
        return new Finder();
    });

    $firstFinder = $dic['finder'];
    $secondFinder = $dic['finder'];

To recap: DI and DIC have nothing to do with Singleton.

## Service Locator

The classes you put into the DIC can be called `Services`: they will execute
a task for you when you call them.

A Service Locator isn't just a container of services which gets them when you
ask it to: what we described is simply a DIC. To be a Service Locator, a DIC
must be injected as a dependency.

This might happen with classes which have many dependencies: instead of
injecting them one by one you can inject directly the DIC and let the class
retrieve the services it needs.

You should be warned that this is generally a bad idea: a class which requires
too many dependencies should be splitted into several smaller classes.

There is however some cases when Service Locator are usefull, for example
controllers are good candidates as their only responsibility is to pass input
to services and to return output.

To be more precise, Service Locator shouldn't be used in your business logic,
but rather in objects which serve as intermediate between two layers.

Here's a [good article about when to use Service Locators by Ralph Schindler](http://ralphschindler.com/2012/10/10/di-dic-service-locator-redux).

## Conclusion

Here's the TL;DR:

* IoC: higher level classes own detail classes (which are abstractions)
* DI: pass as argument objects to the class which will use them
* DIC: creates the dependencies and then injects them into the asked class
* Service Locator: depending on the DIC instead of many dependencies

If this article didn't teach you anything and made you angry, please
[tweet it to me](https://twitter.com/epiloic). If you learned some things, or
if this article made your day, feel free to do the same ;) .

### More resources

If you want to read more about DI and DIC, here's good series by
Fabien Potencier's series on [what is Dependency Injection](http://fabien.potencier.org/article/11/what-is-dependency-injection).

There's also William Durand's slides on [Writing Better Code](http://edu.williamdurand.fr/php-slides/index.html#slide152)
(actually the slides are about PHP and contain good resources. I encourage you to read it entirely!).
