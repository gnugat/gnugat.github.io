---
layout: post
title: Symfony2 Dependency Injection component, by example
tags:
    - technical
    - Symfony2
---

In {{ link('posts/2014-01-22-ioc-di-and-service-locator.md', 'the previous article') }}
we've seen among other things the definition of Dependency Injection (DI) and of
the Dependency Injection Container (DIC).

In this article we'll see the Symfony2's DI component which provides a powerful
DIC. Here's the summary:

* putting the construction of your services into configuration
* how to use it to wire your application

You don't use Symfony2? Don't worry, this article is all about using this
component as a standalone library (you can use it in your
CakePHP/Zend/Home-made-framework application).

## Construction configuration

DI is all about passing arguments to the constructor of an object. Because
constructing all those object might become a burden, the DIC is here to
take this responsibility and centralize it.

Let's replace [Pimple](http://pimple.sensiolabs.org/) by
[Symfony2 DI component](http://symfony.com/doc/current/components/dependency_injection/index.html)
in the code sample from the previous article:

    <?php

    use Symfony\Component\Console\Output\OutputInterface;
    use Symfony\Component\DependencyInjection\ContainerBuilder;

    $container = new ContainerBuilder();

    // This is a parameter definition
    $container->setParameter('verbosity_level_map', array(
        OutputInterface::VERBOSITY_NORMAL => Logger::NOTICE,
        OutputInterface::VERBOSITY_VERBOSE => Logger::INFO,
        OutputInterface::VERBOSITY_VERY_VERBOSE => Logger::DEBUG,
        OutputInterface::VERBOSITY_DEBUG => Logger::DEBUG,
    );

    // register takes the service name, and then its fully qualified classname as a string
    $container->register(
        'console_output',
        'Symfony\Component\Console\Output\ConsoleOutput'
    );
    $container->register(
        'output_formatter',
        'Gnugat\Fossil\ApplicationLayer\OutputFormatter'
    );

    // You can inject:
    // * dependencies which have been declared previously
    // * arguments
    // * parameters which have been declared previously
    // * setter dependencies
    $container
        ->register('console_handler', 'Symfony\Bridge\Monolog\Handler\ConsoleHandler')
        ->addArgument(new Reference('console_output'))
        ->addArgument(true)
        ->addArgument('%verbosity_level_map%')
        ->addMethodCall('setFormatter', array(new Reference('output_formatter')));
    ;

    $container
        ->register('logger', 'Monolog\Logger')
        ->addArgument('default.logger')
        ->addMethodCall('pushHandler', array(new Reference('console_handler')));
    ;

    $container->register('filesystem', 'Symfony\Component\Filesystem\Filesystem');

    $container
        ->register('documentation_writer', 'Gnugat\Fossil\MarkdownFile\DocumentationWriter')
        ->addArgument(new Reference('filesystem'))
        ->addArgument(new Reference('logger'))
    ;

If you think about it, the construction of objects is a configuration thing:
you need to define for each object their dependencies. Symfony2's DI component
allows you to put all those definition inside a configuration file:

    <?xml version="1.0" ?>
    <!-- File: dic_config.xml -->

    <container xmlns="http://symfony.com/schema/dic/services"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://symfony.com/schema/dic/services http://symfony.com/schema/dic/services/services-1.0.xsd">
        <parameters>
            <parameter key="verbosity_Level_map" type="collection">
                <parameter key="Symfony\Component\Console\Output\OutputInterface::VERBOSITY_NORMAL">Monolog\Logger::NOTICE</parameter>
                <parameter key="Symfony\Component\Console\Output\OutputInterface::VERBOSITY_VERBOSE">Monolog\Logger::INFO</parameter>
                <parameter key="Symfony\Component\Console\Output\OutputInterface::VERBOSITY_VERY_VERBOSE">Monolog\Logger::DEBUG</parameter>
                <parameter key="Symfony\Component\Console\Output\OutputInterface::VERBOSITY_DEBUG">Monolog\Logger::DEBUG</parameter>
            </parameter>
        </parameters>

        <services>
            <service id="console_output"
                class="Symfony\Component\Console\Output\ConsoleOutput">
            </service>

            <service id="output_formatter"
                class="Gnugat\Fossil\ApplicationLayer\OutputFormatter">
            </service>

            <service id="console_handler"
                class="Symfony\Bridge\Monolog\Handler\ConsoleHandler">
                <argument type="service" id="console.output" />
                <argument key="bubble">true</argument>
                <argument>%verbosity_Level_map%</argument>
                <call method="setFormatter">
                     <argument type="service" id="output_formatter" />
                </call>
            </service>

            <service id="logger" class="Monolog\Logger">
                <argument>default.logger</argument>
                <call method="pushHandler">
                     <argument type="service" id="console_handler" />
                </call>
            </service>

            <service id="filesystem"
                class="Symfony\Component\Filesystem\Filesystem">
            </service>

            <service id="documentation_writer"
                class="Gnugat\Fossil\MarkdownFile\DocumentationWriter">
                <argument type="service" id="filesystem" />
                <argument type="service" id="logger" />
            </service>
        </services>
    </container>

And here's the code sample allowing you to feed the DIC with this configuration:

    <?php

    // File: front_controller.php

    use Symfony\Component\Config\FileLocator;
    use Symfony\Component\DependencyInjection\ContainerBuilder;
    use Symfony\Component\DependencyInjection\Loader\XmlFileLoader;

    $container = new ContainerBuilder();
    $configurationDirectory = new FileLocator(__DIR__);

    $loader = new XmlFileLoader($container, $configurationDirectory);
    $loader->load('dic_config.xml');

    $documentationWriter = $container->get('documentation_writer');
    $documentationWriter->write('/tmp/example.txt', 'Hello world');

The construction of our objects has been completely removed from the code and
has been put into a configuration file. Actually, we've replaced object
constructions by container initialization, which is way more concise.

### Configuration format

The Symfony2's DI component [allows many configuration formats](http://symfony.com/doc/current/components/dependency_injection/configurators.html):

* plain PHP (like in our first code sample)
* XML (like in our second code sample)
* [YAML](http://www.yaml.org/)

I wouldn't advise you to use YAML format, as it needs to introduce
[special formating in order to support advanced options](http://symfony.com/doc/current/components/dependency_injection/parameters.html#yaml)
like:

* prefixing services ID's with `@`
* prefixing services ID's which aren't mandatory with `@?`
* prefixing `@` with `@` in order to escape them
* [prefixing expressions with `@=`](http://symfony.com/doc/current/book/service_container.html#using-the-expression-language)

Not to mention the fact that it doesn't support every options (for instance
[you cannot declare constants as parameters](http://symfony.com/doc/current/components/dependency_injection/parameters.html#constants-as-parameters))

On the other hand, the only thing XML doesn't support is concatenation:

    <?php

    use Symfony\Component\DependencyInjection\ContainerBuilder;

    $container = new ContainerBuilder();
    // Needs to be done in plain PHP
    $container->setParameter('skeletons_path', __DIR__.'/skeletons');

XML can be easily validated and it also can be read by many software like IDE's
which can use it in order to provide you with blissful autocompletion.

If you're concerned about performances (reading XML might be slower than
requiring directly plain PHP), Symfony2's DI component allows you to convert it
into plain PHP and dump it into a cache file which you can then include in
your application: [take a look at the documentation](http://symfony.com/doc/current/components/dependency_injection/compilation.html#dumping-the-configuration-for-performance).

## Wiring your application

There's a fantastic conclusion we can deduce from the above section: we can
reduce the lines of codes of our porjects simply by extracting object
construction and putting it into configuration files.

Object construction is part of the "wiring layer" of your application: it
doesn't solve your "business problem", nor does it solve your
"application problem". It simply is the boilerplate code necessary to write
those.

Let's explore the impact of wiring your application using Symfony2's DI
component. You might not have noticed it, but the code samples used in the
previous article as well as in this one all come from [fossil](https://github.com/gnugat/fossil),
a command which allows you to bootstrap markdown files of your projects
({{ link('posts/2014-01-15-bootstrap-markdown-files-of-your-FOSS-project.md', 'cf this article') }}).
It uses Symfony2's Console component which requires some boilerplate code in
order to create the application:

    <?php

    // This is the front controller of the application
    // File: fossil

    use Gnugat\Fossil\DocCommand;
    use Symfony\Component\Config\FileLocator;
    use Symfony\Component\Console\Application;
    use Symfony\Component\DependencyInjection\ContainerBuilder;
    use Symfony\Component\DependencyInjection\Loader\XmlFileLoader;

    $container = new ContainerBuilder();
    $configurationDirectory = new FileLocator(__DIR__);

    $loader = new XmlFileLoader($container, $configurationDirectory);
    $loader->load('dic_config.xml');

    $documentationWriter = $container->get('documentation_writer');

    $docCommand = new DocCommand($documentationWriter);

    $application = new Application('Fossil', '2.0.0');
    $application->add($docCommand);

    $output = $container->get('console_output');

    $application->run(null, $output);

Can you imagine what this front controller can become if we were to add more
commands? You'd rather not? Me neither, that's why I advise you to put all this
boilerplate code into a configuration file:

    <?xml version="1.0" ?>

    <!-- File: dic_config.xml -->

    <container xmlns="http://symfony.com/schema/dic/services"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://symfony.com/schema/dic/services http://symfony.com/schema/dic/services/services-1.0.xsd">
        <services>
            <service id="console_output"
                class="Symfony\Component\Console\Output\ConsoleOutput">
            </service>

            <service id="output_formatter"
                class="Gnugat\Fossil\ApplicationLayer\OutputFormatter"
            </service>

            <service id="console_handler"
                class="Symfony\Bridge\Monolog\Handler\ConsoleHandler"
                <argument type="service" id="console.output" />
                <argument key="bubble">true</argument>
                <argument>%verbosity_Level_map%</argument>
                <call method="setFormatter">
                     <argument type="service" id="output_formatter" />
                </call>
            </service>

            <service id="logger" class="Monolog\Logger">
                <argument>default.logger</argument>
                <call method="pushHandler">
                     <argument type="service" id="console_handler" />
                </call>
            </service>

            <service id="filesystem"
                class="Symfony\Component\Filesystem\Filesystem"
            </service>

            <service id="documentation_writer"
                class="Gnugat\Fossil\MarkdownFile\DocumentationWriter"
                <argument type="service" id="filesystem" />
                <argument type="service" id="logger" />
            </service>

            <service id="doc_command" class="Gnugat\Fossil\DocCommand">
                <argument type="service" id="documentation_writer" />
            </service>

            <service id="application"
                class="Symfony\Component\Console\Application">
                <argument key="name">Fossil</argument>
                <argument key="version">2.0.0</argument>
                <call method="add">
                     <argument type="service" id="doc_command" />
                </call>
            </service>
        </services>
    </container>

Which allows us to reduce our front controller:

    <?php

    // This is the front controller of the application
    // File: fossil

    use Symfony\Component\Config\FileLocator;
    use Symfony\Component\DependencyInjection\ContainerBuilder;
    use Symfony\Component\DependencyInjection\Loader\XmlFileLoader;

    $container = new ContainerBuilder();
    $configurationDirectory = new FileLocator(__DIR__);

    $loader = new XmlFileLoader($container, $configurationDirectory);
    $loader->load('dic_config.xml');

    $application = $container->get('application');

    $output = $container->get('console_output');

    $application->run(null, $output);

Now our concern is the size of the `dic_config.xml` file which will keep growing
each time we create new services. Don't panic! You can split it into many files
using the `imports` tag:

    <?xml version="1.0" ?>

    <!-- File: config/dic.xml -->

    <container xmlns="http://symfony.com/schema/dic/services"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://symfony.com/schema/dic/services http://symfony.com/schema/dic/services/services-1.0.xsd">
        <imports>
            <import resource="01-application.xml" />
            <import resource="02-documentation_writer.xml" />
        </imports>
    </container>

We created a `config` directory to put all those XML files, which means we
should change our front controller to:

    <?php

    // This is the front controller of the application
    // File: fossil

    use Symfony\Component\Config\FileLocator;
    use Symfony\Component\DependencyInjection\ContainerBuilder;
    use Symfony\Component\DependencyInjection\Loader\XmlFileLoader;

    $container = new ContainerBuilder();
    $configurationDirectory = new FileLocator(__DIR__.'/config');

    $loader = new XmlFileLoader($container, $configurationDirectory);
    $loader->load('dic.xml');

    $application = $container->get('application');

    $output = $container->get('console_output');

    $application->run(null, $output);

The creation of the `config/01-application.xml` and
`config/02-documentation_writer.xml` files is left as an exercise for the
reader.

## Conclusion

The Symfony2's Dependency Injection component can be used outside of a Symfony2
application. It provides a powerful DIC which can be initialized using
configuration files. This means that boilerplate code (also called "wiring
layer") can be removed from your code and put in configuration files, hooray!

I hope you enjoyed this article, be sure to
[tweet me what you think about it](https://twitter.com/epiloic) ;) .

### Nota bene

We've used the componant as a standalone library, but everything we've done
here is possible inside a Symfony2 fullstack application.

There's also some tips I'd like to share with you:

### Doctrine repositories as services

The construction of Doctrine repositories is fully handled by the EntityManager,
which means:

1. you cannot inject them as dependencies in your own services
2. you cannot inject dependencies into them

[Or can you?](https://gist.github.com/gnugat/8314217)

### Service locator

{{ link('posts/2014-01-22-ioc-di-and-service-locator.md', 'The previous article') }}
spoke about service locator, which is all about using DIC as a dependency. If
you still don't see what it means, take a look at [Symfony2 ContainerAware classes](https://github.com/symfony/symfony/blob/master/src/Symfony/Component/DependencyInjection/ContainerAware.php).

For example, a [Symfony2 controller](https://github.com/symfony/symfony/blob/master/src/Symfony/Bundle/FrameworkBundle/Controller/Controller.php)
uses the DIC as a Service Locator. In this specific case it might be justified,
as the controller shouldn't contain any logic: its purpose is to pass the
request's parameters to some services, and to feed their return values as the
response's parameters.

Keep in mind that in your own code, there's a 99.99% chance that using Service
Locator is a unjustified decision ;) .
