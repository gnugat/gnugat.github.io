---
layout: post
title: Behat: a quick tour
tags:
    - tests series
---

[TL;DR: jump to the conclusion](#conclusion).

This article is part of a series on Tests in general and on how to practice
them:

1. [Introduction](/2014/02/05/tests-introduction.html)
2. [Tools overview](/2014/02/12/tests-tools-overview.html)
3. [Test Driven Development](/2014/02/19/test-driven-development.html)
4. [TDD: just do it!](/2014/02/26/tdd-just-do-it.html)
5. [spec BDD](/2014/03/05/spec-bdd.html)
6. [phpspec: a quick tour](/2014/03/11/phpspec-quick-tour.html)
7. [Behavior Driven Development: story BDD](/2014/03/19/behavior-driven-development-story-bdd.html)
8. [Behat: a quick tour](/2014/03/26/behat-quick-tour.html)
9. [Conclusion](/2014/04/02/tests-cheat-sheet.html)

[Story Behavior Driven Development](/2014/03/19/behavior-driven-development-story-bdd) (BDD)
is all about making user story's acceptance criteria executable.
In this article we'll oversee [Behat](http://behat.org/) a PHP framework which
enables you to do so.

## Introduction

In a nutshel Behat reads your user stories and links each steps in acceptance
criteria to a function. The execution of those functions will then ascertain if
the acceptance criteria succeeded.

To be able to read the user story, Behat needs you to write it in a specific
format.

## User story

By default, your user stories are located as follow: `/features/*.feature`.
They're written using the [Gherkin language](http://docs.behat.org/guides/1.gherkin.html),
which looks like this:

    Feature: <user story title>
        In order to <business value to attain>
        As a/an <actor>
        I need to <requirements to meet>

        Scenario: <acceptance criteria title>
            Given <precondition>
            When <event>
            Then <outcome>

The first lines will be printed while executing the acceptance criteria. The
`Scenario` keyword starts a new criteria. The `Given`, `When` and `Then`
keywords will trigger a search for a related test method. Those are called
steps.

Your criteria will most likely have more than three lines. You can use `And` and
`But` keywords to link the steps:

    Feature: <user story title>
        In order to <business value to attain>
        As a/an <actor>
        I need to <requirements to meet>

        Scenario: <acceptance criteria title>
            Given <precondition>
            And <another precondition>
            When <event>
            But <another event>
            Then <outcome>
            And <another outcom>
            But <yet another outcome>

*Note*: to be fair, `Given`, `When`, `Then`, `But` and `And` keywords aren't
different to Behat: the choice is there for you, in order to make your
acceptance criteria more readable.

## Context

The test methods should be placed in a context: `/features/bootstrap/FeatureContext.php`.
It looks like this:

    <?php

    use Behat\Behat\Context\BehatContext;

    class FeatureContext extends BehatContext
    {
        /**
         * @Given /^a sentence from an acceptance criteria$/
         */
        public function aTestMethod()
        {
            // Your test code.
        }
    }

When Behat reads your user stories, for each step it will look in your context
and check the test method's annotations (comments starting by `@Given`, `@When`
or `@Then`) to see if it matches.

*Note*: again, `@Given`, `@When` and `@Then` don't really matter. If you write
`Given I am an imp` in your user story, and then write a test method with the
annotation `@When /^I am an imp$/`, it will match!

As you can see, a regexp is used for the matching, but since the version 3.0
(still in release candidate at the time I write this article) you can use plain
text with placeholders:

    /**
     * @Given I am an/a :type
     */
    public function setType($type)
    {
        // Your test code.
    }

This has been borrowed from [Turnip](https://github.com/jnicklas/turnip).

*Note*: your test method name can be anything, it doesn't have to match the step
sentence.

## The definition of success

When a test method is executed, it can have the following state:

* not found: you need to create it
* pending: the test method exists, but isn't implemented
* failing: the method throws an exception or raises an error
* succeeds: the default

To set the pending state, write the following in your method:

    throw new \Behat\Behat\Tester\Exception\Pending();

As you can see, if you write the test method, but put nothing in it, then the
test will succeeds. The responsibility to make the success state match business
expectations is yours.

Behat eats its own dog food: its tests are written with itself! Which means you
can have a look at them to inspire yourself. You'll see something that isn't
written in the documentation: you can use
[PHPUnit's assertion methods](http://phpunit.de/manual/current/en/writing-tests-for-phpunit.html#writing-tests-for-phpunit.assertions)
to make your test pass or fail.

## An automated flow

Remember how [phpspec](/2014/03/11/phpspec-quick-tour)
generates your code based on your specifications? Well it's the same thing with
Behat.

First Bootstrap your context:

    behat --init

Write a `/features/<user-story>.feature` file.

Next run the tests. For the pending steps, behat will propose you a template
code which can be copy/pasted in your test methods:

    behat

Then complete your test methods.

And finally run your tests:

    behat

The tests should all fail. Which means now you can start writting the code to
make it pass: it's Behavior **Driven** Development, remember? ;)

## Misconceptions

A lot of people hate Behat because it's slow and it needs [Selenium](http://docs.seleniumhq.org/)
to work, which isn't easy to install (if a novice can't install it, then it's
not easy).
Oh, and they hate it because the tests written with it aren't maintenable.

Guess what? They're wrong. They're probably using the
[mink extension](http://mink.behat.org/), which enables you to write things like:

    Feature: User registration
        In order to gain access to the website
        As a user
        I need to register

        Scenario: Giving account details
            Given I fill the field "#username" with "John"
            And  I fill the field "#password" with "Doe"
            When I submit the form "ul.form-block > li:last > #submit"
            And I wait until the page is fully loaded
            Then I should see "You've registered successfully"

The thing is, you're not describing the business value in this acceptance
criteria. You're describing User Interface (UI) interractions. And it's
completly different!

So here's my rule of thumb: don't use mink nor selenium.
In [Silex, an implementation detail](https://speakerdeck.com/igorw/silex-an-implementation-detail),
the advice given is: imagine you need to add a CLI which shares the same
functionnalities than the web interface. It would be a shame to have to re-write
all your acceptance tests, wouldn't it?

## Conclusion

Behat enables you to make your acceptance criteria executable, and automates the
process. Awsome!

If you're using Selenium, or the mink extension, then you're doing it wrong:
don't test the UI, test the business value.

Here's my workflow advice:

1. write only one criteria
2. implement only one step
3. write the specification of one class used in the step implementation (using [phpspec](/2014/03/11/phpspec-quick-tour))
4. write the code matching the specification
5. go back to 3. until any code from the step implementation is written
6. go back to 2. until any step is written
7. go back to 1. until the user story is completely written

I hope you enjoyed this article, be sure to
[tweet me what you think about it](https://twitter.com/epiloic) ;) .

Story BDD and Behat have a steep learning curve, which makes them hard to
practice in the beginning (but totally worth it). To help you get your own way,
here's a list of references:

* [Behat documentation](http://docs.behat.org/)
* [Behat sources](https://github.com/Behat/Behat)
* [Behat version 3.0 announcement (slides)](http://www.slideshare.net/everzet/behat-30-meetup-march)
* [Behat version 3.0 announcement (video)](https://www.youtube.com/watch?v=xOgyKTmgYI8)

And of course have a look at the references [from my BDD article](/2014/03/19/behavior-driven-development-story-bdd).
