---
layout: post
title: Pomm Foundation
tags:
    - introducing library
    - pomm
---

[Pomm](http://www.pomm-project.org/) is an interresting alternative to Doctrine
([DBAL](http://docs.doctrine-project.org/projects/doctrine-dbal/en/latest/reference/introduction.html)
or [ORM](http://docs.doctrine-project.org/projects/doctrine-orm/en/latest/tutorials/getting-started.html)), it specializes in one database vendor: [PostgreSQL](http://www.postgresql.org/docs/9.4/static/intro-whatis.html).

In this article we'll quickly have a look at [Pomm Foundation](https://github.com/pomm-project/Foundation#foundation).

## Installation

Pomm can be installed using [Composer](https://getcomposer.org/download/):

    composer require pomm-project/foundation:^2.0@rc

Then we need to create a `QueryManager`:

```php
<?php

require __DIR__.'/vendor/autoload.php';

$pomm = new PommProject\Foundation\Pomm(
    'database_name' => array(
        'dsn' => 'pgsql://database_user:database_pass@database_host:database_port/database_name',
        'class:session_builder' => '\PommProject\Foundation\SessionBuilder',
    ),
);

/**
 * @var PommProject\Foundation\QueryManager\QueryManagerInterface
 */
$queryManager = $pomm->getDefaultSession()->getQueryManager();
```

## Usage

The `QueryManager` allows us to send query to our database:

```php
$items = $queryManager->query('SELECT * FROM item WHERE name = $1 AND description = $2', array(
    'Arthur Dent',
    'Nobody expects the Spanish Inquisition!',
));
```

> **Note**: [Named parameters are not supported](https://twitter.com/mvrhov/status/573098943321653248).

The returned value is an iterator, each element is a row (an associative array):

```php
foreach ($items as $item) {
    echo $item['description'];
}
```

If you'd rather get all elements as an array, you can use `iterator_to_array`:

```php
$arrayItems = iterator_to_array($items);
```

> **Note**: Behind the scene the result is stored in a `resource`, which is usually more efficient than a PHP array.
> The iterator allows to get the rows from the `resource` one by one, which can save memory.

## Conclusion

Pomm Foundation provides an efficient abstraction over `pg_*` functions.

In comparison Doctrine DBAL uses `PDO` and tries to abstract vendor features,
so if you're using PostgresSQL and don't need an ORM, you can give it a try!
