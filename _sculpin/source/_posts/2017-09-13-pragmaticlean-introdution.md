---
layout: post
title: PragmatiClean - introduction
tags:
    - pragmaticlean
    - symfony
---

There are only 10 types of debates in the software world,
[Clean Code](https://www.amazon.co.uk/Clean-Code-Handbook-Software-Craftsmanship/dp/0132350882)
v [Pragmatic Code](https://www.amazon.co.uk/Pragmatic-Programmer-Andrew-Hunt/dp/020161622X)
and those which don't matter.

In this new series we'll see how to stop wasting time arguing which one is best
and start using both instead.

## What's Clean Code?

Clean Code is about writing for the long term, usually by structuring it with
the help of Design Patterns and Principles.

The assumption is that everything will change given enough time, be it code or
people, and so things should be easy to understand and easy to change.

The opposite of Clean Code would be "taking shortcuts" to get the job done,
which causes maintenance to become harder and harder over time.

## What's Pragmatic Code?

Pragmatic Code is about writing for the short term, usually by selecting the
most simple and quickest way to achieve a task.

The assumption is that things need to be done as quickly as possible, and the
simplest solution is always the best.

The opposite of Pragmatic Code would be "over engineering" for the sake of it,
which wastes time, makes the code harder to maintain and also makes it less
efficient.

## What's PragmatiClean Code?

As we can see both school seem diametrically opposed, hence the heated debates.

But both seem to be making good points, so why not try to adopt both?

Pragmatic Programmers don't resent structured code or even Design Patterns and
Principles, what they find aberrant is the over use of them and their misuse.

Clean Coders don't dislike simple solutions and they don't like spending more
time on a task than necessary, what they find abnormal is code that has become
too hard to maintain because it grew more and more out of control over time.

So let's [develop one universal school of thought that covers both](https://xkcd.com/927/):
PragmatiClean. We'll do so by going over the following Design Patterns/Principles
and give them a twist:

* Command Bus, by dropping the bus
* Adapter to decouple from third part libraries, but only the ones that matter
* Test Driven Development, by not testing everything
* Command/Query Responsibility Segregation, by making it synchronous
* Event Sourcing, by skipping the sourcing

And to make all this learning applicable, we'll show some Symfony code!
