---
layout: post
title: Open/Closed principle, by example
tags:
    - design principle
    - redaktilo
    - pet project
---

[TL;DR: jump to the conclusion](#conclusion).

This week I've read two articles, which just have been published, on the
Open/Closed principle:

* one by [Uncle Bob](http://blog.8thlight.com/uncle-bob/2014/05/12/TheOpenClosedPrinciple.html)
* another one by [Mathias Verraes](http://verraes.net/2014/05/final-classes-in-php/)

I'd like to add my small contribution to their explanation by providing a real
world example: [Redaktilo](https://github.com/gnugat/redaktilo).

## Problem statement

Let's say you have the following file:

    Egg
    Sausage
    Bacon
    Spam

Redaktilo provides an `Editor` class which allows you to jump to the line you
want, provided that you know exactly its content:

```php
$editor->has($file, 'Bacon'); // true!
$editor->jumpDownTo($file, 'Bacon'); // Current line: Bacon
$editor->jumpUpTo($file, 'Sausage'); // Current line: Sausage
```

But what if you want to jump two lines under `Sausage`? You'd have to create
a new method:

```php
$editor->moveDown($file, 2); // Current line: Spam
```

You have extended `Editor` by modifying it.

## Complying to the Open/Closed principle

Having to fork a library to extend it doesn't feel natural. What does the
Open/Closed principle say?

> Software entities (classes, modules, functions, etc.) should be open for
> extension, but closed for modification.

Our `Editor` class is open to extension, but also to modification.

To fix this, we can transfer the responsibility of finding a pattern in the file
to a `SearchStrategy`:

```php
<?php

namespace Gnugat\Redaktilo\Search;

use Gnugat\Redaktilo\File;

interface SearchStrategy
{
    public function has(File $file, $pattern);

    public function findNext(File $file, $pattern);
    public function findPrevious(File $file, $pattern);

    public function supports($pattern);
}

```

Here's some implementation ideas:

* `LineSearchStrategy`: looking for the exact line in the file
* `LineNumberSearchStrategy`: jumping to a line relatively to the current one
* `RegexpSearchStrategy`: looking for a pattern in the file using regular expressions
* `PhpTokenSearchStrategy`: parsing PHP tokens

The `supports` method tells you that `LineSearchStrategy` needs `$pattern` to be
a string, but that `RegexpSearchStrategy` needs an `Expression` value object.

The responsibility to find a `SearchStrategy` which supports the given pattern
should be delegated to `SearchEngine`:

```php
<?php

namespace Gnugat\Redaktilo\Search;

class SearchEngine
{
    private $searchStrategies = array();

    public function registerStrategy(SearchStrategy $searchStrategy)
    {
        $this->searchStrategies[] = $searchStrategy;
    }

    public function resolve($pattern)
    {
        foreach ($this->searchStrategies as $searchStrategy) {
            if ($searchStrategy->supports($pattern)) {
                return $searchStrategy;
            }
        }

        throw new PatternNotSupportedException($pattern);
    }
}
```

You no longer need to fork Redaktilo to add new search related behavior, you can
now just create a new implementation of `SearchStrategy`, register it into
`SearchEngine` and then inject it into the `Editor`:

```php
use Gnugat\Redaktilo\Editor;
use Gnugat\Redaktilo\Filesystem;
use Gnugat\Redaktilo\Search\SearchEngine;
use Gnugat\Redaktilo\Search\LineNumberSearchStrategy;
use Gnugat\Redaktilo\Search\LineSearchStrategy;
use Symfony\Component\Filesystem\Filesystem as SymfonyFilesystem;

$searchEngine = new SearchEngine();

$lineSearchStrategy = new LineSearchStrategy();
$searchEngine->registerStrategy($lineSearchStrategy);

$lineNumberSearchStrategy = new LineNumberSearchStrategy();
$searchEngine->registerStrategy($lineNumberSearchStrategy);

$symfonyFilesystem = new SymfonyFilesystem();
$filesystem = new Filesystem($symfonyFilesystem);
$editor = new Editor($filesystem, $searchEngine);
```

We just made Redaktilo open to extension (still) and closed to modifications,
hooray!

## Editor's diff

Here's what `Editor` looked like after adding `moveDown`:

```php
<?php

namespace Gnugat\Redaktilo;

class Editor
{
    public function jumpDownTo(File $file, $pattern)
    {
        $lines = $file->readlines();
        $filename = $file->getFilename();
        $currentLineNumber = $file->getCurrentLineNumber() + 1;
        $length = count($lines);
        while ($currentLineNumber < $length) {
            if ($lines[$currentLineNumber] === $pattern) {
                $file->setCurrentLineNumber($currentLineNumber);

                return;
            }
            $currentLineNumber++;
        }

        throw new \Exception("Couldn't find line $pattern in $filename");
    }

    public function jumpUpTo(File $file, $pattern)
    {
        $lines = $file->readlines();
        $filename = $file->getFilename();
        $currentLineNumber = $file->getCurrentLineNumber() - 1;
        while (0 <= $currentLineNumber) {
            if ($lines[$currentLineNumber] === $pattern) {
                $file->setCurrentLineNumber($currentLineNumber);

                return;
            }
            $currentLineNumber--;
        }

        throw new \Exception("Couldn't find line $pattern in $filename");
    }

    public function moveUp(File $file, $lines = 1)
    {
        $newLineNumber = $file->getCurrentLineNumber() - $lines;

        if ($newLineNumber < 0) {
            $newLineNumber = 0;
        }

        $file->setCurrentLineNumber($newLineNumber);
    }

    public function has(File $file, $pattern)
    {
        return $file->hasLine($pattern);
    }
}
```

And now, here's what it looks like:

```php
<?php

namespace Gnugat\Redaktilo;

use Gnugat\Redaktilo\Search\SearchEngine;

class Editor
{
    private $searchEngine;

    public function __construct(SearchEngine $searchEngine)
    {
        $this->searchEngine = $searchEngine;
    }

    public function jumpDownTo(File $file, $pattern)
    {
        $searchStrategy = $this->searchEngine->resolve($pattern);
        $foundLineNumber = $searchStrategy->findNext($file, $pattern);

        $file->setCurrentLineNumber($foundLineNumber);
    }

    public function jumpUpTo(File $file, $pattern)
    {
        $searchStrategy = $this->searchEngine->resolve($pattern);
        $foundLineNumber = $searchStrategy->findPrevious($file, $pattern);

        $file->setCurrentLineNumber($foundLineNumber);
    }

    public function has(File $file, $pattern)
    {
        $searchStrategy = $this->searchEngine->resolve($pattern);

        return $searchStrategy->has($file, $pattern);
    }
}
```

## Conclusion

You should be able to add new features without modifying existing code.

I hope you found this article interesting, if you have any questions or
feedback please feel free to do so on [Twitter](https://twitter.com/epiloic).
