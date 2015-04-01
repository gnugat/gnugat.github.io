---
layout: post
title: Hello World, best practices - part 1.1.1
---

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
