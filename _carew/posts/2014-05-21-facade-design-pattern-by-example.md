---
layout: post
title: Facade design pattern, by example
tags:
    - design pattern
    - redaktilo
    - pet project
---

[TL;DR: jump to the conclusion](#conclusion).

Sometimes, you just want to hide low level complexity behind a unique interface
which communicates a high level policy. The Facade design pattern is all about
this.

In this article, we'll see a real world example with
[Redaktilo](https://github.com/gnugat/redaktilo).

## Low level file manipulation

**Redaktilo** provides an object oriented way to manipulate files. For example
you can open existing ones, or create new ones:

```php
<?php
require_once __DIR__.'/vendor/autoload.php';

use Gnugat\Redaktilo\DependencyInjection\StaticContainer;

$filesystem = StaticContainer::makeFilesystem();

$filename = '/tmp/monthy.py';
if ($filesystem->exists($filename)) {
    $file = $filesystem->open('/tmp/existing.txt');
} else {
    $file = $filesystem->create('/tmp/new.txt');
}

// ...
```

The main interest in this library lies in manipulations you can do, for example
jumping to a line and adding a new one under it:

```php
<?php
// ...

$lineSearchStrategy = StaticContainer::makeLineSearchStrategy();
$lineReplaceStrategy = StaticContainer::makeLineReplaceStrategy();

$lineNumber = $lineSearchStrategy->findNext('if Knight.saysNi():');
$lineReplaceStrategy->insertAt($file, $lineNumber, '    print "Ni!"');

// ...
```

Finally, you need to actually save the changes (they were only done in memory
until now) :

```php
// ...

$filesystem->write($file);
```

## A higher level API?

The Filesystem and Search/Replace strategies are low level APIs and require a
lot of boilerplate code to do every day tasks.

What if we provided a unique interface in front of those services? One that
would be in a higher level, say a text editor metaphor for instance?

```php
<?php
require_once __DIR__.'/vendor/autoload.php';

use Gnugat\Redaktilo\DependencyInjection\StaticContainer;

$editor = StaticContainer::makeEditor();

$filename = '/tmp/monthy.py';
$file = $editor->open($filename, true); // Force file creation.

$editor->jumpDownTo($file, 'if Knight.saysNi():');
$editor->addAfter($file, '    print "Ni!"');

$editor->save($file);
```

You don't need to take care of every service creation, and now you only have to
learn a small set of methods. The text editor metaphor also provides you with a
neat way to easily remember these methods!

## Conclusion

Facades hide low level implementation by providing a unique high level API.

Here's another blog post about this pattern, by
[Mike Ebert](http://mikeebert.tumblr.com/post/25342991856/design-pattern-facade-pattern).

I hope you found this article interesting, if you have any questions or
feedback please feel free to do so on [Twitter](https://twitter.com/epiloic).
