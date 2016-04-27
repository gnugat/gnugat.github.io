---
layout: post
title: Super Speed Symfony - nginx
tags:
    - symfony
---

> **TL;DR**: Put a reverse proxy (for HTTP cache or load balancing purpose) in
> front of your application, to increase its performances.

HTTP frameworks, such as [Symfony](https://symfony.com/), allow us to build
applications that have the *potential* to achieve Super Speed.

We've already seen a first way to do so ([by turning it into a HTTP server](/2016/04/13/super-speed-sf-react-php.html)),
another way would be to put a reverse proxy in front of it.

In this article we'll take a Symfony application and demonstrate how to do so
using [nginx](http://nginx.com/).

> **Note**: those two ways can be combined, or used independently.

## nginx with PHP-FPM

The regular PHP application set up is with nginx and [PHP-FPM](http://php-fpm.org/):

```
sudo apt-get install nginx php7.0-fpm
```

PHP-FPM is going to run our PHP application in a [shared-nothing architecture](https://en.wikipedia.org/wiki/Shared_nothing_architecture).
We might want it to be run with [the same user as the CLI one](http://symfony.com/doc/current/book/installation.html#book-installation-permissions)
to avoid permissions issues:

```
; /etc/php/7.0/fpm/pool.d/www.conf

; ...

user = foobar
group = foobar

; ...

listen.owner = foobar
listen.group = foobar

; ...
```

We should probably do the same for nginx:

```
# /etc/nginx/nginx.conf
user foobar foobar;

# ...
```

Now we should be ready to set up a virtual host for our application:

```
# /etc/nginx/sites-available/super-speed-nginx
server {
    listen 80;
    server_name super-speed-nginx.example.com;
    root /home/foobar/super-speed-nginx/web;

    location / {
        # try to serve file directly, fallback to app.php
        try_files $uri /app.php$is_args$args;
    }

    location ~ ^/app\.php(/|$) {
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

        # Prevents URIs that include the front controller. This will 404:
        # http://domain.tld/app.php/some-path
        # Remove the internal directive to allow URIs like this
        internal;
    }

    # Keep your nginx logs with the symfony ones
    error_log /home/foobar/super-speed-nginx/var/logs/nginx_error.log;
    access_log /home/foobar/super-speed-nginx/var/logs/nginx_access.log;
}
```

> **Note**:
>
> * `fastcgi_pass`: the address of the FastCGI server, can be an IP and port (e.g. `127.0.0.1:9000` or a socket)
> * `fastcgi_split_path_info`: a regex capturing
>   - the script name (here `(.+\.php)` is a file with the `.php` extension), used to set `$fastcgi_script_name`
>   - the path info (here `(/.*)` is a URL like string), used to set `$fastcgi_path_info`
> * `include`: includes a file (here `/etc/nginx/fastcgi_params`)
> * `fastcgi_param`: set a FastCGI parameter (check defaults values in `/etc/nginx/fastcgi_params`)

Then we'll make sure it's enabled:

```
sudo ln -s /etc/nginx/sites-available/super-speed-nginx /etc/nginx/sites-enabled/super-speed-nginx
```

The only thing missing is a Symfony application! Let's create one using the
[Standard Edition](https://github.com/symfony/symfony-standard):

```
composer create-project symfony/framework-standard-edition super-speed-nginx
cd super-speed-nginx
SYMFONY_ENV=prod SYMFONY_DEBUG=0 composer install -o --no-dev
```

Finally, we can set up the domain name and restart nginx:

```
echo '127.0.0.1 super-speed-nginx.example.com' | sudo tee --append /etc/hosts
sudo service nginx restart
```

Let's check if it works: [http://super-speed-nginx.example.com/](http://super-speed-nginx.example.com/).
If a helpful "Welcome" message is displayed, then everything is fine.

> **Note**: If it doesn't work, check the logs:
>
> * application ones in `/home/foobar/super-speed-nginx/var/logs`
> * nginx ones in `/var/log/nginx`
> * PHP-FPM ones in `/var/log/php7.0-fpm.log`

Let's have a quick benchmark:

```
curl 'http://super-speed-nginx.example.com/'
ab -t 10 -c 10 'http://super-speed-nginx.example.com/'
```

The result:

* Requests per second: 146.86 [#/sec] (mean)
* Time per request: 68.091 [ms] (mean)
* Time per request: 6.809 [ms] (mean, across all concurrent requests)

## HTTP cache

Compared to [Apache2](https://httpd.apache.org/), nginx performs better at
serving static files and when under high traffic ([see why](https://www.nginx.com/blog/nginx-vs-apache-our-view/)).

But our main interest here is in nginx's HTTP caching features.

Applications built with HTTP frameworks (e.g. Symfony) benefit from the HTTP cache
specification, all they need is to add some headers to their response:

* `Cache-Control: max-age=60` will ask *caches* to keep a copy for 60 seconds after receiving the response
* `Expires: Fri, 30 Oct 1998 14:19:41 GMT` will ask *caches* to keep a copy of the response until the given date
* `Last-Modified: Tue, 8 Sep 2015 13:35:23 GMT` allows *caches* to keep a copy and check later in the background if there's a more recent "last modified" date
* `Etag: a3e455afd` allows *caches* to keep a copy and check later in the background if there's a different "etag" (*e*ntity *tag*)

> **Note**: For more information about those headers, check this [HTTP cache article](/2015/11/26/http-cache.html).

Since nginx sits between clients (e.g. browsers) and the application, it can act
as the *cache*:

* if the request doesn't match any copies, ask the application to create a response and make a copy of it (that's a MISS scenario)
* if the request matches a fresh copy return it, the application does nothing here (that's a HIT scenario)
* if the request matches a stale copy return it, and in the background ask the application to create a response to replace the copy with a fresh one (that's an UPDATING scenario, only if configured)

It can even serve stale data when the application is failing (e.g. 500 errors)!

To make use of this feature, we first need to set up nginx:

```
# /etc/nginx/nginx.conf

# ...

http {
    proxy_cache_path /home/foobar/super-speed-nginx/var/nginx levels=1:2 keys_zone=super-speed-nginx:10m max_size=10g inactive=60m use_temp_path=off;

    # ...
}
```

> **Note**:
>
> * `levels`: sets up the directory depth in the cache folder, `2` is recommended
>   as putting all files in one directory could slow it down
> * `keys_zone`: sets up an in memory store for cache keys, to avoid avoid fetching
>   them from the disk (cache name associated to the memory size to use)
> * `max-size`: sets up the maximum disk size of the cache, when this limit is
    reached least used copies are removed
> * `inactive`: sets up the time after which an unused copy can be removed
> * `use_temp_path`: enables / disables writing cached copies to a temporary path
>   before they're moved to the permanent one, `off` is recommended to avoid
>   unecessary filesystem operations

Then we need to edit the virtual host by changing the port from `80` to something
else (e.g. `8042`) and add a "cache server" in front of it (the cache server will
listen to port `80`, it's the one exposed to clients):

```
# /etc/nginx/sites-available/super-speed-nginx
server {
    listen 80;
    server_name super-speed-nginx.example.com;

    location / {
        proxy_pass http://super-speed-nginx.example.com:8042;

        proxy_cache super-speed-nginx;
        proxy_cache_key "$scheme://$host$request_uri";
        proxy_cache_lock on;
        proxy_cache_use_stale updating error timeout http_500 http_502 http_503 http_504;
        add_header X-Cache $upstream_cache_status;
    }

    # Keep your nginx logs with the symfony ones
    error_log /home/foobar/super-speed-nginx/var/logs/nginx_cache_error.log;
    access_log /home/foobar/super-speed-nginx/var/logs/nginx_cache_access.log;
}

server {
    listen 8042;
    server_name super-speed-nginx.example.com;
    root /home/foobar/super-speed-nginx/web;

    location / {
        # try to serve file directly, fallback to app.php
        try_files $uri /app.php$is_args$args;
    }

    location ~ ^/app\.php(/|$) {
        fastcgi_pass unix:/run/php/php7.0-fpm.sock;
        fastcgi_split_path_info ^(.+\.php)(/.*)$;
        include fastcgi_params;
        fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;

        # Prevents URIs that include the front controller. This will 404:
        # http://domain.tld/app.php/some-path
        # Remove the internal directive to allow URIs like this
        internal;
    }

    # Keep your nginx logs with the symfony ones
    error_log /home/foobar/super-speed-nginx/var/logs/nginx_error.log;
    access_log /home/foobar/super-speed-nginx/var/logs/nginx_access.log;
}
```

> **Note**:
>
> * `proxy_pass`: the address of the server we'd like to forward the requests to
> * `proxy_cache`: sets up the name of the cache, it echoes the one used in `keys_zone`
> * `proxy_cache_key`: key used to store the copy (the result is converted to md5)
> * `proxy_cache_lock`: enables / disables concurent cache writing for a given key
> * `proxy_cache_use_stale`: sets up usage of a stale copy
>   - `updating` when the copy is being refreshed
>   - `error`, `timeout`, `http_5**` when the application fails
> * `add_header`: adds a header to the HTTP Response
>   (e.g. the value of `$upstream_cache_status` which could be `MISS`, `HIT`, `EXPIRED`, etc)

Now it's the turn of our application. By default Symfony set a
`Cache-Control: no-cache` header to all responses. Let's change it:

```php
<?php
// src/AppBundle/Controller/DefaultController.php

namespace AppBundle\Controller;

use Sensio\Bundle\FrameworkExtraBundle\Configuration\Cache;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use Symfony\Component\HttpFoundation\Request;

class DefaultController extends Controller
{
    /**
     * @Route("/", name="homepage")
     * @Cache(maxage="20", public=true)
     */
    public function indexAction(Request $request)
    {
        // replace this example code with whatever you need
        return $this->render('default/index.html.twig', [
            'base_dir' => realpath($this->getParameter('kernel.root_dir').'/..'),
        ]);
    }
}
```

To apply those changes, restart nginx and clear symfony cache:

```
sudo service nginx restart
bin/console cache:clear -e=prod --no-debug
```

Now we can check the Response's headers:

```
curl -I 'http://super-speed-nginx.example.com/'
curl -I 'http://super-speed-nginx.example.com/'
```

The first one should contain a `X-Cache` header set to `MISS`, while the second
one should be set to `HIT`.

Let's have a quick benchmark:

```
curl 'http://super-speed-nginx.example.com/'
ab -t 10 -c 10 'http://super-speed-nginx.example.com/'
```

The result:

* Requests per second: 21994.33 [#/sec] (mean)
* Time per request: 0.455 [ms] (mean)
* Time per request: 0.045 [ms] (mean, across all concurrent requests)

That's around **140** times faster than without cache.

## Load balancing

In the above examples, we've seen some usage of `proxy_pass` in nginx. It allows
the proxy to forward the request to an "upstream" server (e.g. PHP-FPM).

By providing many upstream servers for one `proxy_pass`, we enable nginx's load
balancing which can be useful with the ReactPHP set up from the previous article
for example:

```
# /etc/nginx/sites-available/super-speed-nginx
upstream backend  {
    server 127.0.0.1:5500 max_fails=1 fail_timeout=5s;
    server 127.0.0.1:5501 max_fails=1 fail_timeout=5s;
    server 127.0.0.1:5502 max_fails=1 fail_timeout=5s;
    server 127.0.0.1:5503 max_fails=1 fail_timeout=5s;
}

server {
    root /home/foobar/bench-sf-standard/web/;
    server_name localhost;

    location / {
        try_files $uri @backend;
    }

    location @backend {
        proxy_pass http://backend;
        proxy_next_upstream http_502 timeout error;
        proxy_connect_timeout 1;
        proxy_send_timeout 5;
        proxy_read_timeout 5;
    }
}
```

> **Note**:
>
> * `proxy_next_upstream`: conditions to satisfy in order to forward the request to another server (here errors and timeouts)
> * `proxy_connect_timeout`: maximum time when trying to connect to an upstream server
> * `proxy_send_timeout`: maximum time when trying to send data to an upstream server
> * `proxy_read_timeout`: maximum time when trying to read data from an upstream server

## Conclusion

With a reverse proxy such as nginx, we can decrease the number of calls to our
applications by:

* enabling HTTP caching (add a HTTP header to responses, use ~50 lines of configuration)
* enabling load balancing (use ~30 lines of configuration)

This results in a drastic reduction of response time from the point of view of
the client.

Resources:

* [nginx, PHP FastCGI Example](https://www.nginx.com/resources/wiki/start/topics/examples/phpfcgi/)
* [nginx a guide to caching](https://www.nginx.com/blog/nginx-caching-guide/)
* [The Benefits of Microcaching with nginx](https://www.nginx.com/blog/benefits-of-microcaching-nginx/)
* [Varnish or nginx?](https://speakerdeck.com/thijsferyn/varnish-or-nginx-symfony-live)
