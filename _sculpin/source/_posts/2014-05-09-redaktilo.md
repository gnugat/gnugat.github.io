---
layout: post
title: "Redaktilo: because your code too needs an editor"
tags:
    - redaktilo
    - pet project
    - introducing library
---

[TL;DR: jump to the conclusion](#conclusion).

I've been working on a silly library lately:
[Redaktilo](https://github.com/gnugat/redaktilo) (it means editor in esperanto).

Redaktilo has been created to fulfill actual needs. In this article we'll see
what it is all about, and why it won't stay silly for long.

## Use case 1: YAML configuration edition

[Incenteev\ParameterHandler](https://github.com/Incenteev/ParameterHandler)
is a good example: it updates a YAML configuration after each update of the
dependencies using [Composer](https://getcomposer.org/).

It uses the
[Symfony2 Yaml component](http://symfony.com/doc/current/components/yaml/introduction.html)
which converts a YAML string into a PHP array, and then converts it back.
The problem with it is that it strips empty lines, custom formatting and
comments...

Redaktilo only inserts a new line in the file, leaving it as it is.

## Use case 2: JSON file edition

The `composer.json` file is really usefull and can be almost completly edited
using the `composer.phar` CLI application.

Some part still need manual edition, like the script section. To automate this
you could use `json_decode` and `json_encode`, but similarly to the previous use
case you would lose empty lines and custom formatting...

Redaktilo aims at solving this problem, but isn't ready yet: inserting a line
in JSON often means adding a comma at the end of the previous one.

## Use case 3: PHP source code edition

To be fair this use case isn't limited to PHP source code: it can be useful for
any plain text files (text, XML, java, python, anything).

[GnugatWizardBundle](https://github.com/gnugat/GnugatWizardBundle) automatically
registers new bundles installed using Composer in your Symfony2 application.

To do so it uses
[SensioGeneratorBundle](https://github.com/sensiolabs/SensioGeneratorBundle)'s
[KernelManipulator](https://github.com/sensiolabs/SensioGeneratorBundle/blob/8b7a33aa3d22388443b6de0b0cf184122e9f60d2/Manipulator/KernelManipulator.php)
to insert a line in the `app/AppKernel.php`. However this class registers bundles for every
environments, and doesn't take into account bundle which depend on the kernel.

If you take a look at the [KernelManipulator source code](https://github.com/sensiolabs/SensioGeneratorBundle/blob/8b7a33aa3d22388443b6de0b0cf184122e9f60d2/Manipulator/KernelManipulator.php)
you'll realise it has been a bit over engineered as it parses PHP tokens.

A new `KernelManipulator` could be written using Redaktilo as follow:

```php
<?php

namespace Sensio\Bundle\GeneratorBundle\Manipulator;

use Gnugat\Redaktilo\Editor;

class KernelManipulator extends Manipulator
{
    protected $editor;
    protected $appKernelFilename;

    public function __construct(Editor $editor, $appKernelFilename)
    {
        $this->editor = $editor;
        $this->appKernelFilename = $appKernelFilename;
    }

    public function addBundle($bundle)
    {
        $file = $this->editor->open($this->appKernelFilename);
        $newLine = sprintf('            new %s(),', $bundle);

        $this->editor->jumpDownTo('    public function registerBundles()');
        $this->editor->jumpDownTo('        $bundles = array(');
        $this->editor->jumpDownTo('        );');

        $this->editor->addBefore($file, $newLine);

        $this->editor->save($file);

        return true;
    }
}
```

## Usage

A great effort has been put to document the project, as you can see in the
[README](https://github.com/gnugat/redaktilo/#redaktilo).

Here's an overview!

You can install Redaktilo using [Composer](https://getcomposer.org/):

    composer require "gnugat/redaktilo:~0.3@dev"

Then you need to create an instance of the `Editor` class:

```php
<?php
require_once __DIR__.'/vendor/autoload.php';

use Gnugat\Redaktilo\Filesystem;
use Gnugat\Redaktilo\Editor;
use Symfony\Component\Filesystem\Filesystem as SymfonyFilesystem;

$symfonyFilesystem = new SymfonyFilesystem();
$filesystem = new Filesystem($symfonyFilesystem);
$editor = new Editor($filesystem);
```

`Editor` is completly stateless, which means you can use the same instance
everywhere in your scripts/applications/libraries.

Let's now have a look at the available classes and their responsibility.

## File

The basic idea behind Redaktilo is to provide an object oriented way to
represent files:

```php
<?php

namespace Gnugat\Redaktilo;

class File
{
    public function getFilename();

    public function read();
    public function write($newContent);

    // ...
}
```

Once this domain model available, you can build services to manipulate it.

## Filesystem

This is the first service available:

```php
<?php

namespace Gnugat\Redaktilo;

class Filesystem
{
    public function open($filename); // Cannot open new files
    public function create($filename); // Cannot create existing files

    public function exists($filename);

    public function write(File $file);
}
```

It creates instances of `File` and write their content in the actual file.

## Editor

Developers should only use the `Editor` class: it's a facade which provides the
text edition metaphor:

```php
<?php

namespace Gnugat\Redaktilo;

class Editor
{
    // Filesystem operations.
    public function open($filename, $force = false);
    public function save(File $file);

    // Line insertion.
    public function addBefore(File $file, $add);
    public function addAfter(File $file, $add);

    // Content navigation.
    public function jumpDownTo(File $file, $line);
    public function jumpUpTo(File $file, $line);
}
```

And that's it.It told you it was a small and simple library ;) . Now let's see
what's planned for the next releases.

## Version 0.4 should bring SearchEngine

There's still some search logic left in `Editor`.

To remove it, a whole system will be put in place: `SearchEngineCollection` will
be called by `Editor` and will ask its `SearchEngine`s if they support the
pattern.

This should allow many search strategies:

* find by line (what's currently done, an exact matching)
* find by line number
* find by regexp
* find by symbol (similar to [SublimeText](http://www.sublimetext.com/)'s `@`)

You could then have an extending point!

## Version 0.5 should bring ContentConverter

Some extra logic are also left in `File`, regarding the conversion of the
content into an array of lines.

`ContentConverter` could take a file, and convert its content into anything:

* an array of lines
* an array of `IndentedLine`
* PHP tokens

This would allow new types of `SearchEngine`, and maybe the creation of
`ContentEditor` which would bear the single responsibility of inserting,
replacing or removing bits of it.

## I need your humble opinion / help

I'd like to hear about more use cases: what would you do with Redaktilo? What
would you like to do with it?

You can [open issues to start discussions](https://github.com/gnugat/redaktilo/issues/new),
just make sure to provide a real life use case ;) .

## Conclusion

[Redaktilo](https://github.com/gnugat/redaktilo) provides an Object Oriented way
to manipulate files, through the editor metaphor:

* your scripts can open a file
* they can then navigate in the file to select a line
* next, they can insert a new line above/under the current one
* finally they can save the changes on the filesystem
