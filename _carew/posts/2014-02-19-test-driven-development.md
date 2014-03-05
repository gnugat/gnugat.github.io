---
layout: post
title: Test Driven Development
tags:
    - practices
    - Tests series
---

This article is part of a series on Tests in general and on how to practice
them:

1. {{ link('posts/2014-02-05-tests-introduction.md', 'Introduction') }}
2. {{ link('posts/2014-02-12-tests-tools-overview.md', 'Tools overview') }}
3. {{ link('posts/2014-02-19-test-driven-development.md', 'Test Driven Development') }}
4. {{ link('posts/2014-02-26-tdd-just-do-it.md', 'TDD: just do it!') }}
5. {{ link('posts/2014-03-05-spec-bdd.md', 'spec BDD') }}

Unlike the two previous articles, this one requires some experience in testing.
While Test Driven Development (TDD) oficionados would tell you that on the
contrary this is the way to learn tests, I'd rather advise you to practice them
a little bit before hand, so you can fully grasp the interest of this principle.

In this article, we'll cover:

1. [an introduction to TDD](#introduction)
2. [why we should write tests first](#writing-the-test-first)
2. [how to write the code afterward](#writing-the-code-afterward)
3. [the importance of refactoring in the end](#refactoring-in-the-end)

[TL;DR: jump to the conclusion](#conclusion).

## Introduction

Test Driven Development (TDD) is a simple principle stating that we should:

1. write the test first
2. then write the code to make it pass
3. then refactor to clean the mess

It is also described as `red, green, refactor` to reflect the state of the tests
after being run in the end of each step. Well the last step should still be
green, but it wouldn't be self explicit if we said `red, green, green` wouldn't
it?

Kent Beck is considered to be the father of TDD, even though this practice must
have been used before, especially because he wrote the
['bible' Test Driven Development by Example](http://en.wikipedia.org/wiki/Test-Driven_Development_by_Example)
and also because he created the [eXtreme Programming methodology](http://en.wikipedia.org/wiki/Extreme_Programming)
(which integrates TDD into its practices).

TDD mostly applies to **unit** tests, but it could be used for any kind of test.

Each step has a purpose, which we'll discover.

## Writing the test first

So, why would we write the test before the code? The idea behind this is to
write a piece of software which will describe how to use the future code: when
writing the test, you're not bothered with implementation details and will
naturally create the API (the public methods).

The first consequence to this step is having a meaningful code coverage: no need
for tools to inspect which lines of code are executed when running the test in
order to make sure the code is properly tested
([those tools aren't effective anyway](http://codemanship.co.uk/parlezuml/blog/?postid=1202)).

The second one is better design: to write tests you need the code to be
decoupled. Writing tests firts forces you to make those decoupling decision
early. Decoupled code should be easier to re-use, read and maintain.

## Writing the code afterward

[As depicted by Ian Cooper](http://vimeo.com/68375232), this step is the
[duct tape progammer](http://www.joelonsoftware.com/items/2009/09/23.html)'s
one: in order to make the freshly written test pass, every sin should be
commited. Every design, clean code and best practice concerns should be put
aside so the test passes as quickly as possible.

Why so much fuss about all
[this ugly code](http://redotheweb.com/2013/06/04/you-should-write-ugly-code.html)?
The main reason is speed, to answer all criticism about how long tests take to
be written.

With this, the school of pragmatic programmers and scholar ones can finally be
reunited: as a matter of fact, while this step is all about the first "clan",
the refactoring step is all about the second one.

To illustrate the fact that sometimes the clean solution comes to mind once the
dirty has been written, here's a quote from [the Eloquent Javascript book](http://eloquentjavascript.net/chapter6.html):

> A student had been sitting motionless behind his computer for hours,
> frowning darkly. He was trying to write a beautiful solution to a
> difficult problem, but could not find the right approach. Fu-Tzu hit
> him on the back of his head and shouted '*Type something!*' The student
> started writing an ugly solution. After he had finished, he suddenly
> understood the beautiful solution.

## Refactoring in the end

Now that we have sin, we have created a technical debt. The third and last step
of TDD, refactoring, is all about managing this debt.

The rules here is to step back a little bit, consider how we can improve the
structure of the code to make it simpler, more readable and if there's anything
which can be extracted to be reused.

Once this consideration is done, then we can start moving the code at the only
condition that we don't break the tests. It also means that the tests shouldn't
be modified.

## Conclusion

Writing first the test allows a complete and meaningful code coverage, a more
decoupled code and a more natural API (public methods).

Then allowing every sins to write as quickly as possible the code to make the
test pass allows to speed up development through pragmatic decisions.

Finally refactoring without touching the tests allows to get rid of the
technical debt created in the previous step, depending on the estimated time
left for the task.

Unfortunately TDD comes with a quite steep learning curve, but hey! You don't
get something for nothing!

I hope you enjoyed this article, if you'd like to make any comments about it
(either good or bad), please feel free to do so [on Twitter](https://twitter.com/epiloic).

There's been many criticism about TDD, and most of those are simply
misconceptions. If you're part of the sceptics,
[check if your argument is listed in Jason Gorman's article](http://codemanship.co.uk/parlezuml/blog/?postid=1170).

The next article is about {{ link('posts/2014-02-26-tdd-just-do-it.md', 'actually doing TDD') }}.
