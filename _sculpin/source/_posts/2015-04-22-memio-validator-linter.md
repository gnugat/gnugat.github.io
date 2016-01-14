---
layout: post
title: Memio validator and linter
tags:
    - memio
    - pet project
    - introducing library
---

> **TL;DR**: Write [constraints](http://github.com/memio/validator) to check
> [models](http://github.com/memio/model) integrity.
> [Linter](http://github.com/memio/linter) constraints (e.g. syntax error) are already available.

Everyday Memio, the higly opinionated PHP code generation library, progresses
toward its stable release.

In this article, we'll have a look at two packages that have been freshly extracted:
`memio/validator` and `memio/linter`.

## Writing constraints

The [validator](http://github.com/memio/validator) packages provides an easy way
to write constraints. Let's write one to check that method arguments are never scalar.

> **Note**: This is one of the principle in [object calisthenics](http://williamdurand.fr/2013/06/03/object-calisthenics):
> [wrap all primitives and string](http://williamdurand.fr/2013/06/03/object-calisthenics/#3-wrap-all-primitives-and-strings).

```php
<?php

require __DIR__.'/vendor/autoload.php';

use Memio\Validator\Constraint;
use Memio\Validator\Violation\NoneViolation;
use Memio\Validator\Violation\SomeViolation;

class ArgumentCannotBeScalar implements Constraint
{
    public function validate($model)
    {
        $type = $model->getType();
        if (in_array($type, array('array', 'bool', 'callable', 'double', 'int', 'mixed', 'null', 'resource', 'string'), true)) {
            return new SomeViolation(sprintf('Argument "%s" cannot be scalar', $model->getName()));
        }

        return new NoneViolation();
    }
}
```

> **Note**: Naming constraints after their error message allow for better reability.

The next step is to register our constraint in a validator. Since our constraint
aims `Argument` models, we'll register it in an `ArgumentValidator`:

```php
// ...

use Memio\Validator\ModelValidator\ArgumentValidator;

$argumentValidator = new ArgumentValidator();
$argumentValidator->add(new ArgumentCannotBeScalar());
```

When building models, `Arguments` are burried in `Methods`, which themselves are burried in
`Contracts` or `Objects` which in turn are burried in `File`.

To make things easy, we'd like to simply give the top most model (e.g. `File`) to
a generic `Validator`. Its responsibility would be to go through each models and execute
the appropriate `ModelValidator`.

In order to do so, we have to create all `ModelValidators` and assemble them as follow:

```php
// ...

use Memio\Validator\ModelValidator\CollectionValidator;
use Memio\Validator\ModelValidator\ContractValidator;
use Memio\Validator\ModelValidator\FileValidator;
use Memio\Validator\ModelValidator\MethodValidator;
use Memio\Validator\ModelValidator\ObjectValidator;

$collectionValidator = new CollectionValidator();
$methodValidator = new MethodValidator($argumentValidator, $collectionValidator);
$contractValidator = new ContractValidator($collectionValidator, $methodValidator);
$objectValidator = new ObjectValidator($collectionValidator, $methodValidator);
$fileValidator = new FileValidator($contractValidator, $objectValidator);
```

Finally, we need to create a validator and register our `ModelValidators` in it:

```php
// ...

use Memio\Validator\Validator;

$calisthenicValidator = new Validator();
$calisthenicValidator->add($argumentValidator);
$calisthenicValidator->add($collectionValidator);
$calisthenicValidator->add($methodValidator);
$calisthenicValidator->add($contractValidator);
$calisthenicValidator->add($objectValidator);
$calisthenicValidator->add($fileValidator);
```

We can now validate our Models:

```php
// ...

$calisthenicValidator->validate($file); // @throws Memio\Validator\InvalidModelException if one or more constraint fail
```

The `InvalidModelException`'s message has one line per violation.

## Linter

Out of the box, Memio provides a [Linter](http://github.com/memio/linter) which
provides the following constraints:

* Collection cannot have name duplicates
* Concrete Object Methods cannot be abstract
* Contract Methods can only be public
* Contract Methods cannot be final
* Contract Methods cannot be static
* Contract Methods cannot have a body
* Method cannot be abstract and have a body
* Method cannot be both abstract and final
* Method cannot be both abstract and private
* Method cannot be both abstract and static
* Object Argument can only default to null

As we've seen above, constructing and assembling constraints and validators can be quite
tiresome.

That's where `memio/memio`, the main central repository, starts to be useful by
providing a simple way to get a ready to use linter:

```php
<?php

require __DIR__.'/vendor/autoload.php';

use Memio\Memio\Config\Build;

$linter = Build::linter();

$linter->validate($file); // @throws Memio\Validator\InvalidModelException if one or more constraint fail
```

## Conclusion

Validator allows the creation of custom constraint to ensure that the build Models
are valid. Linter is a set of constraints ready to use, allowing to prevent syntax errors
(e.g. a method cannot be both final and abstract).

If you'd like to find out more about Memio Validator, have a look at the documentation:

* [Validator Tutorial](http://memio.github.io/memio/doc/03-validation-tutorial.html)
