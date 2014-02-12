---
layout: post
title: Tests: Introduction
tags:
    - practices
    - Tests series
---

This article is part of a series on Tests in general and on how to practice
them:

1. {{ link('posts/2014-02-05-tests-introduction.md', 'Introduction') }}
2. {{ link('posts/2014-02-12-tests-tools-overview.md', 'Tools overview') }}

This introduction can be read by anyone (no special level required) and it
targets those who've never heard about tests, or those you've never really
practice them. Here's what we'll cover:

1. [what is a test](#what-is-a-test)
2. [which kinds of tests are around there](#what-are-the-different-kinds-of-tests)
3. [how to do an isolated test](#how-to-do-an-isolated-test)

[TL;DR: jump to the conclusion](#conclusion).

## What is a test?

A test is a way to check if part of the system is working. Let's say you just
wrote the `strlen` function: it takes a string as argument and returns its
length. To make sure it works correctly, you might have created a script file
which looked like this:

    <?php

    echo strlen('We'); // Should print 2
    echo strlen('are'); // Sould print 3
    echo strlen('the knights'); // Should print 11
    echo strlen('who say "Ni"!'); // Should print 13

This script (which you might have thrown away once satisfied with the printed
result) is a test. It makes sure your function works correctly by providing it
with different inputs and comparing its output with the expected one.

This test is not really efficient, but it does the work. Let's see how to
improve it in the following sections.

## What are the different kinds of tests

Tests can be grouped under 3 categories:

1. random manual tests
2. scenarized manual tests
3. automated tests

### Random manual tests

The first one is when you use your software to see if it works correctly. This
is the worst kind of test because systems can be so complex that some part will
enventually be forgoten, and therefore not checked.

Incidentally, this is what happens everyday when users use your product, except
you're not sure if they'll report the bugs they see (and for each bug discovery
you can potentially lose them).

Why do I mention it, if it's so bad? Because it's still usefull to discover bugs
on parts which haven't been correctly covered by the other kinds of tests.
Actually this is the kind of tests which are done during beta-tests: you get a
restricted set of (volunteer) users to use your product and see if everything
is fine.

### Scenarized manual tests

Let's take a scientific approach to the first kind of tests by writing test
plans which describe use cases with their expected outcome.

Everytime someone tests the system, they follow the scenario given to them.
This is an improvement of the previous approach as there's less risk of
forgoting a step which is written.

Those tests are generally followed (more or less rigorously) during
**acceptance testing** at the end of developments by the customer or product
owner or even better by Quality Assurance (QA).

### Automated tests

The problem with the two previous categories is that they require humans, and
*to err is human*. The software industry was partly created to automate
repititive tasks, so how about we automate those tests?

The simplest way of automating test is to use assertions:

    <?php

    $input = 'We are no longer the knights who say "Ni"!';
    $expectedOutput = 42;

    $output = strlen($input);

    echo ($expectedOutput === $output ? 'Test pass' : 'Test fails');

If you keep this script, you can run it regurarly, which means the risk of
forgoting a step is almost near zero! I say almost because the test doesn't
magically cover every use case: human still have to write them, which lets a
small room for errors to happen, but this is the best we can do.

As you can see, automated tests are constructed very simply:

1. define the input and the expected output
2. execute the part of the system which needs to be tested
3. compare its output with the expected one

## Further kinds of tests

We've seen the 3 big categories of tests. But that's not quite it: whether it's
automated or not, your tests can target many levels/layers in your application:

* View layer:
    + User Interface (UI) tests: HTML and DOM
* Application layer:
    + functional tests: controllers, HTTP status code, command exit status
* Domain layer (the code which solves business needs):
    + behavior tests: interaction between classes
    + unit tests: services, interfaces, functions

**Note**: this classification has been taken from
[Jean François Lépine's slides](https://speakerdeck.com/halleck/symfony2-un-framework-oriente-domain-driven-design?slide=20)

Each of those tests can be executed manually, or can be automated.

There's so many types of tests out there, and so little of us to write them!
Depending on your team, competences, project and planning, you won't be able to
write every possible tests.

I'm afraid you'll have somehow to chose which kind of test is more suitable for
you project. As a matter of fact, testing everything isn't wise:

    <?php

    class User
    {
        private $name;

        public function __construct($name)
        {
            $this->name = $name;
        }

        public function getName()
        {
            return $this->name;
        }
    }

    // Is this test really usefull? I think not!
    $input = 'Johann Gambolputty de von Ausfern -schplenden -schlitter -crasscrenbon -fried -digger -dangle -dungle -burstein -von -knacker -thrasher -apple -banger -horowitz -ticolensic -grander -knotty -spelltinkle -grandlich -grumblemeyer -spelterwasser -kürstlich -himbleeisen -bahnwagen -gutenabend -bitte -eine -nürnburger -bratwustle -gerspurten -mit -zweimache -luber -hundsfut -gumberaber -shönendanker -kalbsfleisch -mittler -raucher von Hautkopft of Ulm.';
    $expectedOutput = $input;

    $user = new User($input);
    $output = $user->getName();

    echo ($expectedOutput === $output ? 'Test pass' : 'Test fails');

In the upper code sample, we're testing if the getter returns a value which
haven't been modified. Sure you could introduce a typo while sketching the
class, but once you've manually tested it a first time there's no need to check
regularly if it still works in the future.

You may not be able to write every possible tests, but still writing some tests
will save you time in the future as it will prevent regression: the software
industry is an industry of changing requirements, which means your code will
eventually be changed, adapted and sometime completly re-written.

Tests will allow you to change the code lighthearted, because if your change
breaks something, you'll know it simply by running your tests.

## How to do an isolated test?

Chances are your system is composed of parts which interact with each other:
your functions call other functions, your classes depend on other classes and
use external functions, etc.

What if the part of the system you want to test interracts with a database, the
filesystem and also use a randomizer? Yep that's right, a randomizer: how can
you even write the expected output if it's supposed to be unpredictable?

The solution is quite simple: you should isolate the part you want to test.
In order to do so, you should use **test doubles** which is the practice of
replacing the dependencies of this part with objects which will behave the way
you tell them to.

There's many kinds of test doubles, fortunately [Martin Fowler has summed it up
for you](http://martinfowler.com/articles/mocksArentStubs.html) as follow:

> * Dummy objects are passed around but never actually used.
>   Usually they are just used to fill parameter lists.
>
> * Fake objects actually have working implementations, but usually take some
>   shortcut which makes them not suitable for production (an in memory
>   database is a good example).
>
> * Stubs provide canned answers to calls made during the test, usually not
>   responding at all to anything outside what's programmed in for the test.
>   Stubs may also record information about calls, such as an email gateway
>   stub that remembers the messages it 'sent', or maybe only how many messages
>   it 'sent'.
>
> * Mocks are what we are talking about here: objects pre-programmed with
>   expectations which form a specification of the calls they are expected to
>   receive.

In practice you'll use stubs to specify the return value of the dependency, and
you'll use mocks to check if the dependency's method has been called. The best
way to create stubs and mocks is to write a class which inherits the targeted
dependency, and overwrites its public methods.

**Note**: the part you want to test is called the System Under Test (SUT), and
its dependencies are called collaborators.

### Dependency Injection's back!

Did you notice I've used the word dependency in this section? That's because in
order to make a class *testable*, you need it to be as decoupled as possible
from its dependencies.

You won't be able to easily replace dependencies which are created by the part
you want to test. The simplest way is to inject them (pass them as arguments)
to your class, allowing you to decide what should be injected: the real
dependency, or one of its stub (or mock).

This is why Dependency Injection is a big deal. If you don't clearly know what
is this design pattern about, I advise you to
{{ link('posts/2014-01-22-ioc-di-and-service-locator.md', 'read this article') }}

## Conclusion

Tests allow you to make sure parts of your system work as expected, and they can
be automated so you can run them regurarly in order to detect any regressions.

There's a lot of layers which can be tested and you might have to choose what is
best for you (the wrong answer being "no tests for me, thank you very much").

Dependency Injection is the right way to go, as it will allow you to use test
doubles to isolate the part you want to check.

This article had much theory in it, so the next one will be more practical with
code samples, case studies and tools which will allow you to test your
applications: {{ link('posts/2014-02-12-tests-tools-overview.md', 'Tools overview') }}.

### A word about test coverage

I might not have stressed this out enough: **tests won't magically prevent your
system from failing**. This is all because your test will only cover the part
you targeted, for the use case you could think of at the time.

So, how to make sure your tests are enough? At first glance, test coverage might
be a solution: it's a tool which will mark any line of code executed while the
test is run and which will produce a report telling you which parts haven't been
visited.

The biggest flaw of such a tool is that just because you called a line doesn't
mean you tested it. The other important weakness is that not every code needs
to be tested (for example getters of values which are not altered): the report
will tell you a percentage of code covered, but it won't be able to tell you
if the covered part is the essential one.

In order to know if your tests cover the critical parts, mutation testing have
been invented: a tool will alter random parts of your code and run the tests. If
your tests fail, then they play well their role of guarding your application
against regressions.

However this is not very precise, they're slow and they can't know what are the
critical parts of your system...

I guess the best you can do is TDD, which we'll see in a future article ;) .

If you're interested in this subject, I advise you to read
[Jason Gorman's article on code coverage](http://codemanship.co.uk/parlezuml/blog/?postid=1202).
