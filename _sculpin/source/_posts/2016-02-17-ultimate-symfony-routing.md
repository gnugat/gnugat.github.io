---
layout: post
title: The Ultimate Developer Guide to Symfony - Routing
tags:
    - symfony
    - ultimate symfony series
    - reference
---

> **Reference**: This article is intended to be as complete as possible and is
> kept up to date.

> **TL;DR**:
>
> ```php
> $parameters = $urlMatcher->match($request->getPathInfo());
>
> $request->attributes->add(array('_controller' => $parameters['_controller']);
> $request->attributes->add(array('_route' => $parameters['_route']);
> unset($parameters['_controller'], $parameters['_route']);
> $request->attributes->add(array('_route_params' => $parameters);
> ```

In this guide we explore the standalone libraries (also known as "Components")
provided by [Symfony](http://symfony.com) to help us build applications.

We've already seen:

* [HTTP Kernel and HTTP Foundation](/2016/02/03/ultimate-symfony-http-kernel.html)
* [Event Dispatcher](/2016/02/10/ultimate-symfony-event-dispatcher.html)

We're now about to check Routing and YAML, then in the next articles we'll have a look at:

* Dependency Injection
* Console

## Routing

Symfony provides a [Routing component](http://symfony.com/doc/current/components/routing/introduction.html)
which allows us, for a HTTP request/URL, to execute a specific function (also known as "Controller").

> **Note**: Controllers must be a [callable](http://php.net/manual/en/language.types.callable.php),
> for example:
>
> * an anonymous function: `$controller = function (Request $request) { return new Response() };`.
> * an array with an instance of a class and a method name:
>   `$controller = array($controller, 'searchArticles');`.
> * a fully qualified classname with a static method name:
>  `$controller = 'Vendor\Project\Controller\ArticleController::searchArticles'`.
>
> Controllers can take a Request argument and should return a Response instance.

It revolves around the following interface:

```php
<?php

namespace Symfony\Component\Routing\Matcher;

use Symfony\Component\Routing\Exception\ResourceNotFoundException;
use Symfony\Component\Routing\Exception\MethodNotAllowedException;

interface UrlMatcherInterface
{
    /**
     * @param string $pathinfo
     *
     * @return array Route parameters (also contains `_route`)
     *
     * @throws ResourceNotFoundException
     * @throws MethodNotAllowedException
     */
    public function match($pathinfo);
}
```

> **Note**: For brevity the interface has been stripped from `RequestContextAwareInterface`.

In actual applications we don't need to implement it as the component provides
a nice implementation that works with `RouteCollection`:

```php
<?php

use Symfony\Component\Routing\RouteCollection;
use Symfony\Component\Routing\Route;

$collection = new RouteCollection();
$collection->add('search_articles', new Route('/v1/articles', array(
    '_controller' => 'Vendor\Project\Controller\ArticleController::search',
), array(), array(), '', array(), array('GET', 'HEAD')));

$collection->add('edit_article', new Route('/v1/articles/{id}', array(
    '_controller' => 'Vendor\Project\Controller\ArticleController::edit',
), array(), array(), '', array(), array('PUT')));
```

`RouteCollection` allows us to configure which Request will match our controllers:
via URL patterns and Request method. It also allows us to specify parts of the URLs
as URI parameters (e.g. `id` in the above snippet).

Building route configuration by interracting with PHP code can be tedious, so the
Routing component supports alternative configuration formats: annotations, XML, YAML, etc.

> **Tip**: have a look at `Symfony\Component\Routing\Loader\YamlFileLoader`.

## YAML

Symfony provides a [YAML component](http://symfony.com/doc/current/components/yaml/introduction.html)
which allows us to convert YAML configuration into PHP arrays (and vis versa).

For example the following YAML file:

```
# /tmp/routing.yml
search_articles:
    path: /api/articles
    defaults:
        _controller: "Vendor\Project\Controller\ArticleController::search"
    methods:
        - GET
        - HEAD

edit_article:
    path: "/api/articles/{id}"
    defaults:
        _controller: "Vendor\Project\Controller\ArticleController::edit"
    methods:
        - PUT
```

> **Note**: Some string values must be escaped using double quotes because the YAML
> has a list of [reserved characters](http://stackoverflow.com/a/22235064), including:
> `@`, `%`, `\`, `-`, `:` `[`, `]`, `{` and `}`.

Can be converted using:

```php
<?php

use Symfony\Component\Yaml\Yaml;

$routing = Yaml::parse(file_get_contents('/tmp/routing.yml'));
```

This will result in the equivalent of the following array:

```php
<?php

$routing = array(
    'search_articles' => array(
        'path' => '/api/articles',
        'defaults' => array(
            '_controller' => 'Vendor\Project\Controller\ArticleController::search',
        ),
        'methods' => array(
            'GET',
            'HEAD',
        ),
    ),
    'edit_article' => array(
        'path' => '/api/articles/{id}',
        'defaults' => array(
            '_controller' => 'Vendor\Project\Controller\ArticleController::edit',
        ),
        'methods' => array(
            'PUT',
        ),
    ),
);
```

> **Note**: the Routing component uses another component to then build `RouteCollection`
> from this array: the [Config component](http://symfony.com/doc/current/components/config/introduction.html)
> which is out of the scope of this guide.

There's also `$yaml = Yaml::dump($array);` that converts a PHP array into a YAML
string.

## Conclusion

The Routing component allows us to define which Controllers should be executed
for the given Request, and the Yaml component allows us to configure it in a simple way.

HttpKernel provides a `RouterListener` which makes use of `UrlMatcher` when the
Request is received to find a corresponding controller.

> **Note**: `Request->attributes` is used to store information about the current
> Request such as the matched route, the controller, etc. It's used internally
> by Symofny but we could also store our own values in it.

Some might be concerned with performance: reading the configuration from the
filesystem may slow down the application.

Don't panic! There's a `PhpMatcherDumper` class which can generate an implementation
of `UrlMatcherInterface` with all configuration in an optimized way. It might look
like this:

```php
<?php

use Symfony\Component\Routing\Exception\MethodNotAllowedException;
use Symfony\Component\Routing\Exception\ResourceNotFoundException;
use Symfony\Component\Routing\RequestContext;

class appDevUrlMatcher extends Symfony\Bundle\FrameworkBundle\Routing\RedirectableUrlMatcher
{
    public function __construct(RequestContext $context)
    {
        $this->context = $context;
    }

    public function match($pathinfo)
    {
        $allow = array();
        $pathinfo = rawurldecode($pathinfo);
        $context = $this->context;

        // edit_article
        if (preg_match('#^/v1/articles/(?P<id>[^/]++)$#s', $pathinfo, $matches)) {
            if ($this->context->getMethod() != 'PUT') {
                $allow[] = 'PUT';
                goto not_edit_article;
            }

            return $this->mergeDefaults(array_replace($matches, array('_route' => 'edit_article')), array (  '_controller' => 'Vendor\Project\Controller\ArticleController::edit',));
        }
        not_edit_article:

        // search_articles
        if ($pathinfo === '/v1/articles') {
            if (!in_array($this->context->getMethod(), array('GET', 'HEAD'))) {
                $allow = array_merge($allow, array('GET', 'HEAD'));
                goto not_search_articles;
            }

            return array (  '_controller' => 'app.article_controller:search',  '_route' => 'Vendor\Project\Controller\ArticleController::search',);
        }
        not_search_articles:

        throw 0 < count($allow) ? new MethodNotAllowedException(array_unique($allow)) : new ResourceNotFoundException();
    }
}
```
