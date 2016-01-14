---
layout: post
title: Diactoros (PSR-7)
tags:
    - introducing library
    - Diactoros
    - PSR-7
---

[Zend Diactoros](https://github.com/zendframework/zend-diactoros) is a lightweight
library providing implementations for [PSR-7 interfaces](http://www.php-fig.org/psr/psr-7/).

It can be installed using [Composer](https://getcomposer.org/download/):

    composer require zendframework/zend-diactoros:^1.0

## Example

We'd like to retrieve data from remote endpoints, using our internal `RequestHandler`:

```php
<?php

namespace Vendor\Project;

use Psr\Http\Message\RequestInterface;

interface RequestHandler
{
    // @return \Psr\Http\Message\ResponseInterface
    public function handle(RequestInterface $request);
}
```

> **Note**: For the sake of our example we use this interface, but in your application
> you'd use an actual HTTP client (e.g. [Guzzle](http://guzzle.readthedocs.org/en/latest/)).

`RequestHandler` expects a `Request` parameter, so we're going to build it:

```php
<?php

namespace Vendor\Project;

use Zend\Diactoros\Request;
use Zend\Diactoros\Stream;

class MemberGateway
{
    private $requestHandler;
    private $username;
    private $password;

    public function __construct(RequestHandler $requestHandler, $username, $password)
    {
        $this->requestHandler = $requestHandler;
        $this->username = $username;
        $this->password = $password;
    }

    public function findOne($id)
    {
        $request = new Request('http://example.com/members/'.$id, 'GET', 'php://memory', array(
            'Authorization' => 'Basic '.base64_encode($this->username.':'.$this->password),
        ));
        $item = json_decode($this->requestHandler->handle($request)->getBody()->__toString(), true);

        return array(
            'id' => $item['id'],
            'name' => $item['name'],
            'description' => $item['description'],
        );
    }

    public function createOne($name, $description)
    {
        $body = new Stream('php://memory', 'w');
        $body->write(json_encode(array(
            'name' => $name,
            'description' => $description,
        )));
        $request = new Request('http://example.com/members/'.$id, 'GET', $body, array(
            'Authorization' => 'Basic '.base64_encode($this->username.':'.$this->password),
        ));
        $item = json_decode($this->requestHandler->handle($request)->getBody()->__toString(), true);

        return array(
            'id' => $item['id'],
            'name' => $item['name'],
            'description' => $item['description'],
        );
    }
}
```

The body of `Request` and `Response` is wrapped in a `Stream` (as specified in PSR-7).

## Tips

If the `Request` body should be empty, simply pass `php://memory`.

If the `Response` has a body, we can convert the `Stream` into a string using `__toString`.

## Conclusion

Zend Diactoros is becoming the de facto PSR-7 implementation, for example it's
used in [Symfony](http://symfony.com/blog/psr-7-support-in-symfony-is-here).

You should give it a try!
