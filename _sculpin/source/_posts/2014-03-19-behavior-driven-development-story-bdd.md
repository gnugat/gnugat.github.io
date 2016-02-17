---
layout: post
title: Behavior Driven Development: story BDD
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

In this article, we'll talk about Behavior Driven Development (BDD), again.
There's no special skills required to read on, although some notions on
[tests](/2014/02/05/tests-introduction) and
[Test Driven Development](/2014/02/19/test-driven-development)
(TDD) would be a plus.

## From spec BDD to story BDD

So TDD has 3 simple rules:

1. write the test first
2. then write as quickly as possible the code to make it pass
3. finally refactor, without changing the tests (and still making them pass)

Like many TDD oficionados, [Dan North](http://dannorth.net/about/) felt that it
was missing some guidelines. To fix this, he created spec BDD, which adds the
following rules to TDD:

* test methods should be sentences (prefix them with `it_should` instead of `test`)
* tests should specify the behavior of the System Under Test (SUT)

One of his colleagues, Chris Matts, suggested to take BDD a step further: why
not making sure the business value was met? And that's how story BDD was
created.

## Acceptance tests

If you're working with agile methodologies, you should be familiar with user
stories. Those are simple cards which describe what to do in 3 lines:

    In order to attain a business value
    As an actor
    I need to meet some requirements

They've also some acceptance criteria, which follow approximately this template:

    Given a context
    When an event happens
    Then an outcome should occur

If the system fulfills the acceptance test, then it behaves correctly. By making
them executable, you can test the business behavior of your system! That's what
story BDD is all about.

Technically, this means parsing the acceptance tests and match each line with
a chunk of code. But don't worry about implementation details, we'll see them
in the next article.

## Misconceptions

Somehow, a surprising number of people started to think that BDD was all about
integration tests. For example in a web application, they would write:

    Given I am on "/home"
    When I click on "form#name_form input[name=submit]"
    And I wait until the page is fully loaded
    Then the "form#name_form input[name=first_name]" form field should contain "value"

What's wrong with it? Well:

* it's not human friendly (usage of xpath)
* it's completely coupled to your routing (usage of URL)
* it's entirely coupled to the web implementation (usage of web vocabulary)
* it's thoroughly coupled to the HTML integration (again, usage of xpath)
* it's fully coupled to the test tool (the waiting line is a hack)
* and mostly: it doesn't describe your business need

Here's a better approach:

    Given the opportunity to introduce myself
    When I give my name
    Then I should be greeted

Yep, that's the story BDD example of "Hello World", in case you didn't recognize
it ;) .

## Conclusion

If you make a user story's acceptance tests executable, then you're doing story
BDD. It helps you to make sure that your application meets your business needs.

Hopefully this article helped you a little. If you have any questions, rants or
praises, feel free to send them to me on [Twitter](https://twitter.com/epiloic).

Tests are hard. TDD is harder. BDD even more! Here's some good references to
help you on story BDD:

* [Introducing BDD, by Dan North](http://dannorth.net/introducing-bdd/)
* [Whose domain is it anyway? By Dan North](http://dannorth.net/2011/01/31/whose-domain-is-it-anyway/)
* [BDD slides by Liz Keogh](http://slideshare.net/lunivore/behavior-driven-development-11754474)
* [Are you really doing BDD? By Rob Conery](http://www.wekeroad.com/2013/08/28/how-behavioral-is-your-bdd/)
* [A.T. Fail! By Robert C. Martin](http://ht.ly/pfNW5)
