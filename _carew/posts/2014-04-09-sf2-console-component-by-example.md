---
layout: post
title: Symfony2 Console component, by example
tags:
    - technical
    - Symfony2
---

[TL;DR: jump to the conclusion](#conclusion).

[Symfony2](http://symfony.com/) is a set of libraries which help you in your
everyday tasks. You can even stack them together and create a framework with it:

* [Symfony standard edition](https://github.com/symfony/symfony-standard)
* [Symfony empty edition](https://github.com/gnugat/symfony-empty)
* [Silex](http://silex.sensiolabs.org/)

Many frameworks already use a lot of components from Symfony2:

* [Laravel](http://laravel.com/)
* [Drupal](https://drupal.org/)
* [eZ Publish](http://ez.no/)
* [PHPUnit](http://phpunit.de/)
* [phpBB](https://www.phpbb.com/)
* [Composer](https://getcomposer.org/)

In this article, we'll see the
[Console Component](http://symfony.com/doc/master/components/console/introduction.html),
which allows you to build Command Line Interface (CLI) applications. Symfony 2.5
will be released in may 2014, with great new features for the Console, so I'll
speak about this version here.

* [Introduction](#introduction)
    * [Application](#application)
    * [Command](#command)
    * [Input](#input)
    * [Output](#output)
    * [ConsoleLogger](#consolelogger)
* [Standalone example](#standalone-example)
    * [Creating the application](#creating-the-application)
    * [Creating the command](#creating-the-command)
    * [Registering the command](#registering-the-command)
    * [Using the Filesystem component](#using-the-filesystem-component)
    * [Thin controller, many small services](#thin-controller-many-small-services)
    * [Registering the services](#registering-the-services)

## Introduction

This component allows you to focus on one thing: creating commands. It takes
care of all the coloring output, input gathering and command containing stuff.

The big picture is: you have an `Application` which contains a set of
`Command`s. When ran, the `Application` will create an `Input` object which
contains `Option`s and `Argument`s provided by the user, and will feed it to
the right `Command`.

The code being the best documentation, we'll now see the strict minimum classes
you should know, with the methods you'll likely use.

### Application

All you need to know about the `Application` is this:

    <?php

    namespace Symfony\Component\Console;

    use Symfony\Component\Console\Command\Command;
    use Symfony\Component\Console\Input\InputInterface;
    use Symfony\Component\Console\Output\OutputInterface;

    class Application
    {
        public function __construct($name = 'UNKNOWN', $version = 'UNKNOWN');
        public function add(Command $command);
        public function setDefaultCommand($commandName); // New in 2.5!
        public function run(InputInterface $input = null, OutputInterface $output = null);
    }

Minimum usage:

    #!/usr/bin/env php
    <?php

    use Symfony\Component\Console\Application;

    $application = new Application();
    $application->run();

By running this script, you should be able to see a colorful output which lists
the available commands (`list` is the default command, and a `help` is also
available).

### Command

The `Command` class is the controller of your CLI application:

    <?php

    namespace Symfony\Component\Console\Command;

    use Symfony\Component\Console\Input\InputArgument;
    use Symfony\Component\Console\Input\InputInterface;
    use Symfony\Component\Console\Input\InputOption;
    use Symfony\Component\Console\Output\OutputInterface;

    class Command
    {
        protected function configure();
        protected function execute(InputInterface $input, OutputInterface $output);
        protected function interact(InputInterface $input, OutputInterface $output);

        // To be called in configure
        public function setName($name);
        public function addArgument($name, $mode = null, $description = '', $default = null);
        public function addOption($name, $shortcut = null, $mode = null, $description = '', $default = null);
        public function setDescription($description);
        public function setHelp($help);
        public function setAliases($aliases);
    }

Basically you create a class which extends `Command`. You need to implement 2
methods:

* `configure`: the configuration of the command's name, arguments, options, etc
* `execute`: where you process the input, call your services and write to the
   output

The `interact` method is called before the `execute` one: it allows you to ask
questions to the user to set more input arguments and options.

Here's my stand on arguments and options modes:

* an argument should always be required (`InputArgument::REQUIRED`)
* a flag is an option without value (`InputOption::VALUE_NONE`)
* an option should always have a required value (`InputOption::VALUE_REQUIRED`),
  don't forget to provide a default one

### Input

The container of the arguments and options given by the user:

    <?php

    namespace Symfony\Component\Console\Input;

    interface InputInterface
    {
        public function getArgument($name);
        public function getOption($name);
    }

The `Application` validates a part of the input: it checks if the command
actually accepts the given arguments and options (is the value required? Does
the `hello:world` command have a `--yell` option? etc), but you still need to
validate the input against your business rules (the `--number` option should
be an integer, the `name` argument should be escaped to avoid SQL injection,
etc).

### Output

A convenient object which allows you to write on the console output:

    <?php

    namespace Symfony\Component\Console\Output;

    abstract class Output implements OutputInterface
    {
        public function writeln($messages, $type = self::OUTPUT_NORMAL);
    }

The `writeln` method allows you to write a new line (with a newline character at
the end). If the given `message` is an array, it will print each elements on a
new line.

The tags allow you to color some parts:

* green text for informative messages (usage example: `<info>foo</info>`)
* yellow text for comments (usage example: `<comment>foo</comment>`)
* black text on a cyan background for questions (usage example: `<question>foo</question>`)
* white text on a red background for errors (usage example: `<error>foo</error>`)

### ConsoleLogger

Another brand new class from the version 2.5:

    <?php

    namespace Symfony\Component\Console\Logger;

    use Psr\Log\AbstractLogger;
    use Symfony\Component\Console\Output\OutputInterface;

    class ConsoleLogger extends AbstractLogger
    {
        public function __construct(
            OutputInterface $output,
            array $verbosityLevelMap = array(),
            array $formatLevelMap = array()
        );

        public function log($level, $message, array $context = array());
    }

As you can see, it uses the `OutputInterface` provided by the `Application`.
You should inject this logger into your services, this will allow them to write
messages on the standard output of the console while keeping them decoupled from
this component (so you can use these services in a web environment).

Oh, and the good news is: it colors the output and decides whether or not to
print it depending on the verbosity and level of log! An error message would
always be printed in red, an informative message would be printed in green if
you pass the `-vv` option.

## Standalone example

Just like any other component, the Console can be used as a standalone library.

In this example, we'll create a tool which will create a `LICENSE` file, just
like [fossil](https://github.com/gnugat/fossil) (the {{ link('posts/2014-01-15-bootstrap-markdown-files-of-your-FOSS-project.md', 'bootstraper of markdown files for your FOSS projetcs') }}).

### Creating the application

To begin, let's install the component using [Composer](https://getcomposer.org/):

    $ curl -sS https://getcomposer.org/installer | php # Downloading composer
    $ ./composer.phar require "symfony/console:~2.5@dev"

Then create an empty application:

    #!/usr/bin/env php
    <?php
    // File: fossil

    require __DIR__.'/vendor/autoload.php';

    use Symfony\Component\Console\Application;

    $application = new Application('Fossil', '2.0.0');
    $application->run();

### Creating the command

Our command has two arguments:

* the name for the copyright
* the year for the copyright

It can also take the path of the project as an option (we'll provide the
current directory as default value).

Let's create it:

    <?php
    // File: src/Gnugat/Fossil/LicenseCommand.php

    namespace Gnugat\Fossil;

    use Symfony\Component\Console\Command\Command;
    use Symfony\Component\Console\Input\InputArgument;
    use Symfony\Component\Console\Input\InputOption;
    use Symfony\Component\Console\Input\InputInterface;
    use Symfony\Component\Console\Output\OutputInterface;

    class LicenseCommand extends Command
    {
        protected function configure()
        {
            $this->setName('license');
            $this->setDescription('Bootstraps the license file of your project');

            $this->addArgument('author', InputArgument::REQUIRED);
            $this->addArgument('year', InputArgument::REQUIRED);

            $this->addOption('path', 'p', InputOption::VALUE_REQUIRED, '', getcwd());
        }

        protected function execute(InputInterface $input, OutputInterface $output)
        {
        }
    }

### Registering the command

Our command doesn't do anything yet, but we can already register it in our
application:

    #!/usr/bin/env php
    <?php
    // File: fossil

    require __DIR__.'/vendor/autoload.php';

    use Symfony\Component\Console\Application;
    use Gnugat\Fossil\LicenseCommand;

    $command = new LicenseCommand();

    $application = new Application('Fossil', '2.0.0');
    $application->add($command);
    $application->run();

In order for it to run, you'll need to register the namespace in the autoloader
by editing the `composer.json` file at the root of the project:

    {
        "require": {
            "symfony/console": "~2.5@dev"
        },
        "autoload": {
            "psr-4": { "": "src" }
        }
    }

Then you need to run `./composer.phar update` to update the configuration.

### Using the Filesystem component

In `fossil`, [templates](https://github.com/gnugat/fossil/tree/master/skeletons)
are retrieved using the
[Finder component](http://symfony.com/doc/current/components/finder.html), their
values are replaced using [Twig](http://twig.sensiolabs.org/) and written using the
[Filesystem component](http://symfony.com/doc/current/components/filesystem.html).

In order to keep this article short, we'll:

* use a fictive license which requires only the copyright line
* simply store the `LICENSE` template in the command
* inject the values using `implode`

This means that you have to install the new component:

    $ ./composer.phar require "symfony/filesystem:~2.4"

And then you need to fill the `execute` method:

    <?php
    // File: src/Gnugat/Fossil/LicenseCommand.php

    namespace Gnugat\Fossil;

    use Symfony\Component\Console\Command\Command;
    use Symfony\Component\Console\Input\InputInterface;
    use Symfony\Component\Console\Output\OutputInterface;
    use Symfony\Component\Filesystem\Filesystem;

    class LicenseCommand extends Command
    {
        // configure method...

        protected function execute(InputInterface $input, OutputInterface $output)
        {
            $path = $input->getOption('path').'/LICENSE';
            $license = implode(' ', array(
                'Copyright (c)',
                $input->getArgument('author'),
                $input->getArgument('year'),
            ));

            $filesystem = new Filesystem();
            $filesystem->dumpFile($path, $license.PHP_EOL);

            $output->writeln(sprintf('Created the file %s', $path));
        }
    }

Now running `./fossil license "Loïc Chardonnet" "2013-2014" -p="/tmp"` will
output the message "Created the file /tmp/LICENSE", which should be what really
happened.

### Thin controller, many small services

I'm not a big fan of putting logic in my commands, so generally I use services
to do the actual job:

    <?php
    // File src/Gnugat/Fossil/DocumentationWriter.php

    namespace Gnugat\Fossil;

    use Symfony\Component\Filesystem\Filesystem;
    use Psr\Log\LoggerInterface;

    class DocumentationWriter
    {
        private $filesystem;
        private $logger;

        public function __construct(Filesystem $filesystem, LoggerInterface $logger)
        {
            $this->filesystem = $filesystem;
            $this->logger = $logger;
        }

        public function write($path, $content)
        {
            $this->filesystem->dumpFile($path, $content);
            $this->logger->notice(sprintf('Created file %s', $path));
        }
    }

As you can see, the `DocumentationWriter` isn't very big. It might seem
overkill, but now it's easy to write tests which will check if the `LICENSE`
file has been created. Also, in `fossil` the class does a bit more work: it
checks if the file already exists, and takes a "force overwrite" option into
account.

You'll also notice that we inject a logger to notice the user of what happens.
We need to install the PSR-3 logger interface:

    $ composer require "psr/log:~1.0"

Our command will now be much thinner, just like any controller should be (MVC
can also be applied in CLI):

    <?php
    // File: src/Gnugat/Fossil/LicenseCommand.php

    namespace Gnugat\Fossil;

    use Gnugat\Fossil\DocumentationWriter;
    use Symfony\Component\Console\Command\Command;
    use Symfony\Component\Console\Input\InputInterface;
    use Symfony\Component\Console\Logger\ConsoleLogger;
    use Symfony\Component\Console\Output\OutputInterface;
    use Symfony\Component\Filesystem\Filesystem;

    class LicenseCommand extends Command
    {
        // configure method...

        protected function execute(InputInterface $input, OutputInterface $output)
        {
            $path = $input->getOption('path').'/LICENSE';
            $license = implode(' ', array(
                'Copyright (c)',
                $input->getArgument('author'),
                $input->getArgument('year'),
            ));

            $filesystem = new Filesystem();
            $logger = new ConsoleLogger($output);
            $documentationWriter = new DocumentationWriter($filesystem, $logger);

            $documentationWriter->write($path, $license.PHP_EOL);
        }
    }

To be fair, our command is longer. But it **is** thinner as it now has less
responsibilities:

* it retrieves the input
* creates the dependencies
* calls the services

If you run again `./fossil license "Loïc Chardonnet" "2013-2014" -p="/tmp"`,
you won't see anything: `ConsoleLogger` hides informative messages by default.
You need to pass the verbose option to see the message:

    $ ./fossil license -v "Loïc Chardonnet" "2013-2014" -p="/tmp"

### Registering the services

The dependency creation isn't a responsibility a controller should have. We'll
delegate this to the
[Dependency Injection component](http://symfony.com/doc/current/components/dependency_injection/introduction.html):

    $ ./composer.phar require "symfony/dependency-injection:~2.4"

We'll also install the
[Config component](http://symfony.com/doc/current/components/config/introduction.html):

    $ ./composer.phar require "symfony/config:~2.4"

If you don't know yet this component, go read
{{ link('posts/2014-01-29-sf2-di-component-by-example.md', 'this helpful article') }}.

We'll create a XML file to configure the registration of our services:

    <?xml version="1.0" ?>

    <!-- File: config/services.xml -->

    <container xmlns="http://symfony.com/schema/dic/services"
        xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
        xsi:schemaLocation="http://symfony.com/schema/dic/services http://symfony.com/schema/dic/services/services-1.0.xsd">
        <services>
            <service id="symfony.application"
                class="Symfony\Component\Console\Application">
                <argument key="name">Fossil</argument>
                <argument key="version">2.0.0</argument>
                <call method="add">
                     <argument type="service" id="fossil.license_command" />
                </call>
            </service>

            <service id="fossil.license_command" class="Gnugat\Fossil\LicenseCommand">
                <argument type="service" id="fossil.documentation_writer" />
            </service>

            <service id="fossil.documentation_writer" class="Gnugat\Fossil\DocumentationWriter">
                <argument type="service" id="symfony.filesystem" />
                <argument type="service" id="symfony.console_logger" />
            </service>

            <service id="symfony.filesystem" class="Symfony\Component\Filesystem\Filesystem">
            </service>

            <service id="symfony.console_logger" class="Symfony\Component\Console\Logger\ConsoleLogger">
                <argument type="service" id="symfony.console_output" />
            </service>

            <service id="symfony.console_output"
                class="Symfony\Component\Console\Output\ConsoleOutput">
            </service>
        </services>
    </container>

As you can see, I've delegated **every** construction to the DIC (Dependency
Injection Container), even the construction of the application. Now the command
looks like this:

        <?php
    // File: src/Gnugat/Fossil/LicenseCommand.php

    namespace Gnugat\Fossil;

    use Gnugat\Fossil\DocumentationWriter;
    use Symfony\Component\Console\Command\Command;
    use Symfony\Component\Console\Input\InputArgument;
    use Symfony\Component\Console\Input\InputOption;
    use Symfony\Component\Console\Input\InputInterface;
    use Symfony\Component\Console\Output\OutputInterface;

    class LicenseCommand extends Command
    {
        private $documentationWriter;

        public function __construct(DocumentationWriter $documentationWriter)
        {
            $this->documentationWriter = $documentationWriter;

            parent::__construct();
        }

        protected function configure()
        {
            $this->setName('license');
            $this->setDescription('Bootstraps the license file of your project');

            $this->addArgument('author', InputArgument::REQUIRED);
            $this->addArgument('year', InputArgument::REQUIRED);

            $this->addOption('path', 'p', InputOption::VALUE_REQUIRED, '', getcwd());
        }

        protected function execute(InputInterface $input, OutputInterface $output)
        {
            $path = $input->getOption('path').'/LICENSE';
            $license = implode(' ', array(
                'Copyright (c)',
                $input->getArgument('author'),
                $input->getArgument('year'),
            ));

            $this->documentationWriter->write($path, $license.PHP_EOL);
        }
    }

And the console now contains the DIC initialization:

    #!/usr/bin/env php
    <?php
    // File: fossil

    use Symfony\Component\Config\FileLocator;
    use Symfony\Component\DependencyInjection\ContainerBuilder;
    use Symfony\Component\DependencyInjection\Loader\XmlFileLoader;

    require __DIR__.'/vendor/autoload.php';

    $container = new ContainerBuilder();
    $loader = new XmlFileLoader($container, new FileLocator(__DIR__.'/config'));
    $loader->load('services.xml');

    $output = $container->get('symfony.console_output');

    $application = $container->get('symfony.application');
    $application->run(null, $output);

And voilà! You now know how to create CLI applications :) .

## Conclusion

The Console component allows you to create CLI applications. The commands are a
thin layer which gathers the input and call services. Those services can then
output messages to the user using a special kind of logger.

Although this article was a bit long, I might have missed something here, so
if you have any feedbacks/questions, be sure to contact me on
[Twitter](https://twitter.com/epiloic).
