---
layout: post
title: Strategy Pattern, Symfony and autowiring
tags:
    - design pattern
    - symfony
---

> **TL;DR**: Since Symfony 5.3
>
> Tag the "Strategy" Interface with the attribute `[#AutoconfigureTag]`:
>
> ```php
> <?php
>
> use Symfony\Component\DependencyInjection\Attribute\AutoconfigureTag;
> 
> #[AutoconfigureTag]
> interface Strategy
> {
>     // Add your Strategy methods below, for example
>     // (please use a more descriptive name than "algorithm"...):
>     public function algorithm();
>
>     // *IF* your Strategies need to be executed in a specific order,
>     // then add a method that returns the priority (highest priority first, lowest priority last)
>     // Note: it MUST be static
>     public static function getDefaultPriority(): int;
>
>     // *IF* your Strategies are executed conditionally,
>     // then add a "predicate" method (eg named `supports()`):
>     public function predicate($input): bool
> }
> ```
>
> Inject the `iterable` that contains all tagged "Strategy" implementations
> in the "Context"'s constructor with the attribute `#[TaggedIterator(<tag>)]`:
>
> ```php
> <?php
>
> class Context
> {
>     public function __construct(
>         // *IF* your Strategies need to be executed in a specific order,
>         // then use the `defaultPriorityMethod` parameter and set it with the Strategy's static method name
>         #[TaggedIterator(Strategy::class, defaultPriorityMethod: 'getDefaultPriority')]
>         private iterable $strategies,
>     ) {
>     }
>
>     public function operation($input)
>     {
>         foreach ($this->strategies() as $strategy) {
>             // *IF* your Strategies need to be executed conditionally,
>             // then add a if statement that verifies the Strategy's predicate method
>             if ($strategy->predicate($input)) {
>                 $strategy->algorithm();
>
>                 // *IF* you only want the first matching Strategy to be executed,
>                 // then break the loop here
>                 break;
>             }
>         }
>     }
> }
> ```
>
> Set `autowire` and `autoconfigure` parameters to be `true` in the DIC configuration:
>
> ```yaml
> services:
>     _defaults:
>         autowire: true
>         autoconfigure: true
> ```

The Strategy Pattern can be really useful when you want to avoid multiple
conditionals, and/or when you want to add new repetitive chunks of logic
in a maintainable way.

Let's see how to use it in a Symfony application, and how autowiring can help
us configure it.

Note that the code snippets below will NOT be truncated, they'll always contain
the full code (so no things like `// rest of the class below` comments).

## Use Case Example

Some classes are just bound to contain repeated chunks of similar logic:

```php
<?php

class EmailDailyReports
{
    public function __construct(
        private BuildSpreadsheet $buildSpreadsheet,
        private Mailer $mailer,
        private WriteSpreadsheet $writeSpreadsheet,
        private RetrieveDataForReportOne $retrieveDataForReportOne,
        private RetrieveDataForReportTwo $retrieveDataForReportTwo,
    ) {
    }

    public function send(\DateTime $startDate, \DateTime $endDate): void
    {
        $reportOneData = $this->retrieveDataForReportOne->fromDatabase($startDate, $endDate);
        $reportOneName = 'Report One';
        $reportOneSpreadsheet = $this->buildSpreadsheet->using($reportOneData, $reportOneName);
        $reportOneFilename = $this->writeSpreadsheet->save($reportOneSpreadsheet);
        
        $reportTwoData = $this->retrieveDataForReportTwo->fromDatabase($startDate, $endDate);
        $reportTwoName = 'Report Two';
        $reportTwoSpreadsheet = $this->buildSpreadsheet->using($reportTwoData, $reportTwoName);
        $reportTwoFilename = $this->writeSpreadsheet->save($reportTwoSpreadsheet);

        $email = (new Email())
            ->from('sender@example.com')
            ->to('recipient@example.com')
            ->attachFromPath($reportOneFilename, $reportOneName, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
            ->attachFromPath($reportTwoFilename, $reportTwoName, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet')
            ->subject('Daily Reports')
            ->text('Find reports in attached files');
        $this->mailer->send($email);
    }
}
```

This `EmailDailyReports` class builds spreadsheets and sends emails for reports.

The retrieval of the data for each report is delegated to a dedicated service.

This is fine as is, with currently only 2 reports to manage...
But what if we need to add 1 more report? 2 more reports? 30 more reports?

## Strategy Pattern

This use case is the perfect candidate for the Strategy Pattern.

`EmailDailyReports` would be considered the "Context" class,
and the services that retrieve the report data would be the "Strategies".

Let's refactor `EmailDailyReports` to implement this design pattern.

First we create a Strategy interface:

```php
<?php

interface RetrieveDataForReport
{
    public function fromDatabase(\DateTime $startDate, \DateTime $endDate): array;
    public function getName(): string;
}
```

Then we make sure the Strategy implementations both implement it
(`RetrieveDataForReportOne` and `RetrieveDataForReportTwo`).

Finally we refactor the Context class to be injected with a collection of
Strategies, and iterate through them:

```php
<?php

class EmailDailyReports
{
    public function __construct(
        private BuildSpreadsheet $buildSpreadsheet,
        private Mailer $mailer,
        private WriteSpreadsheet $writeSpreadsheet,
    ) {
    }

    public function send(\DateTime $startDate, \DateTime $endDate): void
    {
        $email = (new Email())
            ->from('sender@example.com')
            ->to('recipient@example.com')
            ->subject('Daily Reports')
            ->text('Find reports in attached files');

        foreach ($this->retrieveDataForReports as $retrieveDataForReport) {
            $reportData = $retrieveDataForReport->fromDatabase($startDate, $endDate);
            $reportName = $retrieveDataForReport->getReportName();
            $reportSpreadsheet = $this->buildSpreadsheet->using($reportData, $reportName);
            $reportFilename = $this->writeSpreadsheet->save($reportSpreadsheet);

            $email->attachFromPath($reportFilename, $reportName, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        }

        $this->mailer->send($email);
    }

    private array $retrieveDataForReports = [];

    public function register(RetrieveDataForReport $retrieveDataForReport): void
    {
        $this->retrieveDataForReports[] = $retrieveDataForReport;
    }
}
```

If the order in which the reports are built is important,
then we need to add a bit of extra logic:

```php
<?php

class EmailDailyReports
{
    public function __construct(
        private BuildSpreadsheet $buildSpreadsheet,
        private Mailer $mailer,
        private WriteSpreadsheet $writeSpreadsheet,
    ) {
    }

    public function send(\DateTime $startDate, \DateTime $endDate): void
    {
        $email = (new Email())
            ->from('sender@example.com')
            ->to('recipient@example.com')
            ->subject('Daily Reports')
            ->text('Find reports in attached files');

        foreach ($this->getSortedRetrieveDataForReports() as $retrieveDataForReport) {
            $reportData = $retrieveDataForReport->fromDatabase($startDate, $endDate);
            $reportName = $retrieveDataForReport->getReportName();
            $reportSpreadsheet = $this->buildSpreadsheet->using($reportData, $reportName);
            $reportFilename = $this->writeSpreadsheet->save($reportSpreadsheet);

            $email->attachFromPath($reportFilename, $reportName, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        }

        $this->mailer->send($email);
    }

    private const int DEFAULT_PRIORITY = 100;
    private const array NOT_SORTED = [];

    private array $unsortedRetrieveDataForReports = [];
    private array $sortedRetrieveDataForReports = self::NOT_SORTED;

    public function register(
        RetrieveDataForReport $retrieveDataForReport,
        int $priority = self::DEFAULT_PRIORITY,
    ): void {
        $this->unsortedRetrieveDataForReports[$priority][] = $retrieveDataForReport;
        $this->sortedRetrieveDataForReports = self::NOT_SORTED;
    }

    private function getSortedRetrieveDataForReports(): void
    {
        if (self::NOT_SORTED === $this->sortedRetrieveDataForReports)) {
            // Strategies with higher priority need to be executed before the ones with lower priority
            krsort($this->unsortedRetrieveDataForReports);

            // Flattens strategies by removing the "priority" dimension from the array
            $this->sortedRetrieveDataForReports = array_merge(...$this->unsortedRetrieveDataForReports);
        }
        
        return $this->sortedRetrieveDataForReports;
    }
}
```

Have you heard of the Symfony component EventDispatcher?
While it is a well known implementation of the Observer design pattern,
the way the EventListeners (strategies) are registered and executed in the
EventDispatcher (context) is very similar to this.

## Configuring DI in Symfony - YAML

Speaking of Symfony, how would we configure the Dependency Injection Container
for this service? First, let's write the YAML configuration:

```yaml
services:
    'EmailDailyReports':
        arguments:
            - '@BuildSpreadsheet'
            - '@Mailer'
            - '@WriteSpreadsheet'
        calls:
            - register:
                - '@RetrieveDataForReportOne'
                - 200
            - register:
                - '@RetrieveDataForReportTwo'
                - 100

    'BuildSpreadsheet': ~
    'Mailer': ~
    'WriteSpreadsheet': ~
    'RetrieveDataForReportOne': ~
    'RetrieveDataForReportTwo': ~
```

Note that we need to write the priorities here in the `EmailDailyReports`
service definition. The `calls` section is fine for now, as we only have two
Strategies.

But what if we need to add 1 more report? 2 more reports? 30 more reports?

## Configuring DI in Symfony - Compiler Passes

The entire `calls` section can be removed from the configuration,
by creating a CompilerPass:

```php
<?php
  
use Symfony\Component\DependencyInjection\Compiler\CompilerPassInterface;
use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\DependencyInjection\Reference;
  
class RegisterRetrieveDataForReportsCompilerPass implements CompilerPassInterface
{ 
    public function process(ContainerBuilder $container): void
    {
        // Get Context service definition
        $emailDailyReports = $container->findDefinition(EmailDailyReports::class);

        // Get iterable of all the Strategy service definitions (they'll be tagged with the Strategy interface FQCN)
        $retrieveDataForReports = $container->findTaggedServiceIds(RetrieveDataForReport::class);

        foreach ($retrieveDataForReports as $id => $tags) {
            // In theory you can tag a service many times with the same tag,
            // but in our case here, there'll only be one tag
            foreach ($tags as $retrieveDataForReport) {
                // call the Setter Injection on the Context service definition
                $emailDailyReports->addMethodCall('register', [
                    new Reference($id),             
                    $retrieveDataForReport['priority'] ?? EmailDailyReports::DEFAULT_PRIORITY,
                ]);            
            }
        }
    }
}
```

Also, make sure to register the CompilerPass in the Bundle:

```php
<?php
   
use Symfony\Component\DependencyInjection\ContainerBuilder;
use Symfony\Component\HttpKernel\Bundle\Bundle;
  
class MyBundle extends Bundle
{ 
    public function build(ContainerBuilder $container): void
    {
        parent::build($container);      
  
        $container->addCompilerPass(new RegisterRetrieveDataForReportsCompilerPass());
    }
}
```

Note that now the priorities need to be defined in the tags of the
RetrieveDataForReport service definitions:

```yaml
services:
    'EmailDailyReports':
        arguments:
            - '@BuildSpreadsheet'
            - '@Mailer'
            - '@WriteSpreadsheet'

    'BuildSpreadsheet': ~
    'Mailer': ~
    'WriteSpreadsheet': ~
    'RetrieveDataForReportOne':
        tags:
            - { name: 'RetrieveDataForReport', priority: 200 }
    'RetrieveDataForReportTwo':
        tags:
            - { name: 'RetrieveDataForReport', priority: 100 }
```

Defining manually the service definition for every classes in our project is
all fun and games, and having to set tags is fine for now, as we only have two
Strategies.

But what if we need to add 1 more report? 2 more reports? 30 more reports?

## Configuring DI in Symfony (5.3) - TaggedIterator

Since [Symfony 3.3](https://github.com/symfony/symfony/pull/22295),
the Dependency Injection's autowiring will inject dependencies named after the
type of the service arguments.

This works great for the constructor of `EmailDailyReports` (note the
conspicuously missing `EmailDailyReports`, `BuildSpreadsheet`, `Mailer` and
`WriteSpreadsheet`):

```yaml
services:
    _defaults:
        autowire: true

    'RetrieveDataForReportOne':
        tags:
            - { name: 'RetrieveDataForReport', priority: 200 }
    'RetrieveDataForReportTwo':
        tags:
            - { name: 'RetrieveDataForReport', priority: 100 }
```

By adding `_defaults.autowire: true`, we were able to remove 8 lines of configuration!

Then, since [Symfony 5.3](https://github.com/symfony/symfony/pull/39804),
it is possible to automatically tag all the implementations,
by using the `#[AutoconfigureTag]` attribute on the interface:

```php
<?php

use Symfony\Component\DependencyInjection\Attribute\AutoconfigureTag;

#[AutoconfigureTag]
interface RetrieveDataForReport
{
    public function fromDatabase(\DateTime $startDate, \DateTime $endDate): array;
    public function getName(): string;
    public static function getDefaultPriority(): int;
}
```

This only works if `_defaults.autoconfigure` is set to `true` in the config
(note the conspicuously missing `RetrieveDataForReportOne` and `RetrieveDataForReportTwo`):

```yaml
services:
    _defaults:
        autowire: true
        autoconfigure: true
```

You might have noticed that we've added a `public static function getDefaultPriority(): int`
method to our interface. Since the priorities configuration is gone from YAML,
the have to be returned by the implementations: 

- `RetrieveDataForReportOne::getDefaultPriority()` needs to return `200`
- `RetrieveDataForReportTwo::getDefaultPriority()` needs to return `100`

Finally, since [Symfony 5.3](https://github.com/symfony/symfony/pull/40406),
it is also possible to inject an `iterator` containing all services that have a specific tag,
by using the `#[TaggedIterator]` attribute. Let's use it in the "Context" class:

```php
<?php

class EmailDailyReports
{
    public function __construct(
        private BuildSpreadsheet $buildSpreadsheet,
        private Mailer $mailer,
        private WriteSpreadsheet $writeSpreadsheet,
        #[TaggedIterator(RetrieveDataForReport::class, defaultPriorityMethod: 'getDefaultPriority')]
        private iterable $retrieveDataForReports,
    ) {
    }

    public function send(\DateTime $startDate, \DateTime $endDate): void
    {
        $email = (new Email())
            ->from('sender@example.com')
            ->to('recipient@example.com')
            ->subject('Daily Reports')
            ->text('Find reports in attached files');

        foreach ($this->retrieveDataForReports as $retrieveDataForReport) {
            $reportData = $retrieveDataForReport->fromDatabase($startDate, $endDate);
            $reportName = $retrieveDataForReport->getReportName();
            $reportSpreadsheet = $this->buildSpreadsheet->using($reportData, $reportName);
            $reportFilename = $this->writeSpreadsheet->save($reportSpreadsheet);

            $email->attachFromPath($reportFilename, $reportName, 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
        }

        $this->mailer->send($email);
    }
}
```

This means we can remove the `CompilerPass` (and unregister it from the Bundle).

You'll also note that we've removed from `EmailDailyReports` the following methods:

- `register()`: the "Strategies" are no longer injected one by one
- `getSortedRetrieveDataForReports()`: TaggedIterator supports sorting by priorities,
  but it requires the "Strategies" to have a **static** method that returns the priority

## Conclusion

To sum up:

- Tag the "Strategy" Interface with the attribute `[#AutoconfigureTag]`
- Inject the `iterable` that contains all tagged "Strategy" implementations
  in the "Context"'s constructor with the attribute `#[TaggedIterator(<tag>)]`
- Set `autowire` and `autoconfigure` parameters to be `true` in the DIC configuration

The use case doesn't demonstrate how to avoid multiple use statements,
but this can be done by adding a "predicate" method to the "Strategy":
this will allow the "Context" to only execute a sub set of the strategies.

It's even possible to only execute the first strategy,
by adding a `break` in the loop.

I've tried to synthesize as much information as possible at the top of this article,
in the ironically (yet aptly) named "TL;DR" section.

I hope this'll prove useful to you (it'll definitely be for me!).
