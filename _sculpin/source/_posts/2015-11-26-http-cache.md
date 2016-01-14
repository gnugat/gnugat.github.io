---
layout: post
title: HTTP Cache
tags:
    - http
---

> **TL;DR**: Enable HTTP cache by setting one of the following header in your Responses:
> `Cache-Control`, `Expires`, `Last-Modified` or `Etag`.

The HTTP protocol specifies how to cache Responses:

![sequence diagram](http://www.websequencediagrams.com/cgi-bin/cdraw?lz=SFRUUCBHYXRld2F5IENhY2hlCgpDbGllbnQtPgAKBTogUmVxdWVzdAoAGQUtPlNlcnZlcjogRm9yd2FyZGVkIHIAGgcAFAYALQtzcG9uc2UAMQgAUQYAKw4AGggAZA5TYW1lAE0JAC8PAIEfBQAwCw&s=napkin)

The following actors are involved:

* client, usually a browser or a SDK
* reverse proxy (cache application), could be one (or even many) of:
    * [nginx](http://nginx.org/en/)
    * [Varnish](https://www.varnish-cache.org/)
    * a CDN like [cloudfront](https://aws.amazon.com/cloudfront/)
    * `AppCache` embed in [Symfony](http://symfony.com/doc/current/book/http_cache.html#symfony-reverse-proxy)
* application

Its advantages:

* standard and widely adopted (highly documented on the web)
* simple to set up (just add HTTP headers to Responses)
* improves the number of Request per second (avoids calling the dynamic logic)

Its drawbacks:

* requires an extra application (the Reverse Proxy)
* does not reduce network calls from a Client point of view
* needs more thinking (choose a strategy)

## Cacheable Response

A Response can be cached if the incoming Request complies to the following rules:

* it has a `GET` or `HEAD` method
* its URI is the same (that includes query parameters)
* its headers listed in `Vary` are the same
* it doesn't have a `Authorization` header

For example, the following Request can produce cacheable Responses:

```
GET /v1/items?page=1
Accept: application/json
Vary: Accept
```

Sending the following Request would produce a different cacheable Response:

```
GET /v1/items?page=1
Accept: text/html
Vary: Accept
```

To be cacheable, a Response should also have one of the headers described in the
next section.

> **Note**: Headers specified in `Vary` will have their value stored in the
> Reverse Proxy. Sensitive data (e.g. API keys, password, etc) shouldn't be used
> as a cache key.

## Strategies

HTTP cache provides the possibility to choose different strategies:

* Expiration (timeout or expiration date)
* Validation (modification date or hash comparison)

### Expiration

If a Response can be safely cached for a fixed period of time (e.g. 10 minutes),
use `Cache-Control` HTTP Header:

```
HTTP/1.1 200 OK
Cache-Control: max-age=600
Content-Type: application/json

{"id":42,"name":"Arthur Dent"}
```

> **Note**: the Reverse Proxy will add a header to the Response indicating its age:
>
> ```
> HTTP/1.1 200 OK
> Age: 23
> Cache-Control: max-age=600
> Content-Type: application/json
>
> {"id":42,"name":"Arthur Dent"}
> ```

If a Response can be safely cached until a known date (e.g. the 30th of October 1998,
at 2:19pm), use `Expires` HTTP Header:

```
HTTP/1.1 200 OK
Expires: Fri, 30 Oct 1998 14:19:41 GMT
Content-Type: application/json

{"id":42,"name":"Arthur Dent"}
```

> **Note**: the HTTP date format is required.

### Validation

The Reverse Proxy can serve stale cached copy and then asynchronously check with
the Application if it needs to be refreshed, using `Last-Modified` (a date) or/and
`ETag` (a hash) HTTP Headers:

```
HTTP/1.1 200 OK
Last-Modified: Tue, 8 Sep 2015 13:35:23 GMT
ETag: a3e455afd
Content-Type: application/json

{"id":42,"name":"Arthur Dent"}
```

> **Note**: the Reverse Proxy will add a header to requests with `If-Modified-Since`
>(a date) or/and `If-None-Match` (a hash):
>
> ```
> GET /v1/users/42 HTTP/1.1
> If-Modified-Since: Tue, 8 Sep 2015 13:35:23 GMT
> If-None-Match: a3e455afd
> Accept: application/json
> ```
>
> If the Response shouldn't be updated, the Server should return a `304 Not Modified`
> Response.

## Cheatsheet

### Cache-Control values

Keep in mind that `Cache-Control` header can be used by both the Reverse Proxy
and the Client (e.g. a browser) to cache the Response.

* `max-age=[seconds]`: How long the Response should be cached
* `s-maxage=[seconds]`: Same as max-age but for Reverse Proxy only
* `private`: Only the Client can cache (default for authenticated Responses)
* `public`: Proxy can also cache (for authenticated Responses)
* `no-cache`: Refresh the cached copy (but still caches it)
* `no-store`: Response should not be cached anywhere (e.g. because it contains sensitive data)
* `must-revalidate`: Refresh the cached copy if it is stale
* `proxy-revalidate`: Same as must-revalidate but for Reverse Proxy only

### HTTP date format

The date MUST be represented in Greenwich Mean Time (GMT), with the following format: `D, d M Y H:i:s GMT`

* `D`: A textual representation of a day, three letters (`Mon` to `Sun`)
* `d`: Day of the month, 2 digits with leading zeros (`01` to `31`)
* `M`: A short textual representation of a month, three letters (`Jan` to `Dec`)
* `Y`: A full numeric representation of a year, 4 digits (e.g. `1999`, `2003`)
* `H`: 24-hour format of an hour with leading zeros (`00` to `23`)
* `i`: Minutes with leading zeros (`00` to `59`)
* `s`: Seconds, with leading zeros (`00` to `59`)

## Conclusion

The `Expires` header is usually used to cache responses for application which are
updated on a regular date (synchronization with a source of the data).

The `Last-Modified` header is used when the data has an `updated_at` field we can
rely on.

The `Etag` header is used when we can safely create a hash of the response and compare
it with with the cached copy.

> **Note**: With `Last-Modified` and `Etag`, the Reverse Proxy serves first the
> cached Reponse and then check asynchronously with the application if it is stale.

Finally the `Cache-Control` header is usually used in any other situation.

More readings about HTTP Cache can be found here:

* [HTTP 1.1 (RFC 2616), caching chapter](http://www.w3.org/Protocols/rfc2616/rfc2616-sec13.html#sec13)
* [Things caches do](http://2ndscale.com/rtomayko/2008/things-caches-do)
* [Caching tutorial](https://www.mnot.net/cache_docs/)
