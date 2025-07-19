---
layout: post
title: PHPUnit Best Practices (Ultimate Guide)
tags:
    - phpunit
    - reference
---

Forge battle-tested code, under the hammer of PHPUnit.

* [Unit Tests](#unit-tests)
    * [Factory Methods](#factory-methods)
    * [Attributes](#attributes)
    * [Data Providers](#data-providers)
    * [Testdox](#testdox)
    * [Coding Standards](#coding-standards)
    * [Principles](#principles)
* [Mocking](#mocking)
* [Integration Tests](#integration-tests)
    * [Smoke Tests](#smoke-tests)
* [Useful CLI options](#useful-cli-options)
    * [Configuration](#configuration)

## Unit Tests

> _Inspired by **Sebastian Bergmann**, _Sources_:
> 
> * [So you think you know PHPUnit - Sebastian Bergmann - PHPDD2024](https://www.youtube.com/watch?v=qwRdnoeq1H8)
> * [Optimizing Your Test Suite - Sebastian Bergmann - PHP fwdays 2021](https://www.youtube.com/watch?v=wR6YflVkAt4)
> * [Sebastian's raytracer project](https://github.com/sebastianbergmann/raytracer/)
> * [PHPUnit documentation](https://phpunit.de/documentation.html)

Here's a unit test for a `CheckArray->check(string $field, mixed $value): array` class:

```php
<?php

declare(strict_types=1);

namespace App\Tests\Unit\Domain\Check;

use App\Domain\Check\CheckArray;
use App\Domain\Exception\ValidationFailedException;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Small;
use PHPUnit\Framework\Attributes\TestDox;
use PHPUnit\Framework\TestCase;

#[CoversClass(CheckArray::class)]
#[Small]
class CheckArrayTest extends TestCase
{
    private const string FIELD = 'path.field_name';

    private function checkArray(): CheckArray
    {
        return new CheckArray();
    }

    public function test_it_accepts_valid_array(): void
    {
        $validArray = [23, 42, 1337];

        $this->assertSame($validArray, $this->checkArray()->check(
            self::FIELD,
            $validArray,
        ));
    }

    public function test_it_accepts_null(): void
    {
        // When checking that no exception is thrown
        $this->expectNotToPerformAssertions();

        $this->checkArray()->check(
            self::FIELD,
            null,
        );
    }

    /**
     * @return array<string, array{mixed}>
     */
    public static function nonArrayTypesProvider(): array
    {
        return [
            'string' => ['hello world'],
            'integer' => [42],
            'boolean' => [false],
        ];
    }

    #[DataProvider('nonArrayTypesProvider')]
    public function test_it_rejects_non_array_types(mixed $notAnArray): void
    {
        $this->expectException(ValidationFailedException::class);

        $this->checkArray()->check(
            self::FIELD,
            $notAnArray,
        );
    }
}
```

### Factory Methods

When the System Under Test (SUT) has a simple constructor,
or its instantiation is clear and consistent,
then instantiate it directly in each test method.

But when the SUT's constructor has multiple parameters,
or a couple of test method require the same specific configuration, 
consider moving that creation logic to a private factory method:

* it ensures test consistency and validity by eliminating configuration drift
* it centralizes complex instantiation logic, making tests more readable

Finally, when your SUT legitimately needs to be tested under different configurations,
create explicit factory methods that document these variations.

### Attributes

Attributes (`#[<Name>]`) were introduced in PHP 8 and PHPUnit 10,
they replace Annotations (PHPdoc `@<Name>`) which have been deprecated in PHPUnit 10
and removed in PHPUnit 12.

Their goal is to make PHP tooling more robust and IDE integration more reliable, use them!

**Specify targeted class**:

* `#[CoversClass]`: enforces proper test boundaries, prevents accidental coverage,
  and makes the intent clearer both to the readers and tools
  (code coverage, static analysis, etc)
* `#[UsesClass]`: if code from other classes is expected to be used

**Categorize tests** based on their scope, complexity and resource usage:

* `#[Small]` for testing individual components in isolation (unit),
  fast execution (typically under 100ms)
* `#[Medium]` for testing multiple components together in isolation (integration),
  moderate execution (typically under 1s)
* `#[Large]` for complete workflows (end to end),
  slow execution (over 1s)
* `#[Group]` for arbitrary categories (including temporary ones, eg `wip`)

### Data Providers

**Use Data Providers** to test different sets of inputs / outputs:

* `#[DataProvider(string $publicStaticMethodName)]`
  for a method in the test class
* `#[DataProviderExternal(string $className, string $publicStaticMethodName)]`
  for a method in a different class from the test one
* `#[TestWith(array $data)]`
  to provide one set at a time, without having to declare a static method

### Testdox

**Run PHPUnit with `--testdox` option** to get executable specifications:

* `#[TestDox(string $text)]`
  to customize what PHPUnit will display

> **Note 1**
>
> Running `phpunit --testdox` with the following data provider:
>
> ```php
>     public static function nonArrayTypesProvider(): array
>     {
>         return [
>             ['hello world'],
>             [42],
>             [false],
>         ];
>     }
>
>     #[DataProvider('nonArrayTypesProvider')]
>     public function test_it_rejects_non_array_types(mixed $notAnArray): void
> ```
>
> Will output:
>
> ```
> Check Array (App\Tests\Unit\Domain\Check\CheckArray)
>  ✔ It rejects non array types with data set 0
>  ✔ It rejects non array types with data set 1
>  ✔ It rejects non array types with data set 2
> ```

---

> **Note 2**
>
> This is equivalent to:
>
> ```php
>     #[TestWith(['hello world'])]
>     #[TestWith([42])]
>     #[TestWith([false])]
>     public function test_it_rejects_non_array_types(mixed $notAnArray): void
> ```

---

> **Note 3**
>
> However, we can use string keys to describe each set:
>
> ```php
>     public static function nonArrayTypesProvider(): array
>     {
>         return [
>             'string' => ['hello world'],
>             'integer' => [42],
>             'boolean' => [false],
>         ];
>     }
>
>     #[DataProvider('nonArrayTypesProvider')]
>     public function test_it_rejects_non_array_types(mixed $notAnArray): void
> ```
>
> Which will output:
>
> ```
> Check Array (App\Tests\Unit\Domain\Check\CheckArray)
>  ✔ It rejects non array types with string
>  ✔ It rejects non array types with integer
>  ✔ It rejects non array types with boolean
> ```

---

> **Note 4**
>
> Finally, we can also change the text with `#[TestDox]`:
>
> ```php
>     public static function nonArrayTypesProvider(): array
>     {
>         return [
>             'string' => ['hello world'],
>             'integer' => [42],
>             'boolean' => [false],
>         ];
>     }
>
>     #[DataProvider('nonArrayTypesProvider')]
>     #[TestDox('it rejects `$notAnArray` because it does not have type `array`')]
>     public function test_it_rejects_non_array_types(mixed $notAnArray): void
> ```
>
> Which will output:
>
> ```
> Check Array (App\Tests\Unit\Domain\Check\CheckArray)
>  ✔ it rejects `hello·world` because it does not have type `array`
>  ✔ it rejects `42` because it does not have type `array`
>  ✔ it rejects `false` because it does not have type `array`
> ```

### Coding Standards

**Follow Coding Standards** to ensure consistency across the PHP ecosystem,
and internal projects:

* [PSR-4](https://www.php-fig.org/psr/psr-4/) for file, namespace and class names
* [PSR-12](https://www.php-fig.org/psr/psr-12/) for the rest
* discuss, agree and enforce coding styles in your team
  eg using [PHP CS Fixer](https://cs.symfony.com/)

_Here are examples of topics you can debate_:

* **Enforce strict types declaration** (`declare(strict_types=1)`)
  to prevent type coercion bugs that can cause tests to pass when they shouldn't
* **Make test classes final** 
  as they should never be extended from
* **Use visibility and type hint keywords** 
  for future-proofing against language changes
* **Follow snake case for test method names**
  so they read as text, with underscores representing spaces
* **Use `$this` over `self`**
  to call PHPUnit assertions
* **Use `#[Test]` attribute and `it_` prefix**
  to help name test methods in an articulate way

### Principles

FIRST properties of Unit Tests, they should be:

* **Fast**: to provide a short feedback loop
* **Isolated**: one test failure shouldn't impact another test
* **Repeatable**: the outcome of a test should be consistent over time
* **Self-validating**: automated test should fail or pass for the right reason
* **Timely**: write the test around the time the code was written, not long after (but ideally before)

Follow [AAA](https://wiki.c2.com/?ArrangeActAssert),
each test method should group these functional sections, separated by blank lines:

1. **Arrange**: all necessary preconditions and input
2. **Act**: on the System Under Test (SUT)
3. **Assert**: that the expected results have occurred

Not necessarily in that order (eg when testing exceptions: Arrange, Expect, Act).

[DRY](https://wiki.c2.com/?DontRepeatYourself) vs DAMP (aka WET),
it's all about finding the right balance: pick whichever is more readable,
on a case-by-case basis.

> "DRY (Don't Repeat Yourself) increases maintainability
> by isolating change (risk) to only those parts of the system that must change.
>
> DAMP (Descriptive And Meaningful Phrases, _aka WET: We Edit Twice_) increases maintainability
> by reducing the time necessary to read and understand the code."
>
> — Chris Edwards

## Mocking

> **Note**: this is "In My Humble Opinion".

There are two Test Driven Development (TDD) schools of thought:

* **Chicago / Detroit (classical)**: use real objects, avoid mocks
* **London (specification Behaviour Driven Development - spec BDD)**:
  use mocks to describe interactions between the System Under Test (SUT) and its dependencies (collaborators)

The mocking library [prophecy](https://github.com/phpspec/prophecy)'s expressive syntax
allows for an approach that's more aligned with spec BDD.
It can be used in PHPUnit with the `phpspec/prophecy-phpunit` package:

```php
<?php

declare(strict_types=1);

namespace App\Tests\Unit\Domain\Event\Check;

use App\Domain\Check\CheckDateTimeIso8601;
use App\Domain\Event\Check\CheckStart;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Small;
use PHPUnit\Framework\TestCase;
use Prophecy\PhpUnit\ProphecyTrait;

#[CoversClass(CheckStart::class)]
#[Small]
final class CheckStartTest extends TestCase
{
    use ProphecyTrait;

    private const string FIELD = 'start';
    private const string START = '2025-06-17T13:00:00';

    public function test_it_checks_start(): void
    {
        $checkDateTimeIso8601 = $this->prophesize(CheckDateTimeIso8601::class);

        $checkDateTimeIso8601->check(
            self::FIELD,
            self::START,
        )->shouldBeCalled()->willReturn(self::START);

        $checkStart = new CheckStart(
            $checkDateTimeIso8601->reveal(),
        );
        $this->assertSame(self::START, $checkStart->check(
            self::FIELD,
            self::START,
        ));
    }
}
```

## Integration Tests

> 🤫 **Super Secret Tip**:
>
> PHPUnit instantiates the test class once per test method and once per data provider row.
> This is a fundamental design decision that prioritizes test isolation over performance.
>
> So if you have:
>
> * 5 regular test methods: that's 5 instances
> * 1 test method with 10 data provider rows: that's 10 instances
> * Total: 15 instances created
>
> Why This Matters:
>
> * **Performance** : expensive `setUp()` and constructors will have a measurable impact
> * **Memory Usage**: Each instance holds its own state in memory until the end of the testsuite run
> * **Test Isolation**: Ensures no state leakage between tests (the main benefit)
>
> Since each test method creates a new instance, expensive operations compound quickly. Watch out for:
>
> * repeated kernel booting
> * database connections
> * fixture loading (especially when Doctrine ORM Entity hydration is involved)
> * external API calls
>
> You can use singletons for stateless services, transactions for database cleanup, and mocks for external dependencies.
> The example below uses `AppSingleton::get()` to share a stateless application instance across the entire testsuite.

### Smoke Tests

> **Note**: this is the pragmatic approach.

For controllers and commands, no need to mock internal dependencies
or asserting on complex business logic.

Just craft the input, pass it to application, and verify the status code.

This tests the entire request-response cycle:
routing, middleware, validation, business logic, serialization... Everything.

Here's an integration test for a `POST /v1/events` endpoint controller:

```php
<?php

declare(strict_types=1);

namespace App\Tests\Integration\Controller\Event;

use App\Controller\Event\CreateController;
use App\Tests\AppSingleton;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Medium;
use PHPUnit\Framework\TestCase;
use Symfony\Component\HttpFoundation\Request;

#[CoversClass(CreateController::class)]
#[Medium]
final class CreateControllerTest extends TestCase
{
    public function test_it_creates_new_one(): void
    {
        $appKernel = AppSingleton::get()->appKernel();

        $headers = [
            'CONTENT_TYPE' => 'application/json',
        ];
        $request = Request::create('/v1/events', 'POST', [], [], [], $headers, (string) json_encode([
            'title' => 'Daily stand up',
            'start' => (new \DateTimeImmutable('now'))->format('Y-m-d\TH:i:s'),
            'end' => (new \DateTimeImmutable('now + 1 second'))->format('Y-m-d\TH:i:s'),
        ]));

        $response = $appKernel->handle($request);
        $appKernel->terminate($request, $response);

        $this->assertSame(201, $response->getStatusCode(), (string) $response->getContent());
    }

    public function test_it_cannot_create_new_one_without_required_fields(): void
    {
        $appKernel = AppSingleton::get()->appKernel();

        $headers = [
            'CONTENT_TYPE' => 'application/json',
        ];
        $request = Request::create('/v1/events', 'POST', [], [], [], $headers, (string) json_encode([
            'start' => '2025-07-09T09:00:00+00:00',
            'end' => '2025-07-09T09:15:00+00:00',
        ]));

        $response = $appKernel->handle($request);
        $appKernel->terminate($request, $response);

        $this->assertSame(422, $response->getStatusCode(), (string) $response->getContent());
    }
}
```

And here's an integration test for a `./bin/console events:list` CLI command:

```php
<?php

declare(strict_types=1);

namespace App\Tests\Integration\Command\Event;

use App\Command\Event\ListCommand;
use App\Tests\AppSingleton;
use PHPUnit\Framework\Attributes\CoversClass;
use PHPUnit\Framework\Attributes\Medium;
use PHPUnit\Framework\TestCase;
use Symfony\Component\Console\Command\Command;

#[CoversClass(ListCommand::class)]
#[Medium]
final class ListCommandTest extends TestCase
{
    public function test_it_lists_existing_ones(): void
    {
        $applicationTester = AppSingleton::get()->applicationTester();

        $input = [
            ListCommand::NAME,
        ];

        $statusCode = $applicationTester->run($input);

        $this->assertSame(Command::SUCCESS, $statusCode, $applicationTester->getDisplay());
    }
}
```

## Useful CLI options

```console
phpunit

  # Configuration:
  --generate-configuration             Generate configuration file with suggested settings
  --migrate-configuration              Migrate configuration file to current format

  # Selection:
  --list-groups                        List available test groups
  --group small                        Only run tests from the specified group(s)
  --exclude-group small                Exclude tests from the specified group(s)

  --list-tests                         List available tests
  --covers 'CheckArray'                Only run tests that intend to cover <name>
  --filter 'CheckArrayTest'            Filter which tests to run (test class, or test method)
  --filter 'test_it_accepts_valid_array'

  ## Useful for running testsuites individually, in the CI
  --list-testsuites                    List available testsuites
  --testsuite unit                     Only run tests from the specified testsuite(s)
  --exclude-testsuite unit             Exclude tests from the specified testsuite(s)

  # Execution
  --stop-on-failure                    Stop after first failure
  --order-by <order>                   Run tests in order: default|defects|depends|duration|no-depends|random|reverse|size

  # Reporting
  --no-progress                        Disable output of test execution progress (the dots)
  --testdox                            Replace default result output with TestDox format
```

> **Order By options**:
>
> * `default`: tests run in the order they're discovered
>   (filesystem order, typically alphabetical)
> * `defects`: previously failed/errored tests run first
>   (requires `--cache-result` to remember past failures)
> * `depends`: tests with dependencies run after their dependencies, non-dependent tests run first
> * `duration`: fastest tests run first, slowest tests run last
>   (requires `--cache-result` to remember execution times)
> * `no-depends`: ignores test dependencies and runs tests in discovery order
> * `random`: tests run in random order
>   (use `--random-order-seed <N>` for reproducible randomness)
> * `reverse`: tests run in reverse discovery order
> * `size`: tests run by size: `#[Small]`, then `#[Medium]`, after `#[Large]`, and finally unsized tests
>
> _Worth noting_: > * Combining options: `--order-by=depends,defects`

### Configuration

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- https://phpunit.readthedocs.io/en/latest/configuration.html -->
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="tests/bootstrap.php"

         cacheDirectory=".phpunit.cache"
         executionOrder="depends,defects"
         requireCoverageMetadata="true"
         beStrictAboutCoverageMetadata="true"
         beStrictAboutOutputDuringTests="true"
         displayDetailsOnPhpunitDeprecations="true"
         failOnPhpunitDeprecation="true"
         failOnRisky="true"
         failOnWarning="true"

         shortenArraysForExportThreshold="10"
         colors="true"
>
    <php>
        <!-- Useful for CI environments -->
        <ini name="display_errors" value="1" />
        <ini name="error_reporting" value="-1" />

        <!-- Useful for Symfony -->
        <env name="KERNEL_CLASS" value="App\Kernel" />
        <env name="APP_ENV" value="test" force="true" />
        <env name="APP_DEBUG" value="0" force="true" />
        <env name="SHELL_VERBOSITY" value="-1" />
    </php>

    <testsuites>
        <testsuite name="unit">
            <directory>tests/Unit</directory>
        </testsuite>
        <testsuite name="integration">
            <directory>tests/Integration</directory>
        </testsuite>
    </testsuites>

    <source
        ignoreIndirectDeprecations="true"
        restrictNotices="true"
        restrictWarnings="true"
    >
        <include>
            <directory>src</directory>
        </include>
    </source>
</phpunit>
```

> **Notes**:
>
> * `bootstrap` defaults to `vendor/autoload.php`
> * `shortenArraysForExportThreshold` defaults to `0` from v11.3 and `10` from v12
> * `colors` defaults to `false`, for automated/scripted environment compatibility
