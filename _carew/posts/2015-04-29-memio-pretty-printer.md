---
layout: post
title: Memio Pretty Printer
tags:
    - memio
    - pet project
    - introducing library
---

> **TL;DR**: [PrettyPrinter](http://github.com/memio/pretty-printer) converts a
> [Model](http://github.com/memio/model) into its PHP code (returns a string),
> using [Twig templates](http://twig.sensiolabs.org/).

Until now we've seen how to build Memio [Models](http://github.com/memio/model)
to describe PHP code and how to [validate](http://github.com/memio/validator)
the [syntax](http://github.com/memio/linter).

It's now time to take things seriously with the newly released package:
[PrettyPrinter](http://github.com/memio/pretty-printer), the actual code generator.

## What is a pretty printer?

As opposed to "fidelity printers" which are supposed to generate code according to
the developer's coding style, "pretty printer" rely on their own.

If we were to open an existing PHP file with Memio and then to generate it again immediately,
chances are that the code would look slightly different.

> **Note**: Memio actually complies to [PHP standards](http://www.php-fig.org/psr/),
> with some extra rules.

The name "printer" is a bit misleading: one could think that the service would
print the generated code in the console's output or a web page, but all it really
does is to return a simple string.

> **Note**: The terminology used is inspired by this [StackOverflow answer](http://stackoverflow.com/a/5834775/3437428).

## Template engine agnostic

Memio makes use of templates, making it easy to change the style. It defines a
`TemplateEngine` interface that has to be implemented, in order to comply with
[webmozart](http://webmozarts.com/)'s [request](https://github.com/memio/memio/issues/51).

For now the only package available is [TwigTemplateEngine](http://github.com/memio/twig-template-engine),
it provides [Twig templates](http://twig.sensiolabs.org/).

## Code generation example

Enough talk, let's code! First of all we have to create our `PrettyPrinter`:

```php
<?php

require __DIR__.'/vendor/autoload.php';

$loader = new \Twig_Loader_Filesystem(\Memio\TwigTemplateEngine\Config\Locate::templates());
$twig = new \Twig_Environment($loader);

$line = new \Memio\TwigTemplateEngine\TwigExtension\Line\Line();
$line->add(new \Memio\TwigTemplateEngine\TwigExtension\Line\ContractLineStrategy());
$line->add(new \Memio\TwigTemplateEngine\TwigExtension\Line\FileLineStrategy());
$line->add(new \Memio\TwigTemplateEngine\TwigExtension\Line\MethodPhpdocLineStrategy());
$line->add(new \Memio\TwigTemplateEngine\TwigExtension\Line\ObjectLineStrategy());
$line->add(new \Memio\TwigTemplateEngine\TwigExtension\Line\StructurePhpdocLineStrategy());

$twig->addExtension(new \Memio\TwigTemplateEngine\TwigExtension\Type());
$twig->addExtension(new \Memio\TwigTemplateEngine\TwigExtension\Whitespace($line));

$templateEngine = new \Memio\TwigTemplateEngine\TwigTemplateEngine($twig);
$prettyPrinter = new \Memio\PrettyPrinter\PrettyPrinter($templateEngine);
```

Wow! That was quite painful to write! Thankfully the next package to be released
will make life really easier (spoiler alert: `Build::prettyPrinter()`).

Now let's build some models:

```php
// ...

$myMethod = new \Memio\Model\Method('myMethod');
for ($i = 1; $i < 10; $i++) {
    $myMethod->addArgument(new \Memio\Model\Argument('mixed', 'argument'.$i));
}
```

All it takes to generate the code is this:

```php
// ...

$generatedCode = $prettyPrinter->generateCode($myMethod);
```

Let's see in the console output what it did:

```php
// ...

echo $generatedCode;
```

We should get the following:

```php
    public function myMethod(
        $argument1,
        $argument2,
        $argument3,
        $argument4,
        $argument5,
        $argument6,
        $argument7,
        $argument8,
        $argument9
    )
    {
    }
```

Each arguments are displayed on their own line, because the inline equivalent
would have been longer than 120 characters.

## Custom templates

Memio has extra rules regarding coding standards, for example it adds an empty
line between the PHP opening tag and the namespace statement.

We can get rid of this by creating our own custom template: first we copy the `file.twig`
template in our project:

```
{% verbatim %}
{#- File: my_templates/file.twig -#}
<?php
{% if file.licensePhpdoc is not empty %}

{% include 'phpdoc/license_phpdoc.twig' with { 'license_phpdoc': file.licensePhpdoc } only %}
{% endif %}
namespace {{ file.namespace }};

{% include 'collection/fully_qualified_name_collection.twig' with {
    'fully_qualified_name_collection': file.allFullyQualifiedNames
} only %}
{% if needs_line_after(file, 'fully_qualified_names') %}

{% endif %}
{% if file.structure is contract %}
{% include 'contract.twig' with { 'contract': file.structure } only %}
{% else %}
{% include 'object.twig' with { 'object': file.structure } only %}
{% endif %}
{% endverbatim %}
```

We've removed the line between `{% verbatim %}{% endif %}{% endverbatim %}` and `{% verbatim %}namespace {{ file.namespace }};{% endverbatim %}`.

In order for our custom template to be used, we'll need to add its directory path to `PrettyPrinter`:

```php
// ...

$prettyPrinter->addTemplatePath(__DIR__.'/my_templates');
```

And we're done!

Let's check the result:

```php
// ...

$file = \Memio\Model\File::make('src/Vendor/Project/MyClass.php')
    ->setStructure(new \Memio\Model\Object('Vendor\Project\MyClass'))
;

echo $prettyPrinter->generateCode($file);
```

This will output:

```php
<?php
namespace Vendor\Project;

class MyClass
{
}
```

## Conclusion

PrettyPrinter can convert Models into PHP code, it uses templates behind the scene
so we can tweak the coding style our way. It isn't tied to any Template Engine,
but we can install Memio's TwigTemplateEngine package .
