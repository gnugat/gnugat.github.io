---
layout: post
title: The Ultimate Developer Guide to Symfony - HTTP Kernel
tags:
    - symfony
    - ultimate symfony series
    - reference
---

> **Reference**: This article is intended to be as complete as possible and is
> kept up to date.

> **TL;DR**: `$response = $httpKernel->handle($request);`

[Symfony](http://symfony.com) provides many standalone libraries (also known as
"Components") that help us build applications.

In this guide we'll see the main ones that allow us to build an application:

* HTTP Kernel and HTTP Foundation
* [Event Dispatcher](/2016/02/10/ultimate-symfony-event-dispatcher.html)
* Routing and YAML
* Dependency Injection
* Console

## HTTP kernel

Symfony provides a [HttpKernel component](http://symfony.com/doc/current/components/http_kernel/introduction.html)
which follows the HTTP protocol: it converts a `Request` into a `Response`.

It all revolves around the following interface:

```php
<?php

namespace Symfony\Component\HttpKernel;

use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

interface HttpKernelInterface
{
    const MASTER_REQUEST = 1;
    const SUB_REQUEST = 2;

    /**
     * @param Request $request
     * @param int     $type
     * @param bool    $catch   Whether to catch exceptions or not
     *
     * @return Response
     */
    public function handle(Request $request, $type = self::MASTER_REQUEST, $catch = true);
}
```

## HttpFoundation

HttpKernel relies on the [HttpFoundation component](http://symfony.com/doc/current/components/http_foundation/introduction.html)
which mainly provides:

* `Request`: wraps `$_GET`, `$_POST`, `$_COOKIE`, `$_FILES` and `$_SERVER`
* `Response`: wraps `header()` and `setcookie()`, but also displays the content

> **Note**: Global variables have the drawback to be possibly accessed by many
> functions, causing their state to be unpredictable (hence bugs happen and they
> are hard to find/understand).
>
> With HttpFoundation, [PHP super globals](http://php.net/manual/en/language.variables.superglobals.php)
> shouldn't be accessed directly, but rather via the objects that wraps them
> (e.g. `Request`) which are passed around (those objects are not global).

Here's a typical usage:

```php
$request = Request::createFromGlobals();
$response = $httpKernel->handle($request);
$reponse->send();
```

In the above example, `Request` will be initialized using PHP super globals.
Sometimes it can be useful to build it with our own provided values (e.g. for tests):

```php
$uri = '/v1/items';
$method = 'POST';
$parameters = array(); // GET or POST parameters, usually left unused (use uri and content instead)
$cookies = array();
$files = array();
$headers = array('CONTENT_TYPE' => 'application/json');
$content = json_encode(array('name' => 'Arthur Dent'));

$request = Request::create($uri, $method, $getOrPostParameters, $cookies, $files, $headers, $content);
```

In our application, we'll mainly extract its parameters:

```php
$getParameter = $request->query->get('description'); // e.g. from URI `/?description=hitchhicker`
$postParameter = $request->request->get('name'); // e.g. from content `name=Arthur`
$header = $request->headers->get('Content-Type'); // e.g. from headers `Content-Type: application/x-www-form-urlencoded`

$customParameter = $request->attributes->get('_route'); // We'll see more about it in the next article
```

> **Note**: Those public properties are instances of `Symfony\Component\HttpFoundation\ParameterBag`,
> except `headers` which is an instance of `Symfony\Component\HttpFoundation\HeaderBag`.

In our application we'll mainly build `Response`:

```php
$content = json_encode(array('name' => 'Arthur Dent'));
$status = 201;
$headers = array('Content-Type' => 'application/json');

$response = new Reponse($content, $status, $headers);
```

## Example

Let's create a small Hello World example:

```php
<?php

use Symfony\Component\HttpKernel\HttpKernelInterface;
use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

class HelloWorldHttpKernel implements HttpKernelInterface
{
    public function handle(Request $request, $type = self::MASTER_REQUEST, $catch = true)
    {
        $name = $request->query->get('name', 'World');

        return new Response("Hello $name!", 200);
    }
}

$httpKernel = new HelloWorldHttpKernel();

$request = Request::createFromGlobals();
$response = $httpKernel->handle($request);
$response->send();
```

So we can get the following:

* for `/` URL, we get `Hello World!`
* for `/?name=Arthur` URL, we get `Hello Arthur!`

## Conclusion

Symfony provides a simple yet powerful component allowing us to follow the HTTP
protocol.

In this article we've seen the basics and how it works behind the hood, but in
an actual application we don't necessarily need to create our own implementation
of `HttpKernelInterface`.

Indeed there's a `Symfony\Component\HttpKernel\Kernel` abstract class that can
be used out of the box. It provides many features that we'll explore in the next
articles:

* [Event Dispatcher](/2016/02/10/ultimate-symfony-event-dispatcher.html)
* Routing and YAML
* Dependency Injection
