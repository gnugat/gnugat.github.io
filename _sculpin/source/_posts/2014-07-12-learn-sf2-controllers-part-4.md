---
layout: post
title: "Learn Symfony2 - part 4: Controllers"
tags:
    - symfony
    - learn symfony2 series
    - deprecated
---

> **Deprecated**: This series has been re-written - see
> [The Ultimate Developer Guide to Symfony](/2016/02/03/ultimate-symfony-http-kernel.html)

This is the fourth article of the series on learning
[the Symfony2 framework](http://symfony.com/).
Have a look at the three first ones:

1. [Composer](/2014/06/18/learn-sf2-composer-part-1.html)
2. [Empty application](/2014/06/25/learn-sf2-empty-app-part-2.html)
3. [Bundles](/2014/07/02/learn-sf2-bundles-part-3.html)

In the previous articles we created a one-bundled empty application with the
following files:

    .
    ├── app
    │   ├── AppKernel.php
    │   ├── cache
    │   │   └── .gitkeep
    │   ├── config
    │   │   └── config.yml
    │   └── logs
    │       └── .gitkeep
    ├── composer.json
    ├── composer.lock
    ├── src
    │   └── Knight
    │       └── ApplicationBundle
    │           └── KnightApplicationBundle.php
    ├── .gitignore
    └── web
        └── app.php

Running `composer install` should create a `vendor` directory, which we ignored
with git.

Here's the [repository where you can find the actual code](https://github.com/gnugat/learning-symfony2/releases/tag/3-bundles).

In this article, we'll learn more about the routing and the controllers.

## Discovering routing and controller

In order to get familiar with the routing and controllers, we will create a
route which returns nothing. The first thing to do is to configure the router:

    # File: app/config/app.yml
    framework:
        secret: "Three can keep a secret, if two of them are dead."
        router:
            resource: %kernel.root_dir%/config/routing.yml

We can now write our routes in a separate file:

    # File: app/config/routing.yml
    what_john_snow_knows:
        path: /api/ygritte
        methods:
            - GET
        defaults:
            _controller: KnightApplicationBundle:Api:ygritte

As you can see, a route has:

* a name (`what_john_snow_knows`)
* a path (`/api/ygritte`)
* one or many HTTP verbs (`GET`)
* a controller `Knight\ApplicationBundle\Controller\ApiController::ygritteAction()`

*Note*: the `_controller` parameter is a shortcut composed of three parts, which
are the name of the bundle, then the unprefixed controller name and finally the
unprefixed method name.

Now we need to create the following directory:

    mkdir src/Knight/ApplicationBundle/Controller

And to create the controller class:

    <?php
    // File: src/Knight/ApplicationBundle/Controller/ApiController.php

    namespace Knight\ApplicationBundle\Controller;

    use Symfony\Bundle\FrameworkBundle\Controller\Controller;
    use Symfony\Component\HttpFoundation\Request;
    use Symfony\Component\HttpFoundation\Response;

    class ApiController extends Controller
    {
        public function ygritteAction(Request $request)
        {
            return new Response('', Response::HTTP_NO_CONTENT);
        }
    }

To test it, I'd advise you to use a HTTP client. Let's install
[HTTPie, the CLI HTTP client](http://httpie.org):

    sudo apt-get install python-pip
    sudo pip install --upgrade httpie

We can now test our webservice:

    http GET knight.local/api/ygritte

The first line should be `HTTP/1.1 204 No Content`.

## Posting data

Our scrum master and product owner managed to write a user story for us:

    As a Knight of Ni
    I want a webservice which says "ni"
    In order to get a shrubbery

This means we're going to need the following route:

    # File: app/config/routing.yml
    ni:
        path: /api/ni
        methods:
            - POST
        defaults:
            _controller: KnightApplicationBundle:Api:ni

Our controller will retrieve the posted value (named `offering`), check if it
is a `shrubbery` and send back a response containing either `Ni` (on error) or
`Ecky-ecky-ecky-ecky-pikang-zoop-boing-goodem-zoo-owli-zhiv` (on success):

    <?php
    // File: src/Knight/ApplicationBundle/Controller/ApiController.php

    namespace Knight\ApplicationBundle\Controller;

    use Symfony\Bundle\FrameworkBundle\Controller\Controller;
    use Symfony\Component\HttpFoundation\Request;
    use Symfony\Component\HttpFoundation\Response;
    use Symfony\Component\HttpFoundation\JsonResponse;

    class ApiController extends Controller
    {
        public function niAction(Request $request)
        {
            $postedContent = $request->getContent();
            $postedValues = json_decode($postedContent, true);

            $answer = array('answer' => 'Ecky-ecky-ecky-ecky-pikang-zoop-boing-goodem-zoo-owli-zhiv');
            $statusCode = Response::HTTP_OK;
            if (!isset($postedValues['offering']) || 'shrubbery' !== $postedValues['offering']) {
                $answer['answer'] = 'Ni';
                $statusCode = Response::HTTP_UNPROCESSABLE_ENTITY;
            }

            return new JsonResponse($answer, $statusCode);
        }
    }

The `JsonResponse` class will convert the array into JSON and set the proper
HTTP headers.

If we try to submit something fishy like this:

    http POST knight.local/api/ni offering=hareng

Then we should have a response similar to:

    HTTP/1.1 422 Unprocessable Entity
    Cache-Control: no-cache
    Content-Type: application/json
    Date: Thu, 10 Jul 2014 15:23:00 GMT
    Server: Apache
    Transfer-Encoding: chunked

    {
        "answer": "Ni"
    }

And when we submit the correct offering:

    http POST knight.local/api/ni offering=shrubbery

Then we should have something similar to:

    HTTP/1.1 200 OK
    Cache-Control: no-cache
    Content-Type: application/json
    Date: Thu, 10 Jul 2014 21:42:00 GMT
    Server: Apache
    Transfer-Encoding: chunked

    {
        "answer": "Ecky-ecky-ecky-ecky-pikang-zoop-boing-goodem-zoo-owli-zhiv"
    }

## Request's API

Here's part of the Request's API:

    <?php

    namespace Symfony\Component\HttpFoundation;

    class Request
    {
        public $request; // Request body parameters ($_POST)
        public $query; // Query string parameters ($_GET)
        public $files; // Uploaded files ($_FILES)
        public $cookies; // $_COOKIE
        public $headers; // Taken from $_SERVER

        public static function createFromGlobals():
        public static function create(
            $uri,
            $method = 'GET',
            $parameters = array(),
            $cookies = array(),
            $files = array(),
            $server = array(),
            $content = null
        );

        public function getContent($asResource = false);
    }

We used `createFromGlobals` in our front controller (`web/app.php`), it does
excalty what it says: it initializes the Request from the PHP superglobals
(`$_POST`, `$_GET`, etc).

The `create` method is really handful in tests as we won't need to override the
values in PHP's superglobals.

The attributes here listed are all instances of
`Symfony\Component\HttpFoundation\ParameterBag`, which is like an object
oriented array with `set`, `has` and `get` methods (amongst others).

When you submit a form, your browser automatically sets the HTTP request's
header `Content-Type` to `application/x-www-form-urlencoded`, and the form
values are sent in the request's content like this:

    offering=hareng

PHP understands this and will put the values in the `$_POST` superglobal. This
mean you could retrieve it like this:

    $request->request->get('offering');

However, when we submit something in JSON with the `Content-Type` set to
`application/json`, PHP doesn't populate `$_POST`. You need to retrieve the raw
data with `getContent` and to convert it using `json_decode`, as we did in our
controller.

## Response's API

Here's a part of the Response's API:

    <?php

    namespace Symfony\Component\HttpFoundation;

    class Response
    {
        const HTTP_OK = 200;
        const HTTP_CREATED = 201;
        const HTTP_NO_CONTENT = 204;
        const HTTP_UNAUTHORIZED = 401;
        const HTTP_FORBIDDEN = 403;
        const HTTP_NOT_FOUND = 404;
        const HTTP_UNPROCESSABLE_ENTITY = 422; // RFC4918

        public $headers; // @var Symfony\Component\HttpFoundation\ResponseHeaderBag

        public function __construct($content = '', $status = 200, $headers = array())

        public function getContent();
        public function getStatusCode();

        public function isSuccessful();
    }

There's a lot of HTTP status code constants, so I've selected only those I'd use
the most.

You can set and get the Response's headers via a public property which is also
a `ParameterBag`.

The constructor allows you to set the content, status code and headers.

The three other methods are mostly used in tests. There's a lot of `is` methods
to check the type of the request, but usually you'll just want to make sure the
response is successful.

You can find other types of responses:

* `JsonResponse`: sets the `Content-Type` and converts the content into JSON
* `BinaryFileResponse`: sets headers and attaches a file to the response
* `RedirectResponse`: sets the target location for a redirection
* `StreamedResponse`: useful for streaming large files

## Conclusion

Symfony2 is an HTTP framework which primary's public API are the controllers:
those receive a Request as parameter and return a Response. All you have to do
is to create a controller, write some configuration in order to link
it to an URL and you're done!

Do not forget to commit your work:

    git add -A
    git commit -m 'Created Ni route and controller'

The next article should be about tests: stay tuned!
