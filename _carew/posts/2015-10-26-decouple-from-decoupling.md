---
layout: post
title: Decouple from Decoupling
tags:
    - decoupling
---

In the last two articles, we've seen how to decouple our application:

* {{ link('posts/2015-09-30-decouple-from-frameworks.md', 'from frameworks, using the Command Bus pattern') }}
* {{ link('posts/2015-10-12-decouple-from-libraries.md', 'from libraries, using the Inversion of Control principle') }}

Decoupling can be considered as a "Best Practice" as it is a good protection
against external changes, but it doesn't mean that it should always be applied
everywhere.

This article is about mitigating the usage of this tool.

## Clean Code

Decoupling is an important part of clean code, as it can allow a better readability.

For example instead of having a controller full of logic, we just have a Command
class initialized with the input parameters that matter and a class name that describe
the expected behavior. Inside the Command Handler, instead of having implementation
details we have a sequence of service calls that decribe even further the behavior.

Clean code is all about making the application easier to maintain so in theory
this should be applied everywhere, but like every rules it can be abused and its
usefulness depends on the type of the project.

It might seem strange but some projects don't need to be maintained, for example
Proof of Concepts are usually thrown away once the experience they were designed
for are done, so it doesn't make sense to take the time to make them perfect.

Some industry are also commissioned to bootstrap a project as fast as possible
and are expected to pass over the project without any maintainance plan: usually
the ones that promise the earlier delivery for the lowest price are selected.
Again it doesn't make sense to take the time to create the most beautiful code
if that's not what's been asked and paid for.

## Pragmatism

Trying to use the right tool for the right job is an important part of being
pragmatic.

We've seen that some projects don't necessarly need decoupling as we don't expect
to maintain them. But sometimes a project might need decoupling in some parts
of it and not in other parts.

As the saying goes, "Fool me once, shame on you, fool me twice, shame on me":
since we can't know in advance which parts are going to change we might decide
to couple things first. When an issue occurs due to the coupling, we can refactor
to avoid further issues.

Last but not least, we can't always decouple from everything: for example the
programming language used can also release backward incompatible changes, or we
might want to switch to an entirely different one. Is it worth decouling from the
language?

## Conclusion

Decoupling is a great tool that should be used when needed but the decision of
when to use it depends on the context (project, team, industry, etc).

The rule of thumb number one is: don't follow blindly rule of thumbs.
