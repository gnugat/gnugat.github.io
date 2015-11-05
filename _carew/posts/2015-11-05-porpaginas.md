---
layout: post
title: porpaginas
tags:
    - introducing library
    - porpaginas
---

Pagination libraries like [Pagerfanta](https://github.com/whiteoctober/Pagerfanta)
or [KnpPaginator](https://github.com/KnpLabs/KnpPaginatorBundle) usually require
a `QueryBuilder`:

```
// Usually in a controller
$queryBuilder = $this->itemRepository->queryBuilderForFindAll();
$results = $paginationService->paginate(
    $queryBuilder,
    $currentPageNumber,
    $itemsPerPage
);
```

This is necessary because we need to get the result for the page as well as the
number of total results (with a database it would mean two queries).
Unfortunately this kind of logic tends to leak in our controllers which is why
[Benjamin Eberlei](http://www.whitewashing.de/) suggests an elegant alternative:

```php
// Can be done in a service
$result = $this->itemRepository->findAll();

// Can be done in a ViewListener
$page = $result->take($currentPageNumber, $itemsPerPage);
```

The `QueryBuilder` is actually wrapped in a `Result` which provides the possibility
to get all of them or a single portion.
Its `take` method returns the `PaginatorService` wrapped in a `Page` which contains
all the meta data we usually expect (page number, total elements, etc).

To make it possible he created [porpaginas](http://github.com/beberlei/porpaginas),
a small library that provides `Result` and `Page` as interfaces.
The actual pagination logic is delegated to the library of our choice, using adapters.

Enjoy!
