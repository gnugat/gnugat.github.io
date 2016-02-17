---
layout: post
title: Symfony / Web Services - part 1: Introduction
tags:
    - symfony
    - symfony / web services series
---

Welcome to this new series of articles on managing Web Services in a
[Symfony](https://symfony.com) environment. Its purpose is to provide an example,
it doesn't pretend to be the best solution and it requires you to know the basics
of Symfony (if you know what a service is, you're good) and of web services
(basically to know that they're a way to provide data remotely).

> **Spoiler alert**: There won't be much Symfony specific code ;) .

In this post we'll describe the different endpoints of the (fake) web service
which will be used as a reference thoughout the whole series:

* [JSON objects](#json-objects)
* [Authentication](#authentication)
* [Create a profile](#create-a-profile)
* [Delete a profile](#delete-a-profile)
* [Conclusion](#conclusion)

## JSON objects

The posted and returned resources will always be wrapped in a JSON object.

## Authentication

All endpoints require HTTP Basic Authentication with the following credentials:

* user: `spanish_inquisition`
* password: `NobodyExpectsIt!`

If those credentials are missing or wrong (`403 FORBIDDEN`), it will return:

```
{
    "error": "The credentials are either missing or incorrect"
}
```

## Create a profile

* `POST http://ws.local/api/v1/profiles`

The request body should be as follow:

```
{
    "name": "Fawlty Tower"
}
```

In case of success (`201 CREATED`), it will return:

```
{
    "id": 23,
    "name": "Fawlty Tower"
}
```

If the request's body contains malformed JSON (`400 BAD REQUEST`), it will return:

```
{
    "error": "Invalid or malformed JSON"
}
```

If the `name` parameter is missing from the request's body (`422 UNPROCESSABLE ENTITY`),
it will return:

```
{
    "error": "The \"name\" parameter is missing from the request's body"
}
```

If the name already exists (`422 UNPROCESSABLE ENTITY`), it will return:

```
{
    "error": "The name \"Provençal le Gaulois\" is already taken"
}
```

## Delete a profile

* `DELETE http://ws.local/api/v1/profiles/{id}`

This endpoint will always return an empty body (`204 NO CONTENT`).

## Conclusion

So basically we can create and remove profiles, which have an identifier and a name.

In [the next article](/2015/01/21/sf-ws-part-2-1-creation-bootstrap.html)
we'll see how to build such web service.
