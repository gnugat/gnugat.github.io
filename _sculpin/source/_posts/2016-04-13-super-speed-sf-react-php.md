---
layout: post
title: Super Speed Symfony - ReactPHP
tags:
    - symfony
---

> **TL;DR**: Run your application as a HTTP server to increase its performances.

HTTP frameworks, such as [Symfony](https://symfony.com/), allow us to build
applications that have the *potential* to achieve Super Speed.

A first way to make use of it is to run our application as a HTTP server.
In this article we'll take a Symfony application and demonstrate how to run it
as HTTP server using [ReactPHP](http://reactphp.org/).

## ReactPHP HTTP server

We're going to use ReactPHP's [HTTP component](https://github.com/reactphp/http):

```
composer require react/http:^0.5@dev
```

It helps us build HTTP servers:

```php
#!/usr/bin/env php
<?php
// bin/react.php

require __DIR__.'/../vendor/autoload.php';

$loop = React\EventLoop\Factory::create();
$socket = new React\Socket\Server($loop);
$http = new React\Http\Server($socket);

$callback = function ($request, $response) {
};

$http->on('request', $callback);
$socket->listen(1337);
$loop->run();
```

Starting from the last line, we have:

* `$loop->run()`: makes our HTTP server run inside an infinite loop (that's how long running processes work)
* `$socket->listen(1337)`: opens a socket by listening to a port (that's how servers work)
* `$http->on('request', $callback)`: for each HTTP Request received, executes the given callback

> **Note**: HTTP servers usually use the `80` port, but nothing prevents us from
> using a different one. Since there might be some HTTP servers already running
> on our computers (e.g. Apache or nginx), we'll use `1337` in our examples to
> avoid conflicts.

## Hello World example

The application logic has to be written in the callback. For example, here's how
to write a `Hello World!`:

```php
#!/usr/bin/env php
<?php
// bin/react.php

require __DIR__.'/../vendor/autoload.php';

$loop = React\EventLoop\Factory::create();
$socket = new React\Socket\Server($loop);
$http = new React\Http\Server($socket);

$callback = function ($request, $response) {
    $statusCode = 200;
    $headers = array(
        'Content-Type: text/plain'
    );
    $content = 'Hello World!';

    $response->writeHead($statusCode, $headers);
    $response->end($content);
};

$http->on('request', $callback);
$socket->listen(1337);
$loop->run();
```

If we run it now:

```
php bin/react.php
```

Then we can visit the page at [http://localhost:1337/](http://localhost:1337/),
and see a `Hello World!` message: it works!

## Symfony example

Let's recreate the same project, but using the Symfony Standard Edition:

```
composer create-project symfony/framework-standard-edition super-speed
cd super-speed
composer require react/http:^0.5@dev --ignore-platform-reqs
```

Since Symfony is a HTTP framework, wrapping it inside the callback is quite
natural. We only need to:

1. convert the ReactPHP request to a Symfony one
2. call a `HttpKernelInterface` implementation to get a Symfony response
3. convert the Symfony response to a ReactPHP one

As we can see, this is quite straightforward:

```php
#!/usr/bin/env php
<?php
// bin/react.php

require __DIR__.'/../app/autoload.php';

$kernel = new AppKernel('prod', false);
$callback = function ($request, $response) use ($kernel) {
    $method = $request->getMethod();
    $headers = $request->getHeaders();
    $query = $request->getQuery();
    $content = $request->getBody();
    $post = array();
    if (in_array(strtoupper($method), array('POST', 'PUT', 'DELETE', 'PATCH')) &&
        isset($headers['Content-Type']) && (0 === strpos($headers['Content-Type'], 'application/x-www-form-urlencoded'))
    ) {
        parse_str($content, $post);
    }
    $sfRequest = new Symfony\Component\HttpFoundation\Request(
        $query,
        $post,
        array(),
        array(), // To get the cookies, we'll need to parse the headers
        $request->getFiles(),
        array(), // Server is partially filled a few lines below
        $content
    );
    $sfRequest->setMethod($method);
    $sfRequest->headers->replace($headers);
    $sfRequest->server->set('REQUEST_URI', $request->getPath());
    if (isset($headers['Host'])) {
        $sfRequest->server->set('SERVER_NAME', explode(':', $headers['Host'])[0]);
    }
    $sfResponse = $kernel->handle($sfRequest);

    $response->writeHead(
        $sfResponse->getStatusCode(),
        $sfResponse->headers->all()
    );
    $response->end($sfResponse->getContent());
    $kernel->terminate($request, $response);
};

$loop = React\EventLoop\Factory::create();
$socket = new React\Socket\Server($loop);
$http = new React\Http\Server($socket);

$http->on('request', $callback);
$socket->listen(1337);
$loop->run();
```

> **Note**: Request conversion code from React to Symfony has been borrowed from
> [M6Web PhpProcessManagerBundle](https://github.com/M6Web/PhpProcessManagerBundle/blob/dcb7d971250ec504821dca040e6e2effbdb5adc5/Bridge/HttpKernel.php#L102).

And as easy as that, we can run it:

```
php bin/react.php
```

Finally we can visit the page at [http://localhost:1337/](http://localhost:1337/),
and see a helpful `Welcome` message: it works!

## Benchmarking and Profiling

It's now time to check if we've achieved our goal: did we improve performances?

### Regular version

In order to find out, we can first benchmark the regular Symfony application:

```
SYMFONY_ENV=prod SYMFONY_DEBUG=0 composer install -o --no-dev --ignore-platform-reqs
php -S localhost:1337 -t web&
curl 'http://localhost:1337/app.php/'
ab -c 1 -t 10 'http://localhost:1337/app.php/'
```

We get the following results:

* Requests per second: 273.76 #/sec
* Time per request: 3.653 ms

We can also profile the application using [Blackfire](http://blackfire.io/) to
discover bottlenecks:

```
blackfire curl 'http://localhost:1337/app.php/'
killall -9 php
```

We get the following results:

* Wall Time: 12.5ms
* CPU Time: 11.4ms
* I/O Time: 1.09ms
* Memory: 2.2MB

Let's have a look at the graph:

<iframe width="960px" height="960px" frameborder="0" allowfullscreen src="https://blackfire.io/profiles/53f653ad-1770-4c89-93c4-1ff758b2b29e/embed"></iframe>

As expected from an empty application without any logic, we can clearly see that
autoloading is the number 1 bottleneck, with the Dependency Injection Container
being its main caller (for which the EventDispatcher is the main caller).

### ReactPHP version

Before we continue our benchmarks for the ReactPHP version of our application,
we'll need to modify it a bit in order to support Blackfire:

```
#!/usr/bin/env php
<?php
// bin/react.php

require __DIR__.'/../app/autoload.php';

$kernel = new AppKernel('prod', false);
$callback = function ($request, $response) use ($kernel) {
    $method = $request->getMethod();
    $headers = $request->getHeaders();
    $enableProfiling = isset($headers['X-Blackfire-Query']);
    if ($enableProfiling) {
        $blackfire = new Blackfire\Client();
        $probe = $blackfire->createProbe();
    }
    $query = $request->getQuery();
    $content = $request->getBody();
    $post = array();
    if (in_array(strtoupper($method), array('POST', 'PUT', 'DELETE', 'PATCH')) &&
        isset($headers['Content-Type']) && (0 === strpos($headers['Content-Type'], 'application/x-www-form-urlencoded'))
    ) {
        parse_str($content, $post);
    }
    $sfRequest = new Symfony\Component\HttpFoundation\Request(
        $query,
        $post,
        array(),
        array(), // To get the cookies, we'll need to parse the headers
        $request->getFiles(),
        array(), // Server is partially filled a few lines below
        $content
    );
    $sfRequest->setMethod($method);
    $sfRequest->headers->replace($headers);
    $sfRequest->server->set('REQUEST_URI', $request->getPath());
    if (isset($headers['Host'])) {
        $sfRequest->server->set('SERVER_NAME', explode(':', $headers['Host'])[0]);
    }
    $sfResponse = $kernel->handle($sfRequest);

    $response->writeHead(
        $sfResponse->getStatusCode(),
        $sfResponse->headers->all()
    );
    $response->end($sfResponse->getContent());
    $kernel->terminate($request, $response);
    if ($enableProfiling) {
        $blackfire->endProbe($probe);
    }
};

$loop = React\EventLoop\Factory::create();
$socket = new React\Socket\Server($loop);
$http = new React\Http\Server($socket);

$http->on('request', $callback);
$socket->listen(1337);
$loop->run();
```

This requires Blackfire's SDK:

```
SYMFONY_ENV=prod SYMFONY_DEBUG=0 composer require -o --update-no-dev --ignore-platform-reqs 'blackfire/php-sdk'
```

Now let's run the benchmarks:

```
php bin/react.php&
curl 'http://localhost:1337/'
ab -c 1 -t 10 'http://localhost:1337/'
```

We get the following results:

* Requests per second: 2098.17 #/sec
* Time per request: 0.477 ms

Finally we can profile it:

```
curl -H 'X-Blackfire-Query: enable' 'http://localhost:1337/'
killall -9 php
```

We get the following results:

* Wall Time: 1.51ms
* CPU Time: 1.51ms
* I/O Time: 0.001ms
* Memory: 0.105MB

Let's have a look at the graph:

<iframe width="960px" height="960px" frameborder="0" allowfullscreen src="https://blackfire.io/profiles/2ca1084f-ce66-4073-b2b8-4a82ed7e4c76/embed"></iframe>

This time we can see that most of the time is spent in event listeners, which is
expected since that's the only lace in our empty application where there's any
logic.

### Comparison

There's no denial, we've made use of our *potential* to achieve Super Speed: by
converting our application into a HTTP server using ReactPHP we improved our
Symfony application by **8**!

## Alternatives to ReactPHP

After running some silly benchmarks, we've picked ReactPHP as it was seemingly
yielding better results:

![ReactPHP is faster than Aerys which is faster than IcicleIO which is faster than PHP FastCGI](/images/super-speed-sf-react-php-graph.png)

However since we don't actually make use of the *true* potential of any of those
projects, it's worth mentioning them and their differences:

* [PHPFastCGI](http://phpfastcgi.github.io) aims at building a long running FastCGI application, rather than a HTTP server
  (see [Breaking Boundaries with FastCGI](http://andrewcarteruk.github.io/slides/breaking-boundaries-with-fastcgi/))
* [IcicleIO](http://icicle.io/) Icicle is a library for writing asynchronous code using synchronous coding techniques,
  it's powered by Generators/Coroutines
* [Amp](http://amphp.org/) is a non-blocking concurrency framework
  (see [Getting started with Amp](http://blog.kelunik.com/2015/09/20/getting-started-with-amp.html))
  - its Application Server component, [Aerys](http://amphp.org/docs/aerys/), also supports HTTP/2
  (see [Getting started with Aerys](http://blog.kelunik.com/2015/10/21/getting-started-with-aerys.html))

Not mentioned in the graph, there's also:

* [appserver.io](http://appserver.io/) a full Application Server, powered by threads
  (see [Appserver – a Production-Ready PHP-Based Server](http://www.sitepoint.com/appserver-a-production-ready-php-based-server/))
  - benchmarks showed it was actually slower than vanilla Symfony, which might be due to configuration issues
* [PHP-PM](https://github.com/php-pm/php-pm), manages ReactPHP processes
  (see [Bring High Performance Into Your PHP App](http://marcjschmidt.de/blog/2014/02/08/php-high-performance.html))
  - benchmarks showed it wasn't much faster than vanilla Symfony, which might be due to configuration issues
* [M6Web PHP process manager Bundle](https://github.com/M6Web/PhpProcessManagerBundle),
  provides your Symfony application as a ReactPHP server via a command
  - benchmarks showed it was a bit slower than vanilla ReactPHP

> **Note**: To check the benchmarks, have a look at [Bench Symfony Standard](https://github.com/gnugat-examples/bench-sf-standard).
> Each project has its own branch with the set up used and the benchmarks results.

## Why does ReactPHP improve performances?

To understand how turning our application into a HTTP server can increase
performances, we have to take a look how the alternative works. In a regular
stack (e.g. "Apache / mod_php" or "nginx / PHP-FPM"), for each HTTP request:

1. a HTTP server (e.g. Apache, nginx, etc) receives the Request
2. it starts a new PHP process, [variable super globals](http://php.net/manual/en/language.variables.superglobals.php),
   (e.g. `$_GET`, `$_POST`, etc) are created using data from the Request
3. the PHP process executes our code and produces an output
4. the HTTP server uses the output to create a Response, and **terminates the PHP process**

Amongst the advantages this brings, we can list not having to worry (too much) about:

* memory consumption: each new process starts with a fresh empty memory which is freed once it exits (memory leaks can be ignored)
* fatal errors: a process crashing won't affect other processes (but if they encounter the same error they'll also crash)
* statefullness: static and global variables are not shared between processes
* code updates: each new process starts with the new code

Killing the PHP process once the Response is sent means that nothing is shared
between two Requests (hence the name "shared-nothing" architecture).

One of the biggest disadvantages of such a set up is low performance., because
creating a PHP process for each HTTP Requests means adding a bootstraping footprint
which includes:

* starting a process
* starting PHP (loading configuration, starting extensions, etc)
* starting our application (loading configuration, initializing services, autoloading, etc)

With ReactPHP we keep our application alive between requests so we only execute
this bootstrap once when starting the server: the footprint is absent from Requests.

However now the tables are turned: we're vulnerable to memory consumption, fatal error,
statefulness and code update worries.

## Making ReactPHP production ready

So turning our application into a HTTP server means that way have to be mindful
developers: we have to make it stateless and we need to restart the server for
each updates.

Regarding fatal errors and memory consumption, there is a simple strategy to we
can use to mitigate their impact: automatically restart the server once it's stopped.

That's usually a feature included in load balancers (for example in PHP-PM, Aerys
and appserver.io), but we can also rely on [Supervisord](http://supervisord.org/).

On Debian based distributions it can easily be installed:

```
sudo apt-get install -y supervisor
```

Here's a configuration example (create a `*.conf` file in `/etc/supervisord/conf.d`):

```
[program:bench-sf-standard]
command=php bin/react.php
environment=PORT=55%(process_num)02d
process_name=%(program_name)s-%(process_num)d
numprocs=4
directory=/home/foobar/bench-sf-standard
umask=022
user=foobar
stdout_logfile=/var/log/supervisord/%(program_name)s-%(process_num)d.log              ; stdout log path, NONE for none; default AUTO
stderr_logfile=/var/log/supervisord/%(program_name)s-%(process_num)d-error.log        ; stderr log path, NONE for none; default AUTO
autostart=true
autorestart=true
startretries=3
```

It will:

* run 4 ReactPHP servers on ports `5500`, `5501`, `5502` and `5503`
* it restarts them automatically when they crash (will try a maximum of 3 times, then give up)

Here's a nice resource for it: [Monitoring Processes with Supervisord](https://serversforhackers.com/monitoring-processes-with-supervisord).

While PHP itself doesn't leak memory, our application might. The more memory a PHP
application uses, the slower it will get, until it reaches the limit and crashes.
As a safeguard, we can:

* stop the server after X requests (put a counter in the callback and once the server stops, Supervisord will restart a new one)
* stop the server once a given memory limit is reached (then supervisord will restart a new one)

But a better way would be to actually [hunt down memoy leaks, for example with PHP meminfo](https://speakerdeck.com/bitone/hunting-down-memory-leaks-with-php-meminfo).

We also need to know a bit more about the tools we use such as Doctrine ORM or
Monolog to avoid pitfalls (or use [the LongRunning library](https://github.com/LongRunning/LongRunning#longrunning)
to clean those automatically for us).

## Conclusion

It only takes ~50 lines to turn our application into a HTTP server, ReactPHP is
indeed a powerful library.

In fact we haven't even used its main features and still managed to greatly
improve performances! But these will be the subject of a different article.

> **Note**: Read-only APIs are a good candidate for such a set up.

In the next blog post, we'll have a look at a different way (not that we can't
combine both) to achieve the Super Speed potential of our applications built
with HTTP frameworks like Symfony.

In the meantime, here's some resources about turning our applications into HTTP
applications:

* [Things to consider when developing an application with PHPFastCGI](http://phpfastcgi.github.io/general/2015/08/21/things-to-consider-using-phpfastcgi.html)
* [Running Symofny applications with PHP-PM or PHPFastCGI](https://www.symfony.fi/entry/running-symfony-applications-with-php-pm)
* [Fabien Potencier's take on PHP](https://www.youtube.com/watch?v=gpNbmEnRLBU)
* [PHP High-Performance - Follow Up with Symfony/Jarves.io and PHP-PM](http://marcjschmidt.de/blog/2016/04/16/php-high-performance-reactphp-jarves-symfony-follow-up.html)
* [Serve PSR-7 Middleware Via React](https://mwop.net/blog/2016-04-17-react2psr7.html)
