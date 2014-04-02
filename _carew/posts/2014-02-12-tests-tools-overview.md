---
layout: post
title: Tests: Tools overview
tags:
    - technical
    - Tests series
---

This article is part of a series on Tests in general and on how to practice
them:

1. {{ link('posts/2014-02-05-tests-introduction.md', 'Introduction') }}
2. {{ link('posts/2014-02-12-tests-tools-overview.md', 'Tools overview') }}
3. {{ link('posts/2014-02-19-test-driven-development.md', 'Test Driven Development') }}
4. {{ link('posts/2014-02-26-tdd-just-do-it.md', 'TDD: just do it!') }}
5. {{ link('posts/2014-03-05-spec-bdd.md', 'spec BDD') }}
6. {{ link('posts/2014-03-11-phpspec-quick-tour.md', 'phpspec: a quick tour') }}
7. {{ link('posts/2014-03-19-behavior-driven-development-story-bdd.md', 'Behavior Driven Development: story BDD') }}
8. {{ link('posts/2014-03-26-behat-quick-tour.md', 'Behat: a quick tour') }}
9. {{ link('posts/2014-04-02-tests-cheat-sheet.md', 'Conclusion') }}

This article can be read by any regular developer (no special level required),
we'll put some code on the principles we've previously seen and we'll have a
quick look on existing tools. Here's what we'll cover:

1. [test frameworks](#test-frameworks)
2. [PHPUnit](#phpunit)
3. [unit tests](#unit-tests) with test doubles (mocks and stubs)
4. [functional tests](#functional-tests)
5. [user interface tests](#user-interface-tests)

[TL;DR: jump to the conclusion](#conclusion).

## Test frameworks

In order to automate your tests (whether they're unitary, functionnal or anything
else), you'll need to use some tools. These would be libraries helping you
doing assertions, or libraries helping you creating test doubles without writing
any new classes, or even frameworks which group those libraries together.

Most of the test frameworks follow the
[**xUnit** convention, which have been (accidently?) created by Kent Beck](http://www.xprogramming.com/testfram.htm).
Those are composed of:

* a test runner which gather the **test suites**, execute their tests and then
  prints the result using a **test result formatter**
* a test case, a class which you extend to write your tests
* test fixtures to provide data as context for the tests
* test suites, a bunch of tests which share commonalities (in practice this would
  be the class which extends the test case and where you'll write your tests)
* test execution: you can execute a bunch of code before every test with a
  **setUp** method, and afterward in a **tearDown** function
* test result formatter taking responsibility for outputing how test failed,
  or if it should be written on the output or in a XML file
* assertions which check if the given expected value matches the given actual
  value

Those are, among a ton of others:

* [PHPUnit](http://phpunit.de/) in PHP
* [Atoum](https://github.com/atoum/) in PHP
* [jUnit](http://junit.org/) in Java
* [unittest](http://docs.python.org/2/library/unittest.html) in Python

You could aslo find Behavior Driven Development (BDD) style test frameworks:

* [Codeception](http://codeception.com/) in PHP
* [phpspec](http://www.phpspec.net/) alongside with [Behat](http://behat.org/)
  in PHP
* [jasmine](http://pivotal.github.io/jasmine/) in javascript
* [RSpec](http://rspec.info/) in ruby

I won't talk about these, as it will be the subject of a future article
(there's so much to say about them).

Full stack frameworks isn't the only thing around here to help you write tests,
there also are some libraries:

* [Mocha](http://visionmedia.github.io/mocha/), a base layer for tests,
  in javascript
* [Chai](http://chaijs.com/), an assertion library in javascript
* [Sinon.js](http://sinonjs.org/), a test double library in javascript
* [Mockery](https://github.com/padraic/mockery), a mock framework in PHP
* [Prophecy](https://github.com/phpspec/prophecy), another mock framework in PHP

Choose your weapon wisely!

## PHPUnit

I mainly code in PHP, and in this language PHPUnit is the most popular test
framework. It's been there for so long (version 1.0.0 released in July 2006)
that almost any libraries and frameworks are tested with it. So it'll be our tool
for the next examples.

You can install it using [Composer](https://getcomposer.org/):

    curl -sS https://getcomposer.org/installer | php # Download composer
    composer install "phpunit/phpunit:~3.7"
    php vendor/bin/phpunit -h

**Note**: if you don't know Composer, let's just say that it makes your life easier
by downloading for you the libraries you told him to (it takes care of selecting
the good versions and can update them to get bug fixes). It also autoloads your
classes so you don't have to require them.

Now that you have the latest stable version, you'll need to configure it:

    <?xml version="1.0" encoding="UTF-8"?>
    <!-- File: phpunit.xml -->
    <phpunit
        backupGlobals="false"
        colors="true"
        syntaxCheck="false"
        bootstrap="test/bootstrap.php"
    >
        <testsuites>
            <testsuite name="Fossil Test Suite">
                <directory suffix="Test.php">./test/</directory>
            </testsuite>
        </testsuites>
    </phpunit>

This configuration tells PHPUnit to look (recursively) in the `test` directory
for files ending in `Test.php`. Those will be your test suites.

You'll need a bootstrap file in order to use composer's autoloader:

    <?php

    $loader = require __DIR__.'/../vendor/autoload.php';
    $loader->add('Gnugat\\Fossil\\Test', __DIR__);

And voilà! You can now write your tests in `test`.

## Unit tests

The common understanding of unit test is a symmetry between classes and tests:
when you have a class with 2 methods, you need to have a test class for it
which will test these two methods.

It looks like this wasn't the real meaning of the term unit, which should have
meant making tests which can be run in any order without ruinning them, and as
many times as wanted. Fortunately a new kind of test was created to fix this
misunderstanding, so let's stick with the common one.

Imagine you have the following class, which creates a file if it doesn't already
exist:

    <?php
    // File: src/MarkdownFile/DocumentationWriter.php

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

**Note**: once again the code samples are taken from
[fossil](https://github.com/gnugat/fossil), have a look at
{{ link('posts/2014-01-15-bootstrap-markdown-files-of-your-FOSS-project.md', 'this article') }}
to discover what it is.

In order for it to be autoloaded, you'll need to edit your `composer.json` file:

    {
        "require": {
            "phpunit/phpunit": "~3.7"
        },
        "autoload": {
            "psr-4": {
                "Gnugat\\Fossil": "src/"
            }
        }
    }

To test it, we could run it and check if the file has been created with the
given content, but that would be testing Symfony2's `Filesystem` which
[happens to be already tested](https://github.com/symfony/symfony/blob/fe86efd3f256c5bda845cf23bf8a5400ae6a295e/src/Symfony/Component/Filesystem/Tests/FilesystemTest.php).

So what does our class adds to it? Well it calls `Filesystem` to check if the
file exists, and if not it calls again the `Filesystem` to create it. We could
check if those calls are made using stubs and mocks.

**Reminder**: stubs are a substitute of an object which forces it to return
a given value. When a System Under Test (SUT, the class you're testing) has
collaborators (classes used by the SUT, also called dependencies), we can stub
them so their behavior is completly controlled.

**Reminder**: mocks are a substitute of an object which checks if its methods
have been called. When a System Under Test (SUT, the class you're testing) has
collaborators (classes used by the SUT, also called dependencies), we can mock
them to monitor their use.

PHPUnit allows us to create stubs and mocks without having to write a class
which extends the colaborator and overwrites its methods:

    <?php
    // File: test/MarkdownFile/DocumentationWriterTest.php

    namespace Gnugat\Fossil\Test\MarkdownFile;

    use Gnugat\Fossil\MarkdownFile\DocumentationWriter;

    class DocumentationWriterTest extends \PHPUnit_Framework_TestCase
    {
        const FIXTURE_ABSOLUTE_PATHNAME = '/tmp/example.txt';
        const FIXTURE_CONTENT = "Hello world\n";

        public function setUp()
        {
            $this->filesystem = $this->getMock('Symfony\\Component\\Filesystem\\Filesystem');
            $this->documentationWriter = new DocumentationWriter($this->filesystem);
        }

        public function testWriteNewFile()
        {
            // Stub
            $this->filesystem->expects($this->any())
                ->method('exists')
                ->with(self::FIXTURE_ABSOLUTE_PATHNAME)
                ->will($this->returnValue(true))
            ;

            // Mock
            $this->filesystem->expects($this->once())
                ->method('dumpFile')
                ->with(
                    $this->equalTo(self::FIXTURE_ABSOLUTE_PATHNAME),
                    $this->equalTo(self::FIXTURE_CONTENT)
                )
            ;

            // Call
            $this->documentationWriter->write(
                self::FIXTURE_ABSOLUTE_PATHNAME,
                self::FIXTURE_CONTENT
            );
        }
    }

In the stub: for every call (`expects($this->any())`) of the method `exists`
with the parameter `self::FIXTURE_ABSOLUTE_PATHNAME`, force the colaborator to
return `true`.

In the mock: a unique call must be made (`expects($this->once())`) of the method
`dumpFile` with the two parameters `self::FIXTURE_ABSOLUTE_PATHNAME` and
`self::FIXTURE_CONTENT`.

You can run the test using `php vendor/bin/phpunit` and see that they pass. As
an exercise, write a second method in this test suite
`testDoesNotWriteExistingFile`, with a stub returning false and a mock checking
that `dumpFile` is never called ([hint](http://phpunit.de/manual/3.7/en/test-doubles.html#test-doubles.mock-objects.tables.matchers)).

I advise you to watch [extract till you drop](http://verraes.net/2013/09/extract-till-you-drop/),
a nice refactoring session by Mathias Verraes: in order to improve his code, he
writes tests which give him enough confidence to proceed. He uses PHPUnit with
assertions, mocks and stubs, so you can really see their use.

## Functional tests

Unit tests are used in order to make sure each unit of `code` works as expected.
But applications aren't just about code, they're also about interactions
between these units. This is what functional tests are for: they use the entry
point of the system and check the final status code.

To illustrate this, we'll still use PHPUnit: even though there's the word `unit`
in its name, this test framework allows us to write many types of tests.

The Symfony2 web framework is all about the HTTP protocol: it takes a HTTP
Request and returns a HTTP Response. It also provides a convenient client which
simulates HTTP Requests, allowing us to write easily functional tests:

    <?php
    // File: src/Acme/DemoBundle/Tests/Controller/DemoControllerTest.php

    namespace Acme\DemoBundle\Tests\Controller;

    use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;
    use Symfony\Component\HttpFoundation\Response;

    class DemoControllerTest extends WebTestCase
    {
        public function testIndex()
        {
            $client = static::createClient();

            $client->request('GET', '/demo/hello/Fabien');

            $this->assertSame(
                Response::HTTP_OK,
                $client->getResponse()->getStatusCode()
            );
        }
    }

The `assertSame` line is an assertion: it compares the expected value (first
argument) with the actual one (second one). PHPUnit provides many assertions:

* `assertSame` is equivalent to `===` (type and value comparison)
* `assertEquals` is equivalent to `==` (loose value comparison)
* `assertFileExists` checks if the given filename corresponds to an exisitng file
* [and many more](http://phpunit.de/manual/3.7/en/appendixes.assertions.html)

Different approaches exist with assertions, for example jasmine uses the
`expect` method to set the actual value, chained with a matcher like `toBe`
which takes the expected value:

    describe("A suite", function() {
      it("contains spec with an expectation", function() {
        var expectedValue = true;
        var actualValue = true;

        expect(actualValue).toBe(expectedValue);
      });
    });

In this case, assertions are splitted into expectations and matchers.

Back to our sheeps. Here's an example of functional test for a Symfony2 command:

    <?php
    // File: src/Acme/DemoBundle/Tests/Command/GreetCommandTest.php

    namespace Acme/DemoBundle/Tests/Command;

    use Symfony\Component\Console\Tester\CommandTester;
    use Symfony\Bundle\FrameworkBundle\Console\Application;
    use Symfony\Bundle\FrameworkBundle\Test\WebTestCase;
    use Acme\DemoBundle\Command\GreetCommand;

    class ListCommandTest extends WebTestCase
    {
        public function testExecute()
        {
            $kernel = $this->createKernel();
            $kernel->boot();

            $application = new Application($kernel);
            $application->add(new GreetCommand());

            $command = $application->find('demo:greet');
            $commandTester = new CommandTester($command);
            $commandTester->execute(
                array(
                    'name' => 'Fabien',
                    '--yell'  => true,
                )
            );

            $exitSuccess = 0;

            $this->assertSame($exitSuccess, $commandTester->getStatusCode());
        }
    }

Just like with a controller where we check the HTTP Response's status code, in
a command we check the exit status code.

## User Interfact tests

Up until now, we've been testing that the code worked and that interractions
between all those units go well. But what about the thing the user actually
sees and interacts with?

The User Interface (UI) turns out to be tricky to test, but not impossible. You
can click on buttons, or load pages, or run CLI tasks programmatically and you
can inspect the standard output or the HTTP Response's content.

The main problem with this is that you'll tie your tests to the UI, which
changes a lot.

We'll see briefly the tools available and then better explain the flaws of such
a technique.

### Selenium

[Selenium](http://docs.seleniumhq.org/) allows you to open a browser and
simulates interractions with the page. Technically it means having a Selenium
server running in the background, and using a webdriver library in your test to
send messages to it. In PHP, you can find those webdrivers:

* [One by Alexandre Salomé](https://github.com/alexandresalome/php-webdriver)
* [another one by Facebook](https://github.com/facebook/php-webdriver)

You can find code samples in the respective documentation of each library, for
example here's the doc describing [how to click on a button with Alexandre's one](https://github.com/alexandresalome/php-webdriver/blob/master/doc/elements.rst#element-api).

If you're curious, [here's how to use Selenium with another test framework](http://codeception.com/11-20-2013/webdriver-tests-with-codeception.html):
[Codeception](http://codeception.com/).

### CasperJs

You don't like the idea of running a server in order to run your tests? You
don't want a browser to be openned and you [find it too slow](http://stackoverflow.com/questions/2354590/why-is-selenium-rc-so-slow)?

Then you might want to try a **headless website testing** solution like
[CasperJs](http://casperjs.org/). It's headless because it won't open a
browser to make the tests.

Here's the [get started documentation](http://docs.casperjs.org/en/latest/quickstart.html),
so you can have a quick look on how to use it.

### Goutte

Simulating a browser is too much for you? Making a curl request and parsing its
response would be sufficient for your needs? Then have a look at the
[Goutte web scrapper](https://github.com/fabpot/goutte).

This one also allows you to click on links.

### Mink

> One Tool to rule them all, One Tool to find them,
> One Tool to bring them all and in the webness bind them

[Mink](http://mink.behat.org/) can use either Goutte or Selenium as a driver to
interract with the UI. It's goal is to provide a unified API.

### What's the point?

The thing in common with all these tools is that they rely on the HTML rendered
in the HTTP Response. In order to check if a message appears, you'll have to
crawl the page, find the `div` using its class or id in a CSS selector, or even
worse using its xpath.

When the page will change (and it will) your tests will be broken. There's some
best practices out there, mainly making your tests rely on ID's on one hand and
making your code and stylesheets rely on classes on the other hand, but in the
end it still is a risky business.

Well that's my opinion and this section might be more a rant than an objective
description. To counter balance this, here's a nice article on
[writing reliable locators for Selenium and WebDriver tests](http://blog.mozilla.org/webqa/2013/09/26/writing-reliable-locators-for-selenium-and-webdriver-tests/).

## Conclusion

In PHP, [PHPUnit](http://phpunit.de/) is the most popular test framework and it
allows you to write unit, functional and every other kinds of tests.

Unit tests allow you to make sure each functions return the expected output when
given a set of fixtures, and functional tests are used to check the status code
(think HTTP response, or a command's exit status).

Stubs are used to force a colaborator's method to return a wanted value, and
mocks are used to check if a colaborator's method have been called.

[Selenium](http://docs.seleniumhq.org/) is the most popular tool to test the
User Interface, which is done by interracting with the HTML rendered in the
HTML's reponse.

I hope this article helped you to see how each kinds of tests are written. The
next one will be on Test Driven Development, a practice where tests are written
before the code: {{ link('posts/2014-02-19-test-driven-development.md', 'TDD') }}.


If there's something bothering you in this post, or if you have a question, or
if you want to give me your opinion, be sure to do so on
[Twitter](https://twitter.com/epiloic) ;) .
