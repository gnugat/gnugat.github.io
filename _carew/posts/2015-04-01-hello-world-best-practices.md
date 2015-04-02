---
layout: post
title: Hello World, best practices - part 1.1.1
---

> **TL;DR**: Happy April Fool joke!

Hello World applications are often used to showcase framework capabilities, but
they usually fail to do so! This is because real world applications are never that simple.

In this series of articles, we will demonstrate how to build a real world Hello World application.

The first part will include the following standard technologies:

* AngularJs, to write the frontend
* [PostgreSQL](http://www.pomm-project.org/), for the database
* [Redis](http://labs.octivi.com/handling-1-billion-requests-a-week-with-symfony2/), a cache to reduce the high cost of querying the database
* IIS, as a web server
* [Logstash/Elasticsearch/Kibana](http://odolbeau.fr/blog/when-monolog-meet-elk.html), to monitor our application

In the second part, we'll take things to the advanced level:

* [FOSRestBundle](http://williamdurand.fr/2012/08/02/rest-apis-with-symfony2-the-right-way/) to create a HATEOS compliant API with Symfony
* [OAuth2](http://homakov.blogspot.fr/2013/03/oauth1-oauth2-oauth.html) to manage authentication
* [Oldsound/RabbitMQBundle](http://www.slideshare.net/cakper/2014-0821-symfony-uk-meetup-scaling-symfony2-apps-with-rabbit-mq?related=1), to keep our database and cache up to date
* [Laravel 5](https://twitter.com/m_lukaszewski/status/583143784394985473) to create a backend

In the conlusion we'll explore Docker, [Go Martini](http://www.slideshare.net/giorrrgio/import-golang-struct-microservice) (for faster GET endpoints),
[Python beautiful soup](http://www.crummy.com/software/BeautifulSoup/) (for web crawling) and NodeJs (to monitor our queues).

Of course we're going to use [full stack BDD](https://cukes.info/blog/2015/03/24/single-source-of-truth) all along!

Get ready for the best "Hello World" application you've ever seen!

## April Fool

This was my April Fool joke, no let's get serious and build  what I think is the best
Hello World application:

```php
<?php

echo 'Hello world';
```

Note that there's no symfony, no RabbitMQ, no nothing involved. That's because
a Hello World application doesn't require anything else, those tools were design
to solve issues that we don't have here.

If you're concerned about our Hello World application's performance, well you shouldn't be.
First of all, it's a Hello World application... As far as I'm concerned it prints
pretty much instantly this way.

Second of all, you shouldn't worry about performance when building an application.
This is something you should start worrying only when you have performance issues.
The best thing you could do, is build the application in a way that will allow you
to change it afterwards, if the need comes (and it usually will: requirements are changing by nature).

I hope you enjoyed it :) .
