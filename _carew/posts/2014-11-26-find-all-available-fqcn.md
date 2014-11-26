---
layout: post
title: Find all available Fully Qualified ClassNames
tags:
    - technical
    - php
    - pet project
---

> **TL;DR**: [Nomo Spaco](https://github.com/gnugat/nomo-spaco) finds a given
> project's PHP files, and read them to give you the available Fully Qualified
> ClassNames.

PHP provides the following function to find the declared classes of a project:
[get_declared_classes](http://php.net/get_declared_classes).

However this function only lists the classes which have been loaded
(included/required) before its call: the usage of an autoloader breaks it
([Composer](http://getcomposer.org) for example).

In this article, we'll see how to solve this problem.

## For a single class

The first step is to find a way to get the Fully Qualified ClassName (fqcn) of
a single class.

A solution would be to read in its source file: if the project follows the
[PSR-0](http://php-fig.org/psr/psr-0) or [PSR-4](http://php-fig.org/psr/psr-4)
standards, the file should only contain one class and its filename should be the
same as the classname.

Let's create a function that retrieves the namespace declaration:

```php
<?php

function _get_full_namespace($filename) {
    $lines = file($filename);
    $namespaceLine = array_shift(preg_grep('/^namespace /', $lines));
    $match = array();
    preg_match('/^namespace (.*);$/', $namespaceLine, $match);
    $fullNamespace = array_pop($match);

    return $fullNamespace;
}
```

Now let's create a function that chops down the filename to get the classname:

```php
<?php

function _get_classname($filename) {
    $directoriesAndFilename = explode('/', $this->filename);
    $filename = array_pop($directoriesAndFilename);
    $nameAndExtension = explode('.', $filename);
    $className = array_shift($nameAndExtension);

    return $className;
}
```

That was easy! To get the Fully Qualified ClassName from a filename we can simply
call those two functions:

```php
<?php

$fqcn = _get_full_namespace($filename).'\\'._get_class_name($filename);
```

## For a project

The second step is to find the filenames of all the project's classes. Let's use
the [Symfony2 Finder Component](http://symfony.com/doc/current/components/finder/index.html):

```php
<?php

use Symfony\Component\Finder\Finder;

require __DIR__.'/vendor/autoload.php';

function _get_filenames($path) {
    $finderFiles = Finder::create()->files()->in($path)->name('*.php');
    $filenames = array();
    foreach ($finderFiles as $finderFile) {
        $filenames[] $finderFiles->getRealpath();
    }

    return $filenames;
}
```

And that's it! We can now create a function which calls those three:

```php
<?php

function get_all_fcqns($path) {
    $filenames = _get_filenames($projectRoot);
    $fcqns = array();
    foreach ($filenames as $filename) {
        $fcqns[] = _get_full_namespace($filename).'\\'._get_class_name($filename);
    }

    return $fcqns
}
```

It can simply be used like this:

```php
<?php

$allFcqns = get_all_fcqns(__DIR__);
```

## Conclusion

By finding all the PHP filenames in a project, and reading them to extract their
namespace and classname, we can easily find all the all available Fully
Qualified ClassNames.

The given functions are not meant to be used in production:

1. they won't include standard and loaded extensions classes
  (we could merge the result with `get_declared_classes()`)
2. they don't check if the files comply to PSR-0 or PSR-1
3. they will include test and fixture PHP files

I've started a proof of concept: [Nomo Spaco](https://github.com/gnugat/nomo-spaco).
Hopefully it will grow to be more efficient, safer and tested. But for now it
provides you with a package, so you don't have to copy paste anything :) .
