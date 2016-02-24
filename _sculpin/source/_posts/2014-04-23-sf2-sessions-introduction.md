---
layout: post
title: Symfony Sessions introduction
tags:
    - symfony
    - introducing library
    - reference
---

> **Reference**: This article is intended to be as complete as possible and is
> kept up to date.

> *Last reviewed*: 22/02/2016.

[TL;DR: jump to the conclusion](#conclusion).

The [Symfony HttpFoundation component](http://symfony.com/doc/current/components/http_foundation/introduction.html)
is a library which provides an Object Oriented implementation of the HTTP
protocol: it wraps PHP's variable superglobals (`$_POST`, `$_GET`, `$_SERVER`,
etc) inside objects (`Request`, `Response`, `Session`, etc).

The idea behind it: web applications should receive a Request and return a
Response.

In this article, we'll focus on the Session management which solves many issues
(for example the [PHP session already started error](https://www.google.com/search?q=php+session+already+started+error)
nightmare).

This introduction will show you how to use it in a "non-symfony" project:

1. [Basics](#basics)
2. [Examples](#examples)
    * [Simple attributes](#simple-attributes)
    * [Deep attributes](#deep-attributes)
3. [Going further](#going-further)
    * [Root attributes](#root-attributes)
    * [Documentation](#documentation)
    * [Troubleshooting](#troubleshooting)

## Basics

In almost any cases, you'll only deal with the following three methods of the
`Session` object:

```php
<?php

namespace Symfony\Component\HttpFoundation\Session;

use Symfony\Component\HttpFoundation\Session\SessionBagInterface;

class Session implements SessionInterface, \IteratorAggregate, \Countable
{
    public function registerBag(SessionBagInterface $bag);
    public function start();
    public function getBag($name);
}
```

A `Bag` is a group of attributes stored in the session. Again, in most cases
you'll only deal with the following four methods of the `AttributeBag` object:

```php
<?php

namespace Symfony\Component\HttpFoundation\Session\Attribute;

class AttributeBag implements AttributeBagInterface, \IteratorAggregate, \Countable
{
    public function __construct($storageKey = '_sf2_attributes');
    public function setName($name);
    public function get($name, $default = null);
    public function set($name, $value);
}
```

When using the sessions, you'll generally need to bootstrap things up as follows:

```php
<?php

$session = new Session();

$myAttributeBag = new AttributeBag('my_storage_key');
$myAttributeBag->setName('some_descriptive_name');
$session->registerBag($myAttributeBag);

$session->start();
```

The session **MUST** be started by Symfony, and it *SHOULD* be started after
the bag registrations.

## Examples

Here's some code samples to make things clear.

### Simple attributes

Let's assume that our session looks like this:

```php
<?php

$_SESSION = array(
    'user' => array(
        'first_name' => 'Arthur',
        'last_name' => 'Dent',
    ),
);
```

Here's the bootstrap code we need:

```php
<?php

$session = new Session();

$userAttributeBag = new AttributeBag('user');
$session->registerBag($userAttributeBag);

$session->start();
```

The equivalent to:

```php
<?php

$firstName = 'Ford';
if (isset($_SESSION['user']['first_name'])) {
    $firstName = $_SESSION['user']['first_name'];
}
$_SESSION['user']['last_name'] = 'Prefect';
```

Would be:

```php
<?php

$userAttributeBag = $session->getBag('user');

$firstName = $userAttributeBag->get('first_name', 'Ford');
$userAttributeBag->set('last_name', 'Prefect');
```

### Deep attributes

Now, let's assume we have a session which has deep attributes:

```php
<?php

$_SESSION = array(
    'authentication' => array(
        'tokens' => array(
            'github' => 'A45E96F',
            'twitter' => '11AEBC980D456E4EF',
        ),
    ),
);
```

Here's the bootstrap code we need:

```php
<?php

$session = new Session();

$authenticationAttributeBag = new NamespacedAttributeBag('authentication');
$session->registerBag($authenticationAttributeBag);

$session->start();
```

The equivalent to:

```php
<?php

$_SESSION['authentication']['tokens']['github'] = 'AEB558F02C3B346';
```

Would be:

```php
<?php

$authenticationAttributeBag = $session->getBag($authenticationAttributeBag);

$authenticationAttributeBag->set('tokens/github', 'AEB558F02C3B346');
```

## Going further

The `Session` has been designed to contain a group of attribute bags. But when
working with legacy sessions, you might have to access attributes which are
located at the root of the session. Here's how to extend the `Session` to allow
this.

### Root attributes

A root attribute might look like:

```php
<?php

$_SESSION = array(
    'attribute' => 'value',
);
```

You need to create your own kind of `Bag`:

```php
<?php

namespace Acme\Session;

use Symfony\Component\HttpFoundation\Session\SessionBagInterface;

class RootAttributeBag implements SessionBagInterface
{
    private $name = 'single_attribute';

    /** @var string */
    private $storageKey;

    /** @var mixed */
    private $attribute;

    public function __construct($storageKey)
    {
        $this->storageKey = $storageKey;
    }

    /** {@inheritdoc} */
    public function getName()
    {
        return $this->name;
    }

    public function setName($name)
    {
        $this->name = $name;
    }

    /** {@inheritdoc} */
    public function initialize(array &$array)
    {
        $attribute = !empty($array) ? $array[0] : null;
        $this->attribute = &$attribute;
    }

    /** {@inheritdoc} */
    public function getStorageKey()
    {
        return $this->storageKey;
    }

    /** {@inheritdoc} */
    public function clear()
    {
        $this->attribute = null;
    }

    public function get()
    {
        return $this->attribute;
    }

    public function set($value)
    {
        $this->attribute = $value;
    }
}
```

The `storage key` will be directly the attribute's key.

We also need to hack a `Storage` class which supports our `Bag`:

```php
<?php

namespace Acme\Session;

use Symfony\Component\HttpFoundation\Session\Storage\NativeSessionStorage;

class LegacySessionStorage extends NativeSessionStorage
{
    /** {@inheritdoc} */
    protected function loadSession(array &$session = null)
    {
        if (null === $session) {
            $session = &$_SESSION;
        }

        $bags = array_merge($this->bags, array($this->metadataBag));

        foreach ($bags as $bag) {
            $key = $bag->getStorageKey();
            // We cast $_SESSION[$key] to an array, because of the SessionBagInterface::initialize() signature
            $session[$key] = isset($session[$key]) ? (array) $session[$key] : array();
            $bag->initialize($session[$key]);
        }

        $this->started = true;
        $this->closed = false;
    }
}
```

Finally, we'll need the following bootstrap code:

```php
<?php

use Acme\Session\LegacySessionStorage;
use Acme\Session\RootAttributeBag;
use Symfony\Component\HttpFoundation\Session\Session;

$sessionStorage = new LegacySessionStorage();
$session = new Session($sessionStorage);

// before: $_SESSION['attribute']
$legacyBag = new RootAttributeBag('attribute');
$legacyBag->setName('legacy');

// after: $session->getBag('legacy')->get()
$session->registerBag($legacyBag);
```

### Documentation

[The official documentation](http://symfony.com/doc/current/components/http_foundation/sessions.html)
provides useful information about how the session use it.
For example it explains [how to manage flash messages](http://symfony.com/doc/current/components/http_foundation/sessions.html#flash-messages).

It also explains [how the session works behind the scene](http://symfony.com/doc/current/components/http_foundation/session_configuration.html)
with useful tips on how to write the session in a database.

[Some cookbooks](http://symfony.com/doc/current/cookbook/session/index.html) are
also available.
You can find for instance one describing how to use
[session proxy](http://symfony.com/doc/current/cookbook/session/proxy_examples.html)
which is useful if you want to encrypt the session data or to make it read
only.

### Troubleshooting

The common cases of problems encountered are due to the fact that the session
was started before Symfony2 did.

To fix this, check in your `php.ini` that the `session.auto_start` option is set
to `0` (its default value).

If the session isn't auto started, it means that the application is starting the
session itself. If you cannot prevent this, use
[`PhpBridgeSessionStorage`](https://github.com/symfony/HttpFoundation/blob/master/Session/Storage/PhpBridgeSessionStorage.php)
with
[`NativeFileSessionHandler`](https://github.com/symfony/HttpFoundation/blob/master/Session/Storage/Handler/NativeFileSessionHandler.php):

```php
<?php

use Symfony\Component\HttpFoundation\Session\Session;
use Symfony\Component\HttpFoundation\Session\Storage\Handler\NativeFileSessionHandler;
use Symfony\Component\HttpFoundation\Session\Storage\PhpBridgeSessionStorage;

$sessionHandler = new NativeFileSessionHandler();
$sessionStorage = new PhpBridgeSessionStorage($sessionHandler);
$session = new Session($sessionStorage);
```

Another trouble you can encounter: you register some bags but they're always
empty, even though the `$_SESSION` contains the targeted values.
This would be because you register your bags after starting the session: if you
can't do otherwise then simply call `$session->migrate()` after your bag
registration, this will reload the values.

Finally when doing AJAX request you might notice slow performances, or non
persistence of the data. This might be caused by a
[session locking mechanism](http://blog.alterphp.com/2012/08/how-to-deal-with-asynchronous-request.html)
which can be solved like this by saving manually the session:

```php
<?php

$session->save();
// session_write_close(); // Only required before Symfony 2.1
```

## Conclusion

By wrapping `$_SESSION` and `session_*()` functions, `Session` allows you to
make your code more testable
([you can mock it](http://symfony.com/doc/current/components/http_foundation/session_testing.html))
and to solve starting session issues (just make sure to be the first to start
it).

It's divided into `AttributeBag` which are arrays of parameters: this allows you
to organize your session by namespaces.

I hope you found some useful tips in this article, if you have any comments or
questions don't be shy and drop me a line on
[Twitter](https://twitter.com/epiloic).
