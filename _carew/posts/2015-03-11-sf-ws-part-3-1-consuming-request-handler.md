---
layout: post
title: Symfony / Web Services - part 3.1: Consuming, RequestHandler
tags:
    - Symfony
    - phpspec
    - Symfony / Web Services series
---

This is the fifth article of the series on managing Web Services in a
[Symfony](https://symfony.com) environment. Have a look at the four first ones:

* {{ link('posts/2015-01-14-sf-ws-part-1-introduction.md', '1. Introduction') }}
* {{ link('posts/2015-01-21-sf-ws-part-2-1-creation-bootstrap.md', '2.1 Creation bootstrap') }}
* {{ link('posts/2015-01-28-sf-ws-part-2-2-creation-pragmatic.md', '2.2 Creation, the pragmatic way') }}
* {{ link('posts/2015-03-04-sf-ws-part-2-3-creation-refactoring.md', '2.3 Creation, refactoring') }}

Our purpose in this third section is to create an application that consumes the
[previously created web services](https://github.com/gnugat-examples/sf-ws).

But for now, we'll just bootstrap it, and start to create a RequestHandler!

## Installation

We will follow the exact same steps as in {{ link('posts/2015-01-21-sf-ws-part-2-1-creation-bootstrap.md', 'the chapter 2.1') }}:

1. Installing the standard edition
2. Twitching for tests

Instead of calling our application `ws`, we'll call it `cs` (like Consuming Service).

## Making remote calls with Guzzle

Is the application boostrapped yet? If it is, then we can continue.

In order to consume web services, we need to be able to make remote requests. PHP
provides some native functions for this (`file_get_contents`, `stream_socket_client`,
`fopen`, etc) and we can find many libraries as well ([Buzz](https://github.com/kriswallsmith/Buzz),
[HTTP Full](http://phphttpclient.com/), [React](http://reactphp.org/), etc).

For this series, we'll use [Guzzle](http://guzzle.readthedocs.org/en/latest/):

    composer require guzzlehttp/guzzle:~5.0

Let's commit it for now:

    git add -A
    git commit -m 'Installed Guzzle'

## Creating a Request Handler

Sometimes we need to decouple our application from the third party libraries it depends on.

For example let's say that we were using Guzzle 4, but we'd like to use Amazon Web Service (AWS)
S3 in our project. The issue? It's version 2 depends on Guzzle 3 and its version 3
depends on Guzzle 5. We now need to upgrade our usage of Guzzle everywhere in our
application.

[![True story](http://i0.kym-cdn.com/photos/images/newsfeed/000/141/710/7nTnr.png?1309357850)](http://knowyourmeme.com/photos/141710-true-story)

To minimize this, we can centralize the usage of Guzzle in one single file. In order
to be able to do so, we'll create a RequestHandler:

```php
<?php
// File: src/AppBundle/RequestHandler/RequestHandler.php

namespace AppBundle\RequestHandler;

interface RequestHandler
{
    // @return Response
    public function handle(Request $request);
}
```

In our application we can rely on this interface: we own it and it has few chances to change.
We'll now create an object that describes the request to send:

    ./bin/phpspec describe 'AppBundle\RequestHandler\Request'

A minimalistic raw HTTP request looks like the following:

    GET /api/v1/profiles HTTP/1.1

Since we don't really care about the protocol's version we can define the constructor
with two arguments:

```php
// File: spec/AppBundle/RequestHandler/RequestSpec.php

    function it_has_a_verb_and_an_uri()
    {
        $this->beConstructedWith('GET', '/api/v1/profiles');

        $this->getVerb()->shouldBe('GET');
        $this->getUri()->shouldBe('/api/v1/profiles');
    }
```

Running the specifications will bootstrap the class for us:

    ./bin/phpspec run

We can now make the test pass by writing the code:

```php
<?php
// File: src/AppBundle/RequestHandler/Request.php

namespace AppBundle\RequestHandler;

class Request
{
    private $verb;
    private $uri;

    public function __construct($verb, $uri)
    {
        $this->verb = $verb;
        $this->uri = $uri;
    }

    public function getVerb()
    {
        return $this->verb;
    }

    public function getUri()
    {
        return $this->uri;
    }
}
```

Let's check if it's enough for now:

    ./bin/phpspec run

All green, we can commit:

    git add -A
    git commit -m 'Created Request'

## Request headers

A request usually has headers:

```php
// File: spec/AppBundle/RequestHandler/RequestSpec.php

    function it_can_have_headers()
    {
        $this->beConstructedWith('GET', '/api/v1/profiles');
        $this->setHeader('Content-Type', 'application/json');

        $this->getHeaders()->shouldBe(array('Content-Type' => 'application/json'));
    }
```

Let's boostrap them:

    ./bin/phpspec run

And complete the code:

```php
// File: src/AppBundle/RequestHandler/Request.php

    private $headers = array();

    public function setHeader($name, $value)
    {
        $this->headers[$name] = $value;
    }

    public function getHeaders()
    {
        return $this->headers;
    }
```

This makes the test pass:

    ./bin/phpspec run

That's worth a commit:

    git add -A
    git commit -m 'Added headers to Request'

## Request body

The last addition to our request will be the possibility to add a body:

```php
// File: spec/AppBundle/RequestHandler/RequestSpec.php

    function it_can_have_a_body()
    {
        $this->beConstructedWith('GET', '/api/v1/profiles');
        $this->setBody('{"wound":"just a flesh one"}');

        $this->getBody()->shouldBe('{"wound":"just a flesh one"}');
    }
```

As usual we bootstrap it:

    ./bin/phpspec run

And then we complete it:

```php
// File: src/AppBundle/RequestHandler/Request.php

    private $body;

    public function setBody($body)
    {
        $this->body = $body;
    }

    public function getBody()
    {
        return $this->body;
    }
```

Let's make our console green:

    ./bin/phpspec run

Let's make our console grin:

    git add -A
    git commit -m 'Added body to Request'

## Creating a Response

`RequestHandler` should return a `Response` object:

    ./bin/phpspec describe 'AppBundle\RequestHandler\Response'

A minimalistic raw HTTP response looks like the following:

    HTTP/1.1 204 NO CONTENT

Since we don't care about both the protocol's version and the reason, we can
define the constructor with a single argument:

```php
// File: spec/AppBundle/RequestHandler/ResponseSpec.php

    function it_has_a_status_code()
    {
        $this->beConstructedWith(204);

        $this->getStatusCode()->shouldBe(204);
    }
```

Running the specifications will bootstrap the class for us:

    ./bin/phpspec run

We can now make the test pass by writing the code:

```php
<?php
// File: src/AppBundle/RequestHandler/Response.php

namespace AppBundle\RequestHandler;

class Response
{
    private $statusCode;

    public function __construct($statusCode)
    {
        $this->statusCode = $statusCode;
    }

    public function getStatusCode()
    {
        return $this->statusCode;
    }
}
```

Let's check if it's enough for now:

    ./bin/phpspec run

All green, we can commit:

    git add -A
    git commit -m 'Created Response'

## Response headers

A response can also have headers:

```php
// File: spec/AppBundle/RequestHandler/ResponseSpec.php

    function it_can_have_headers()
    {
        $this->beConstructedWith(204);
        $this->setHeaders(array('Content-Type' => 'application/json'));

        $this->getHeader('Content-Type')->shouldBe('application/json');
    }
```

Let's boostrap them:

    ./bin/phpspec run

And complete the code:

```php
// File: src/AppBundle/RequestHandler/Response.php

    private $headers = array();

    public function setHeaders(array $headers)
    {
        $this->headers = $headers;
    }

    public function getHeader($name)
    {
        return (isset($this->headers[$name]) ? $this->headers[$name] : null);
    }
```

This makes the test pass:

    ./bin/phpspec run

That's worth a commit:

    git add -A
    git commit -m 'Added headers to Response'

## Response body

Last but not least, the response's body:

```php
// File: spec/AppBundle/RequestHandler/ResponseSpec.php

    function it_can_have_a_body()
    {
        $this->beConstructedWith(200);
        $this->setBody('{"wound":"just a flesh one"}');

        $this->getBody()->shouldBe('{"wound":"just a flesh one"}');
    }
```

As usual we bootstrap it:

    ./bin/phpspec run

And then we complete it:

```php
// File: src/AppBundle/RequestHandler/Response.php

    private $body;

    public function setBody($body)
    {
        $this->body = $body;
    }

    public function getBody()
    {
        return $this->body;
    }
```

Let's make our console green:

    ./bin/phpspec run

Let's make our console grin:

    git add -A
    git commit -m 'Added body to Response'

## Conclusion

We've bootstrapped an application, and created a RequestHandler which will help us
to avoid coupling with Guzzle. In the {{ link('posts/2015-03-18-sf-ws-part-3-2-consuming-guzzle.md', 'next article') }},
we'll talk about middleware and start to create some RequestHandler
implementations (yes, more than one!).
