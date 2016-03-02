---
layout: post
title: The Ultimate Developer Guide to Symfony - Console
tags:
    - symfony
    - ultimate symfony series
    - reference
---

> **Reference**: This article is intended to be as complete as possible and is
> kept up to date.

> **TL;DR**: `$statusCode = $application->run($input);`

In this guide we explore the standalone libraries (also known as "Components")
provided by [Symfony](http://symfony.com) to help us build applications.

We've already seen:

* [HTTP Kernel and HTTP Foundation](/2016/02/03/ultimate-symfony-http-kernel.html)
* [Event Dispatcher](/2016/02/10/ultimate-symfony-event-dispatcher.html)
* [Routing and YAML](/2016/02/17/ultimate-symfony-routing.html)
* [Dependency Injection](/2016/02/24/ultimate-symfony-dependency-injection.html)

We're now about to check the last one: Console.

## Application

Symfony provides a [Console component](http://symfony.com/doc/current/components/console/introduction.html)
which allows us to create CLI commands. Its main class is `Application`:

```php
<?php

namespace Symfony\Component\Console;

use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;
use Symfony\Component\Console\Command\Command;

class Application
{
    public function __construct($name = 'UNKNOWN', $version = 'UNKNOWN');

    public function add(Command $command);
    public function setDefaultCommand($commandName);
    public function run(InputInterface $input = null, OutputInterface $output = null);

    public function setAutoExit($boolean);
}
```

> **Note**: This snippet is a truncated version. Please note that `Application`
> is (unfortunately) not an interface.

We can create it as follow:

```php
<?php
// /tmp/console.php

use Symfony\Component\Console\Application;
use Symfony\Component\Console\Input\ArgvInput;

$application = new Application('My Application', 'v4.2.3');
$application->add($command);
$application->setDefaultCommand($command->getName());

$application->run(new ArgvInput());
```

Which can then be used as follow:

```
php /tmp/console.php
```

> **Note**: After running the command, `Application` will automatically stop
> using `exit`.
> As it can sometimes be inconvenient (for example in tests), we can disable it
> with this line: `$application->setAutoExit(false);`

Out of the box, `Application` has two commands:

* `list`, list all available commands (it's the default command if `setDefaultCommand` hasn't been used)
* `help`, displays a description with available arguments and options for the current command

## Command

In order for `Application` to be useful, we need to create commands. This can be
done by extending `Command`:

```php
<?php

namespace Symfony\Component\Console\Command;

use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Output\OutputInterface;

class Command
{
    public function run(InputInterface $input, OutputInterface $output);
    // Called by run
    protected function execute(InputInterface $input, OutputInterface $output);
    protected function interact(InputInterface $input, OutputInterface $output);

    protected function configure();
    // To be called in configure
    public function setName($name);
    public function addArgument($name, $mode = null, $description = '', $default = null);
    public function addOption($name, $shortcut = null, $mode = null, $description = '', $default = null);
    public function setDescription($description);
    public function setHelp($help);
    public function setAliases($aliases);
}
```

We can configure the command (name, arguments, options, description, etc) in the
`configure` method, we can define more options to be asked interractively in
the `interact` method (e.g. `Are you sure? (Y/n)`) and finally we can write the
command logic in the `execute` method.

Commands are to Console what Controllers are to HttpKernel: their responsibility
is to extract input parameters, pass them to a service and then put the service's
returned value in the output.

## Input

Input parameters are wrapped in the following interface:

```php
<?php

namespace Symfony\Component\Console\Input;

interface InputInterface
{
    public function getArgument($name);
    public function getOption($name);
}
```

Out of the box we have the following implementations:

* `ArgvInput`: wraps CLI arguments comming from `$_SERVER['argv']`
* `ArrayInput`: define arguments using an array, which is useful for tests

`Application` will take care of validating `InputInterface` parameters against
the `Command` configuration (e.g. if required arguments present).

## Output

While `InputInterface` can be seen as a value object, `OutputInterface` should
be seen as a service able to send informations to a stream:

```php
<?php

namespace Symfony\Component\Console\Output;

abstract class Output implements OutputInterface
{
    public function writeln($messages, $type = self::OUTPUT_NORMAL);
}
```

The `writeln` method allows us to write a new line (with a newline character at
the end). If the given message is an array, it will print each elements on a new
line.

The given message can contain tags (e.g. `Arthur <info>Dent</info>`), which can
be used to format it. Out of the box it will color the followings:

* green text for informative messages (usage example: `<info>Arthur Dent</info>`)
* yellow text for comments (usage example: `<comment>Tricia McMillan</comment>`)
* black text on a cyan background for questions (usage example: `<question>Ford Prefect</question>`)
* white text on a red background for errors (usage example: `<error>Marvin</error>`)

## Conclusion

The Console component allows us to create CLI applications. Its Commands are a
thin layer which gathers the input and call services. Those services can then
output messages to the user.

> **Note**: Since Symfony follows a [Console Output Formating Style Guide](https://github.com/symfony/symfony-docs/issues/4265),
> the Console component provides the following helper class:
>
> ```php
> <?php
>
> namespace Symfony\Component\Console\Style;
>
> use Symfony\Component\Console\Input\InputInterface;
> use Symfony\Component\Console\Output\OutputInterface;
> use Symfony\Component\Console\Question\Question;
>
> class SymfonyStyle
> {
>     public function __construct(InputInterface $input, OutputInterface $output);
>
>     public function block($messages, $type = null, $style = null, $prefix = ' ', $padding = false);
>     public function title($message);
>     public function section($message);
>     public function listing(array $elements);
>     public function text($message);
>
>     public function comment($message);
>     public function success($message);
>     public function error($message);
>     public function warning($message);
>     public function note($message);
>     public function caution($message);
>
>     public function table(array $headers, array $rows);
>
>     public function ask($question, $default = null, $validator = null);
>     public function askHidden($question, $validator = null);
>     public function confirm($question, $default = true);
>     public function choice($question, array $choices, $default = null);
>     public function askQuestion(Question $question);
>
>     public function progressStart($max = 0);
>     public function progressAdvance($step = 1);
>     public function progressFinish();
>     public function createProgressBar($max = 0);
>
>     public function writeln($messages, $type = self::OUTPUT_NORMAL);
>     public function write($messages, $newline = false, $type = self::OUTPUT_NORMAL);
>     public function newLine($count = 1);
> }
> ```
