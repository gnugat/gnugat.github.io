---
layout: post
title: Towards CQRS, Search Engine
tags:
    - cqrs
    - porpaginas
---

> **TL;DR**: A `Search Engine` component can help you get the CQRS "Query" part right.

The [Command / Query Responsibility Segregation](http://martinfowler.com/bliki/CQRS.html)
(CQRS) principle states that "write" and "read" logic should be separated.
For example a single "Publisher" server (write) with many "Subscribers" servers
(read) is a macro example of applying this principle, and an API that defines
a read endpoint free from write side effects is a micro example of applying it.

Because it's hard to go from a regular mindset to a CQRS one, we've seen in the
last article how we can use [the Command Bus pattern](/2016/05/11/towards-cqrs-command-bus.html)
to help us get the Command part right.

The "Query" equivalent of the Command Bus would be the [Repository design pattern](http://code.tutsplus.com/tutorials/the-repository-design-pattern--net-35804).

> **Note**: Here's some nice articles about this pattern:
>
> * [Gateway](http://martinfowler.com/eaaCatalog/gateway.html)
> * [Refactoring code that accesses external services](http://mnapoli.fr/repository-interface/)
> * [The Repository interface](http://martinfowler.com/articles/refactoring-external-service.html)
> * [The Collection interface and Database abstraction](http://mnapoli.fr/collection-interface-and-database-abstraction/)

However repositories can grow into an object containing many methods like
`findByName`, `findAllInDescendingOrder`, `findByNameInDescendingOrder`, etc.
To avoid this, we can combine it with the [Specification design pattern](https://en.wikipedia.org/wiki/Specification_pattern):
our Repository would only have one single `search` method taking a Criteria object
that describes our query parameters.

> **Note**: For more articles on the topic, see:
>
> * [Taiming repository classes in Doctrine with the QueryBuilder](http://dev.imagineeasy.com/post/44139111915/taiming-repository-classes-in-doctrine-with-the)
> * [On Taming Repository Classes in Doctrine](http://www.whitewashing.de/2013/03/04/doctrine_repositories.html)
> * [On Taming Repository Classes in Doctrine… Among other things](http://blog.kevingomez.fr/2015/02/07/on-taming-repository-classes-in-doctrine-among-other-things/)
> * [RulerZ, specifications and Symfony are in a boat](http://blog.kevingomez.fr/2015/03/14/rulerz-specifications-and-symfony-are-in-a-boat/)

In this article, we'll build a private "Search Engine" component to help us get
the Query part right.

## Requirements

All projects are different, and while the feature described here might have some
similarity with other projects requirements, there's a big chance that creating
a single common library might prove too hard.

So instead we'll create a "private" Component for our project: it's going to be
decoupled, allowing it to become a library on its own just in the unlikely event
it turns out to be the "Universal Search Engine Component".

Our requirements will be the following: we need to create an endpoint that allows
us to search "profiles", with the following features:

* it has to be paginated (default page = `1`, default number of profiles per page = `10`)
* it has to be ordered (default field = `name`, default direction = `ASC`)
* it can be filtered

Here's a HTTP Request example:

```
GET /v1/profiles?name=marvin&page=42&per_page=23&sort=-name HTTP/1.1
Accept: application/json
```

> **Note**: `sort`'s value can be either `name` (the default) or `-name`
> (changes the direction to be descending).

And here's a HTTP Response example:

```
HTTP/1.1 200 OK
Content-Type: application/json

{
    "items": [
        {
            "name": "Arthur Dent"
        },
        {
            "name": "Ford Prefect"
        },
        {
            "name": "Trillian Astra"
        }
    ],
    "page": {
        "current_page": 1,
        "per_page": 10,
        "total_elements": 3,
        "total_pages": 1
    }
}
```

## The Search Engine component

In order to satisfy the above requirements, we need to create a flexible
Search Engine component that can accept any of those parameters. That can be done
in one interface and a few (4) value objects.

First, we can have a `SearchEngine` interface:

```php
<?php

namespace AppBundle\Search;

use Porpaginas\Result;

interface SearchEngine
{
    public function match(Criteria $criteria) : Result;
}
```

> **Note**: We're using [porpaginas](https://github.com/beberlei/porpaginas),
> a  library that makes paginated result a breeze to handle.
> [Find out more about it here](/2015/11/05/porpaginas.html).

A `Criteria` is a value object, composed of:

* a resource name (e.g. `profile`)
* a `Paginating` value object
* an `Ordering` value object
* a `Filtering` value object

It can be constructed using the query parameters:

```php
<?php

namespace AppBundle\Search;

use AppBundle\Search\Criteria\Filtering;
use AppBundle\Search\Criteria\Ordering;
use AppBundle\Search\Criteria\Paginating;

class Criteria
{
    public $resourceName;
    public $filtering;
    public $ordering;
    public $paginating;

    public function __construct(
        string $resourceName,
        Filtering $filtering,
        Ordering $ordering,
        Paginating $paginating
    ) {
        $this->resourceName = $resourceName;
        $this->filtering = $filtering;
        $this->ordering = $ordering;
        $this->paginating = $paginating;
    }

    public static function fromQueryParameters(string $resourceName, array $queryParameters) : self
    {
        return new self(
            $resourceName,
            Filtering::fromQueryParameters($queryParameters),
            Ordering::fromQueryParameters($queryParameters),
            Paginating::fromQueryParameters($queryParameters)
        );
    }
}
```

The `Paginating` value object takes care of the `page` parameter (e.g. `1`) and
the `per_page` parameter (e.g. `10`):

```php
<?php

namespace AppBundle\Search\Criteria;

class Paginating
{
    const DEFAULT_CURRENT_PAGE = 1;
    const DEFAULT_ITEMS_PER_PAGE = 10;

    public $currentPage;
    public $itemsPerPage;
    public $offset;

    public function __construct(int $currentPage, int $itemsPerPage)
    {
        $this->currentPage = $currentPage;
        if ($this->currentPage <= 0) {
            $this->currentPage = self::DEFAULT_CURRENT_PAGE;
        }
        $this->itemsPerPage = $itemsPerPage;
        if ($this->itemsPerPage <= 0) {
            $this->itemsPerPage = self::DEFAULT_ITEMS_PER_PAGE;
        }
        $this->offset = $this->currentPage * $this->itemsPerPage - $this->itemsPerPage;
    }

    public static function fromQueryParameters(array $queryParameters) : self
    {
        $currentPage = $queryParameters['page'] ?? self::DEFAULT_CURRENT_PAGE;
        $maximumResults = $queryParameters['per_page'] ?? self::DEFAULT_ITEMS_PER_PAGE;

        return new self($currentPage, $maximumResults);
    }
}
```

The `Ordering` value object takes care of the `sort` parameter (e.g. `-name`):

```php
<?php

namespace AppBundle\Search\Criteria;

class Ordering
{
    const DEFAULT_FIELD = 'name';
    const DEFAULT_DIRECTION = 'ASC';

    public $field;
    public $direction;

    public function __construct(string $field, string $direction)
    {
        $this->field = $field;
        $this->direction = $direction;
    }

    public static function fromQueryParameters(array $queryParameters) : self
    {
        $column = $queryParameters['sort'] ?? self::DEFAULT_FIELD;
        $direction = self::DEFAULT_DIRECTION;
        if ('-' === $column[0]) {
            $direction = 'DESC';
            $column = trim($column, '-');
        }

        return new self($column, $direction);
    }
}
```

The `Filtering` value object takes care of all the other parameters:

```php
<?php

namespace AppBundle\Search\Criteria;

class Filtering
{
    public $fields;

    public function __construct(array $fields)
    {
        $this->fields = $fields;
    }

    public static function fromQueryParameters(array $queryParameters) : self
    {
        $fields = $queryParameters;
        unset($fields['page']);
        unset($fields['per_page']);
        unset($fields['sort']);

        return new self($fields);
    }
}
```

With this we have a generic Search Engine. The next step is to provide an
implementation.

## A Doctrine implementation

All implementations of `SearchEngine` need to be able to handle many types of
parameters (pagination, filtering, etc).

To [avoid our Doctrine implementation to become a big ball of mud](https://speakerdeck.com/richardmiller/avoiding-the-mud),
we're going to split the work into `Builders`, which construct the DQL query using
the `QueryBuilder`:

```php
<?php

namespace AppBundle\DoctrineSearch;

use AppBundle\Search\Criteria;
use AppBundle\Search\SearchEngine;
use Doctrine\DBAL\Connection;
use Doctrine\DBAL\Query\QueryBuilder;
use Porpaginas\Result;

class DoctrineSearchEngine implements SearchEngine
{
    private $connection;
    private $builders = [];

    public function __construct(Connection $connection)
    {
        $this->connection = $connection;
    }

    public function add(Builder $builder)
    {
        $this->builders[] = $builder;
    }

    public function match(Criteria $criteria) : Result
    {
        $queryBuilder = new QueryBuilder($this->connection);
        foreach ($this->builders as $builder) {
            if (true === $builder->supports($criteria)) {
                $builder->build($criteria, $queryBuilder);
            }
        }

        return new DoctrineResult($queryBuilder);
    }
}
```

Here's the `Builder` interface:

```php
<?php

namespace AppBundle\DoctrineSearch;

use AppBundle\Search\Criteria;
use Doctrine\DBAL\Query\QueryBuilder;

interface Builder
{
    public function supports(Criteria $criteria) : bool;
    public function build(Criteria $criteria, QueryBuilder $queryBuilder);
}
```

We're not going to execute the query immediately, we're instead going to return
the `QueryBuilder` wrapped in a `Result` implementation: this will allow us to
choose between getting all the profiles or only getting a subset:

```php
<?php

namespace AppBundle\DoctrineSearch;

use Doctrine\DBAL\Query\QueryBuilder;
use Porpaginas\Result;

class DoctrineResult implements Result
{
    private $queryBuilder;

    public function __construct(QueryBuilder $queryBuilder)
    {
        $this->queryBuilder = $queryBuilder;
    }

    public function take($offset, $limit)
    {
        $queryBuilder = clone $this->queryBuilder;
        $queryBuilder->setFirstResult($offset);
        $queryBuilder->setMaxResults($limit);
        $statement = $queryBuilder->execute();

        return new IteratorPage($statement->getIterator(), $offset, $limit, $this->count());
    }

    public function count()
    {
        $queryBuilder = clone $this->queryBuilder;
        $subSql = $queryBuilder->getSql();
        $sql = <<<SQL
SELECT count(*) AS count
FROM (
    $subSql
) as sub_query
SQL
        ;
        $result = $queryBuilder->getConnection()->fetchAssoc($sql, $queryBuilder->getParameters());

        return $result['count'] ?? 0;
    }

    public function getIterator()
    {
        $queryBuilder = clone $this->queryBuilder;
        $statement = $queryBuilder->execute();

        return $statement->getIterator();
    }
}
```

Finally if a subset is asked, we need to provide our implementation of `Page`:

```php
<?php

namespace AppBundle\DoctrineSearch;

use Porpaginas\Page;

class IteratorPage implements Page
{
    private $iterator;
    private $offset;
    private $limit;
    private $totalCount;

    public function __construct(\Iterator $iterator, int $offset, int $limit, int $totalCount)
    {
        $this->iterator = $iterator;
        $this->offset = $offset;
        $this->limit = $limit;
        $this->totalCount = $totalCount;
    }

    public function getCurrentOffset()
    {
        return $this->offset;
    }

    public function getCurrentPage()
    {
        if (0 === $this->limit) {
            return 1;
        }

        return floor($this->offset / $this->limit) + 1;
    }

    public function getCurrentLimit()
    {
        return $this->limit;
    }

    public function count()
    {
        return count($this->iterator);
    }

    public function totalCount()
    {
        return $this->totalCount;
    }

    public function getIterator()
    {
        return $this->iterator;
    }
}
```

## Building our Query

Now that we have a fully functional Search Engine, we need to create `Builders`
specific for our need. The first one will be about selecting profiles:

```php
<?php

namespace AppBundle\Profile\DoctrineSearch;

use AppBundle\DoctrineSearch\Builder;
use AppBundle\Search\Criteria;
use Doctrine\DBAL\Query\QueryBuilder;

class SelectProfileBuilder implements Builder
{
    public function supports(Criteria $criteria) : bool
    {
        return 'profile' === $criteria->resourceName;
    }

    public function build(Criteria $criteria, QueryBuilder $queryBuilder)
    {
        $queryBuilder->select('name');
        $queryBuilder->from('profile', 'p');
    }
}
```

We also need to be able to order our results:

```php
<?php

namespace AppBundle\Profile\DoctrineSearch;

use AppBundle\DoctrineSearch\Builder;
use AppBundle\Search\Criteria;
use Doctrine\DBAL\Query\QueryBuilder;

class OrderingBuilder implements Builder
{
    public function supports(Criteria $criteria) : bool
    {
        return true;
    }

    public function build(Criteria $criteria, QueryBuilder $queryBuilder)
    {
        $queryBuilder->orderBy(
            $criteria->ordering->field,
            $criteria->ordering->direction
        );
    }
}
```

Finally if a name filter is provided we want to apply it:

```php
<?php

namespace AppBundle\Profile\DoctrineSearch;

use AppBundle\DoctrineSearch\Builder;
use AppBundle\Search\Criteria;
use Doctrine\DBAL\Query\QueryBuilder;

class ProfileNameFilteringBuilder implements Builder
{
    public function supports(Criteria $criteria) : bool
    {
        return 'profile' === $criteria->resourceName && isset($criteria->filtering->fields['name']);
    }

    public function build(Criteria $criteria, QueryBuilder $queryBuilder)
    {
        $queryBuilder->where('p.name LIKE :name');
        $queryBuilder->setParameter('name', "%{$criteria->filtering->fields['name']}");
    }
}
```

## Usage example

Let's create our controller:

```php
<?php
// File: src/AppBundle/Controller/SearchProfilesController.php

namespace AppBundle\Controller;

use Sensio\Bundle\FrameworkExtraBundle\Configuration\Method;
use Sensio\Bundle\FrameworkExtraBundle\Configuration\Route;
use Symfony\Bundle\FrameworkBundle\Controller\Controller;
use Symfony\Component\HttpFoundation\JsonResponse;
use Symfony\Component\HttpFoundation\Request;

class SearchProfilesController extends Controller
{
    /**
     * @Route("/api/v1/profiles")
     * @Method({"GET"})
     */
    public function searchProfilesAction(Request $request)
    {
        $criteria = Criteria::fromQueryParameters(
            'profile',
            $request->query->all()
        );
        $page = $this->get('app.search_engine')->match($criteria)->take(
            $criteria->paginating->offset,
            $criteria->paginating->itemsPerPage
        );
        $totalElements = $page->totalCount();
        $totalPages = (int) ceil($totalElements / $criteria->paginating->itemsPerPage);

        return new JsonResponse(array(
            'items' => iterator_to_array($page->getIterator()),
            'page' => array(
                'current_page' => $criteria->paginating->currentPage,
                'per_page' => $criteria->paginating->itemsPerPage,
                'total_elements' => $totalElements,
                'total_pages' => $totalPages,
            ),
        ), 200);
    }
}
```

And that's it!

## Conclusion

Just like using and overusing the "Command Bus" pattern can help us learn more on
how to get the "Command" part of CQRS right, using and overusing the "Repository"
design pattern in combination with the "Specification" one can help us get the
"Query" part right.

Building a private Search Engine component for our project is one way to achieve
this.
