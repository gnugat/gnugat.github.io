---
layout: post
title: Symfony Differently - part 1: Introduction
tags:
    - Symfony
    - Symfony Differently
---

[Symfony](https://symfony.com) is an amazing HTTP framework which powers
[high traffic websites](http://labs.octivi.com/handling-1-billion-requests-a-week-with-symfony2/).
Performance shouldn't be a concern when first creating a website, because between
the time it is launched and the time it actually has a high traffic many things
that we didn't expect in the first days will happen:

* requirements will change
* user behavior will change
* even the team can change

Optimizing applications has an impact over maintenance, and making it harder to change
right from the begining might not be the best option. However when the need of performance
actually arises, we need to tackle it.

This series of articles is about this specific moment, and how to tackle it in a pragmatic way.

> **Spoiler Alert**: It will feature a section where we optimize our application step by step,
> with a monitoring of the impact on performance. We'll see that those don't make a big
> difference, which is why those concerns shouldn't be addressed from day 1.

First, let's have a look at the big picture. Please note that the approach we use
here is only one amongst many (every need is different, it might not be the best in every situations).

## The project

For our examples, we'll pretend to be the Acme Company which powers half the planet
in almost every aspect of our lives. Performance isn't just a concern, it has become
a reality.

> **Note**: Those examples are all made up, but they're based on real experience.

We've analysed our market and we'd like to have the following new feature:

    As a customer, I'd like to buy an item

During a meeting, we've come up with the following example:

    Given a "fruit" category
    When I pick a "banana"
    Then it should be ordered

## The team

In the first days of Acme, we only had a few developers which were full stack. It
worked quite well but we've grown so much that we had to recruit more specialized
profiles with a frontend team and an API one: it allowed us to parallelize the work.

## The architecture

Frontend applications that live in the customer's browser have been chosen because:

* they are extremely responsive
* they provide a richer User eXperience
* they have a lower server consumption

In the early days of Acme there was a single big application, but with the number
of customer growing and asking features specific to their need, it failed us hard
costing us Money, Customers and Developers.
Now each frontend applications talk to a dedicated API.

The dedicated APIs mix and match data coming from another layer of specific APIs.
Those basically provide Create Read Update Delete and Search (CRUDS) access to
their own data storage.

> **Note**: We've decided to have two layers of APIs in order to avoid mixing
> features specific to a customer in an endpoint used by everyone.

From the Use Stories, we've identified two types of data: `item` related ones
and `order` related one.
We've decided to create the following applications:

* `acme/order-items-front`, the frontend application
* `acme/order-items-api` the dedicated API
* `acme/items`, an API specific to the `item` and `item_category` tables
* `acme/orders`, an API specific to the `order` table

![Diagram](http://yuml.me/c0591d90)

In this series, we'll focus on the creation of the Search endpoint in `acme/items`.

## The task

The Search endpoint should allow:

* pagination of items, using `page` and `per_page` parameters
* filtering of items, using column name with value for parameters
* ordering items, using a `sort` parameter

In this series, we'll focus on paginating items.

Here's a valid `Request` sample:

```
GET /v1/items?page=2&per_page=1 HTTP/1.1
```

It should return a `Response` similar to:

```
HTTP/1.1 200 OK
Content-Type: application/json

{"data":[{"id":42,"name":"banana","category_id":23}],"page":{"current_page":2,"per_page":1,"total_elements":2,"total_pages":2}}
```

## Conclusion

Our Acme mega corporation needs a new feature and we've decided to implement it
by creating a frontend, its dedicated API which mix and match data coming from two
new specific APIs.

The choice of this architecture has been made because it solved issues encountered
in Acme's past, when we had a single big application.

In the next article we'll bootstrap a Symfony application to create an endpoint to search
for items.

In the mean time if you're interrested in creating APIs in a pragmatic way you can
read [the following article](http://www.vinaysahni.com/best-practices-for-a-pragmatic-restful-api).
If you're wondering why Acme didn't use this approach from the begining you might
want to read [the following article](http://martinfowler.com/bliki/MonolithFirst.html).
