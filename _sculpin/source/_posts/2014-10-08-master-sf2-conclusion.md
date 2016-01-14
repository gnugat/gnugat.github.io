---
layout: post
title: Master Symfony2 - Conclusion
tags:
    - Symfony
    - Master Symfony2 series
---

This is the conclusion of the series on mastering the
[Symfony2](http://symfony.com/) framework. Have a look at the five articles:

* [1: Bootstraping](/2014/08/05/master-sf2-part-1-bootstraping.html)
* [2: TDD](/2014/08/13/master-sf2-part-2-tdd.html)
* [3: Services](/2014/08/22/master-sf2-part-3-services.html)
* [4: Doctrine](/2014/08/27/master-sf2-part-4-doctrine.htm)
* [5: Events](/2014/09/03/master-sf2-part-5-events.html)
* [6: Annotations](/2014/09/10/master-sf2-part-6-annotations.html)

It quickly sums up what we've seen and provides some directions to the next
steps, for those interrested in learning more (there's always more!).

## Summary

In these 6 articles, we've learned how to master Symfony2 through:

1. the usage of distributions to bootstrap our projects
2. the writing of simple functional tests (we used TDD/PHPUnit but any methodology/Framework can be used)
3. the creation of services and entities (where our business related code actually lies)
4. the usage of a third party library (Doctrine)
5. the extension of the framework via events (change the Request and Response at will)
6. the configuration via annotations, allowing to reduce the distance with the code

As a bonus, we've also seen:

* the Repository Design Pattern (retrieve data and format it before using it)
* the Symfony Console Component, which can be used as a standalone library

## Going further

There's still a deal lot more to learn, but with this series we've hopefully
seen the strict minimum to create any day to day application with deep knowledge
on how to extend the framework and where to put our code.

We've seen Symfony as a full stack framework: it deals with the HTTP protocol
for you. But the truth is that Symfony is a collection of third party libraries
before anything else. Here's a short selection of its available components:

* Validation: define constraints and check if the given variable complies to them
* Form: define fields, generate the HTML form and populate variables from the request
* Yaml: parse a yaml file
* Security: check the identity users and their permissions

Do you want to go further? Then have a look a these fabulous resources:

* [The documentation](http://symfony.com/doc/current/index.html)
* [Raul Fraile](https://twitter.com/raulfraile) overview articles on the:
    * [HttpFoundation Component](http://blog.servergrove.com/2013/09/23/symfony2-components-overview-httpfoundation/)
    * [HttpKernel Component](http://blog.servergrove.com/2013/09/30/symfony2-components-overview-httpkernel/)
    * [Routing Component](http://blog.servergrove.com/2013/10/08/symfony2-components-overview-routing/)
    * [EventDispather Component](http://blog.servergrove.com/2013/10/23/symfony2-components-overview-eventdispatcher/)
    * [Config Component](http://blog.servergrove.com/2014/02/21/symfony2-components-overview-config/)
    * [Validator Component](http://blog.servergrove.com/2014/03/03/symfony2-components-overview-validator/)
    * [Templating Component](http://blog.servergrove.com/2014/03/11/symfony2-components-overview-templating/)
    * [Translation Component](http://blog.servergrove.com/2014/03/18/symfony2-components-overview-translation/)
    * [Finder Component](http://blog.servergrove.com/2014/03/26/symfony2-components-overview-finder/)
    * [ExpressionLanguage Component](http://blog.servergrove.com/2014/04/07/symfony2-components-overview-expression-language/)
    * [Process Component](http://blog.servergrove.com/2014/04/16/symfony2-components-overview-process/)
* [Sebastien Armand](https://twitter.com/khepin)'s book [Extending Symfony Web Application Framework](http://www.amazon.co.uk/Extending-Symfony-Web-Application-Framework/dp/1783287195)
* [Matthias Noback](https://twitter.com/matthiasnoback)'s book [A Year with Symfony](http://www.amazon.co.uk/Year-With-Symfony-reusable-Symfony2/dp/9082120119)
* [Kris Walsmith](https://twitter.com/kriswallsmith) slides on the [Security Component](http://www.slideshare.net/kriswallsmith/love-and-loss-a-symfony-security-play)
