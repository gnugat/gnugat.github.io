---
layout: post
title: PHP array manipulation
tags:
    - redaktilo
    - pet project
    - php
---

> **TL;DR**: [Redaktilo](https://github.com/gnugat/redaktilo) provides a nice
> API to manipulate array of lines (insert, replace, go to line, etc).

Arrays are surely one of the most used PHP functionality: they're simple,
convenient and benefit from a large set of standard functions to manipulate them.

Let's see the different possibilities:

* [Finding an element](#finding-an-element)
* [Finding an element relatively to a given index](#finding-an-element-relatively-to-a-given-index)
* [Inserting a new element](#inserting-a-new-element)
* [Removing an element](#removing-an-element)
* [Retrieving elements from a file](#retrieving-elements-from-a-file)
* [Saving changes in a file](#saving-changes-in-a-file)
* [There is a better way](#there-is-a-better-way)
    * [Retrieving a line](#retrieving-a-line)
    * [Finding an element relatively to a given line number](#finding-an-element-relatively-to-a-given-line-number)
    * [Inserting a new line](#inserting-a-new-line)
    * [Using Text](#using-text)
    * [Cheat Sheet](#cheat-sheet)
        * [Editor](#editor)
        * [Text](#text)
        * [File](#file)
* [Conclusion](#conclusion)

## Finding an element

In order to find the index of a string in an array, we can use one of the
following functions:

```php
<?php

$montyPython = array(
    'This is a dead parrot',
    'No, no, it\'s not dead, it\'s resting!',
);

$exactSentence = 'This is a dead parrot';
array_search($exactSentence, $montyPython, true); // Returns 0
$regex = '/resting!$/';
$found = preg_grep($regex, $montyPython);
key($found); // Returns 1
```

> **Note**: The third parameter of [`array_search`](http://php.net/array_search)
> enables the strict comparison (it makes sure the types are also the same).

We can find the matching elements of a pattern using
[`preg_grep`](http://php.net/preg_grep). To get the index of the first result
found, we can use [`key`](http://php.net/key).

## Finding an element relatively to a given index

It's great! Now what if we want to remember the index and then make a search
relatively to it? For example we want to find the index of the element
`/a knewt/`, but only in the elements above `... I got better...`:

```php
<?php

$holyGrail = array(
    'She turned me into a knewt!',
    'A knewt?',
    '... I got better...',
    'A WITCH!',
);

$index = array_search('... I got better...', $holyGrail, true);
$section = array_slice($holyGrail, 0, $index, true);
$reversedSection = array_reverse($section, true);
$found = preg_grep('/a knewt/', $reversedSection);
key($found); // Returns 0
```

In this code snippet, we get a subset of the array
(from the first element to `... I got better`) using
[`array_slice`](http://php.net/array_slice) (the last argument allows to keep
the indexes unchanged). This also excludes `... I got better...`.

Then we change the order of the elements using
[`array_reverse`](http://php.net/array_reverse) (the second argument allows to
keep the index unchanged) so the element above `... I got better...` would be
the first result.

Finally we look for `/a knewt/` as we did previously.

## Inserting a new element

If we want to insert a new element after a given index in the array, we need to
use [`array_splice`](http://php.net/array_splice):

```php
<?php

$grandPiano = array(
    'I would like to learn how to fly an aeroplane',
    'A what?',
    'An aeroplane',
    'OH! An aeroplane, oh I say we are grand aren\'t we?',
    'Pardon me while I\'m flying me aeroplane... NOW GET ON THE TABLE!',
);

$found = preg_grep('/grand/', $grandPiano);
$index = key($found);
array_splice($grandPiano, $index + 1, 0, 'No more cluttered cream for me, butler, I\'m off to play the grand piano');
```

Actually `array_splice` allows to replace a subsection of an array, here's the
explanation of its arguments:

1. the array to manipulate
2. the starting index
3. the ending index (`0` means replacing nothing, therefore just inserting)
4. the replacement (in our case the element to insert)

It's not very explicit, but we have a solution for this (keep reading to find
out).

## Removing an element

Here's an easy one:

```php
<?php

$parrot = array(
    'Hello, I would like to make a complain. Hello, miss?',
    'What do you mean miss?',
    'Sorry, I have a cold',
);

$index = array_search('Sorry, I have a cold', $parrot, true);
unset($parrot[$index]);
```

You might want to reorder the indexes, to avoid gaps:

```php
<?php

$parrot = array(
    'Hello, I would like to make a complain. Hello, miss?',
    'What do you mean miss?',
    'Sorry, I have a cold',
);

$index = array_search('What do you mean miss?', $parrot, true);
unset($parrot[$index]);
// Current value:
// $parrot = array(
//     0 => 'Hello, I would like to make a complain. Hello, miss?',
//     2 => 'Sorry, I have a cold',
// );

$parrot = array_values($parrot);
// Current value:
// $parrot = array(
//     0 => 'Hello, I would like to make a complain. Hello, miss?',
//     1 => 'Sorry, I have a cold',
// );
```

The [`array_values`](http://php.net/array_values) function is equivalent to:

```php
$newArray = array();
foreach ($oldArray as $element) {
    $newArray[] = $element;
}
```

## Retrieving elements from a file

Until now, we've been using a hard coded array, but this is rarely what we
encounter in real life project. The data could for example come from a file,
which can be transformed into an array of lines:

```php
<?php

$file = file('/tmp/holy-grail.text', FILE_IGNORE_NEW_LINES);
```

> **Note**: the second argument will remove the trailing line breaks.

The only problem with [`file`](http://php.net/file) is that it will remove the
last line if it's empty. Let's use another function:

```php
<?php

$content = file_get_contents('/tmp/holy-grail.txt');
$lines = explode("\n", $content);
```

The [`file_get_contents`](http://php.net/file_get_contents) function returns the
content as a string.

We used [`explode`](http://php.net/explode) to split it into an array of lines.

This assumes that the file hasn't been created on Windows (where the line
separator is `\r\n`)... We need to detect the line break:

```php
<?php

$content = @file_get_contents('/tmp/holy-grail.txt');
$lineBreak = "\n"; // Used by every systems (except Windows), so used as default
if (false === strpos($content, "\n")) { // No line break detected at all
    $lineBreak = PHP_EOL; // Using the system's one
}
if (false !== strpos($content, "\r\n")) { // Windows line break detected
    $lineBreak = "\r\n";
}
$lines = explode($lineBreak, $content);
```

> **Note**: There's many check to be done before actually reading the file
> (does the file actually exists? Do we have the permission to read it?).
> We have a solution for this (keep reading to find out).

## Saving changes in a file

If we do any changes to those lines, we might want to save them on the
filesystem:

```php
<?php

$lines = array(
    'Morning, morning, morning',
    'Morning Jim, Morning Jack',
    'Can\'t complain, keep coming back',
    'Boring, boring, boring',
);
$lineBreak = "\n"; // Or whatever has been detected
$content = implode($lineBreak, $lines);
file_put_contents('/tmp/silly-walk-song.txt', $content);
```

To convert back the array of lines to a string content, we use
[`implode`](http://php.net/implode).

To write the content in the file, we use
[`file_put_contents`](http://php.net/file_put_contents).

> **Note**: There's many check to be done before actually writing in a file
> (does the path actually exists? Do we have the permissions? What happens if
> the writing process fails during the execution?). To solve this, use the
> Symfony2 Filesystem Component (`Filesystem#dumpFile()`).

## There is a better way

You don't find `array_splice` very explicit for element insertion (or can't find
a way to remember its argument order/meaning)?

Keeping the elements, the index, the line break in separates variables looks too
procedural for you?

And what about error management?

Don't panic! There is a better way: [Redaktilo](https://github.com/gnugat/redaktilo)
(it means "Editor" in esperanto).

This small library makes array manipulation easier by providing:

* an `Editor` object (open, save, find, insert, etc)
* a `Text` object (line break, elements, current index, etc)
* a `File` object (same as `Text`, but with filename)

Use it in your projects, thanks to [Composer](http://getcomposer.org):

    composer require 'gnugat/redaktilo:~1.1'

```php
<?php

require __DIR__.'/vendor/autoload.php';

use Gnugat\Redaktilo\EditorFactory;

$editor = EditorFactory::createEditor();
```

> **Note**: In order to make operations more explicit, Redaktilo has adopted the
> vocabulary of file edition (more specifically manipulation of lines). But in
> the end it's still array manipulation.

### Retrieving a line

You don't have to worry about file checking and line break detection anymore:

```php
<?php

require __DIR__.'/vendor/autoload.php';

use Gnugat\Redaktilo\EditorFactory;

$editor = EditorFactory::createEditor();
$file = $editor->open('/tmp/silly-walk-song.txt');
$file->getLineBreak(); // Returns "\n" if the file hasn't been created on Windows
```

### Finding an element relatively to a given line number

Redaktilo takes care of the search strategy for you (it uses `preg_grep` when
you give a valid regular expression, and `array_search` when you give a string).

It supports search relative to the current line number stored in the given
`Text` and `File` (it uses `array_slice`, `array_reverse` and `key` internally).

The `hasAbove` and `hasBelow` methods just return a boolean, while the
`jumpAbove` and `jumpBelow` methods rather store the found line number in the
given `Text` and `File` (and raise an exception if nothing is found):

```php
<?php

require __DIR__.'/vendor/autoload.php';

use Gnugat\Redaktilo\EditorFactory;

$editor = EditorFactory::createEditor();
$file = $editor->open('/tmp/silly-walk-song.txt');

$editor->jumpBelow($file, 'Boring, boring, boring');
$file->getCurrentLineNumber(); // Returns 3

$editor->hasAbove($file, '/morning,/'); // Returns true
```

> **Note**: `hasAbove`, `hasBelow`, `jumpAbove` and `jumpBelow` all have a third
> argument which is a line number. If provided, the search will be done
> relatively to this line number, rather than to the current one.
>
> For example, checking the presence of a pattern in the whole file can be done
> as: `$editor->hasBelow($file, $pattern, 0); // starts the search from the top of the file`.

### Inserting a new line

No more `array_splice` nonsense!

```php
<?php

require __DIR__.'/vendor/autoload.php';

use Gnugat\Redaktilo\EditorFactory;

$editor = EditorFactory::createEditor();
$file = $editor->open('/tmp/silly-walk-song.txt');

$editor->insertAbove($file, 'The silly walk song');
```

> **Note**: `insertAbove`, `insertBelow`, `replace` and `remove` all have a
> third argument which is a line number. If provided, the anipulation will be
> done relatively to it, instead of relatively to the current one.

### Using Text

If you're not manipulating a file, you can use `Text` just like we used
`File`:

```php
<?php

require __DIR__.'/vendor/autoload.php';

use Gnugat\Redaktilo\EditorFactory;
use Gnugat\Redaktilo\Service\LineBreak;
use Gnugat\Redaktilo\Service\TextFactory;

$lineBreak = new LineBreak();
$textFactory = new TextFactory($lineBreak);

$text = $textFactory->make(<<<EOF
Some raw text you would have got from somewhere,
for example a database.
EOF
);

$editor = EditorFactory::createEditor();
$editor->hasBelow($text, '/a database/'); // Returns true
```

### Cheat Sheet

There's many more operations available, as you can discover in
[the documentation](https://github.com/gnugat/redaktilo/tree/master/doc).

To make it easier, here's some cheat sheet.

#### Editor

```php
<?php

namespace Gnugat\Redaktilo;

use Gnugat\Redaktilo\Search\PatternNotFoundException;
use Gnugat\Redaktilo\Search\SearchEngine;
use Gnugat\Redaktilo\Service\Filesystem;
use Symfony\Component\Filesystem\Exception\FileNotFoundException;
use Symfony\Component\Filesystem\Exception\IOException;

class Editor
{
    public function open($filename, $force = false); // @throws FileNotFoundException
    public function save(File $file); // @throws IOException If cannot write

    // @throw PatternNotFoundException
    public function jumpAbove(Text $text, $pattern, $location = null);
    public function jumpBelow(Text $text, $pattern, $location = null);

    // @return bool
    public function hasAbove(Text $text, $pattern, $location = null);
    public function hasBelow(Text $text, $pattern, $location = null);

    public function insertAbove(Text $text, $addition, $location = null);
    public function insertBelow(Text $text, $addition, $location = null);
    public function replace(Text $text, $replacement, $location = null);
    public function remove(Text $text, $location = null);
}
```

#### Text

```php
<?php

namespace Gnugat\Redaktilo;

class Text
{
    public function getLines();
    public function setLines(array $lines);
    public function getLength();
    public function getLineBreak();
    public function setLineBreak($lineBreak);
    public function getCurrentLineNumber();

    // @throw InvalidLineNumberException
    public function setCurrentLineNumber($lineNumber);
    public function getLine($lineNumber = null);
    public function setLine($line, $lineNumber = null);
}
```

#### File

```php
<?php

namespace Gnugat\Redaktilo;

class File extends Text
{
    public function getFilename();
    public function setFilename($filename);
}
```

## Conclusion

PHP provides plenty of built-in functions to manipulate arrays, but those are
not enough. [Redaktilo](https://github.com/gnugat/redaktilo) is a small library
which provides a nicer API.

It allows you to select a line relatively to the current one and then do CRUD
operations on it.

I hope you'll find it as usefull as I do and if you find any bug or have any
proposals feel free to do so on [Github](https://github.com/gnugat/redaktilo/issues)
where [Loïck Piera](http://loickpiera.com/) and myself will both be glad to help
you.

> **Note**: As for the 15/10/2014, the current version of Redaktilo is 1.1.6
> (stable). Future updates are already planned!
