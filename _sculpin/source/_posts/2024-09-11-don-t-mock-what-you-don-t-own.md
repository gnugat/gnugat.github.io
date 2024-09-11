---
layout: post
title: "Don't mock what you don't own -- phpspec isn't a test framework"
tags:
    - phpspec
    - tdd
---

> TL;DR: phpspec isn't a test framework. It's a code designing/modeling tool.

## Something feels wrong

Looking at some 2014 code of mine, I found the following test:

```php
<?php

namespace spec\Memio\SpecGen\CodeEditor;

use Gnugat\Redaktilo;
use Memio\Model;
use Memio\PrettyPrinter\PrettyPrinter;
use Memio\SpecGen\CodeEditor\InsertConstructor;
use Memio\SpecGen\CodeEditor\InsertConstructorHandler;
use Memio\SpecGen\CommandBus\CommandHandler;
use PhpSpec\ObjectBehavior;

class InsertConstructorHandlerSpec extends ObjectBehavior
{
    function let(
        Redaktilo\Editor $redaktiloEditor,
        PrettyPrinter $prettyPrinter,
    ) {
        $this->beConstructedWith($redaktiloEditor, $prettyPrinter);
    }

    function it_inserts_constructor_in_class_that_has_constants_and_methods(
        Redaktilo\Editor $redaktiloEditor,
        Redaktilo\File $redaktiloFile,
        Model\Method $modelMethod,
        PrettyPrinter $prettyPrinter,
    ) {
        $insertConstructor = new InsertConstructor($redaktiloFile->getWrappedObject(), $modelMethod->getWrappedObject());

        $generatedCode =<<<'GENERATED_CODE'
                public function __construct(Dependency $dependency, string $redaktiloFilename)
                {
                    $this->dependency = $dependency;
                    $this->filename = $redaktiloFilename;    
                }
            GENERATED_CODE
        ;

        $redaktiloEditor->hasBelow($redaktiloFile, InsertConstructorHandler::CONSTRUCTOR, 0)->willReturn(false);
        $redaktiloEditor->hasBelow($redaktiloFile, InsertConstructorHandler::METHOD, 0)->willReturn(true);
        $redaktiloEditor->jumpBelow($redaktiloFile, InsertConstructorHandler::METHOD, 0)->shouldBeCalled();
        $redaktiloEditor->insertAbove($redaktiloFile, '')->shouldBeCalled();
        $prettyPrinter->generateCode($modelMethod)->willReturn($generatedCode);
        $redaktiloEditor->insertAbove($redaktiloFile, $generatedCode)->shouldBeCalled();
        $redaktiloFile->decrementCurrentLineNumber(1)->shouldBeCalled();
        $redaktiloFile->getLine()->willReturn('    const CONSTANT = 42;');
        $redaktiloEditor->insertBelow($redaktiloFile, '')->shouldBeCalled();

        $this->handle($insertConstructor);
    }
}
```

There are some things that feel wrong there, like the calls to
`getWrappedObject()`, and when something feels wrong with phpspec, it usually
means that this thing is wrong.

## Don't mock SUT inputs

As per the previous advice, [don't mock SUT inputs](https://gnugat.github.io/2024/08/19/phpspec-tip-don-t-mock-sut-inputs.html),
I've removed the inputs mock and their awkward `getWrappedObject()` calls
and instead set up the inputs:

```php
    function it_inserts_constructor_in_class_that_has_constants_and_methods(
        Redaktilo\Editor $redaktiloEditor,
        PrettyPrinter $prettyPrinter,
    ) {
        $redaktiloFile = Redaktilo\File::fromString(<<<'FILE'
            <?php 
                  
            namespace Vendor\Project;
              
            class MyClass
            { 
                const CONSTANT = 42;
                
                public function existingMethod()
                {
                }
            } 
            FILE
        );
        $modelMethod = (new Model\Method('__construct'))
            ->addArgument(new Model\Argument('Vendor\Project\Dependency', 'dependency'))
            ->addArgument(new Model\Argument('string', 'filename'))
        ;                      
        $insertConstructor = new InsertConstructor($redaktiloFile, $modelMethod);

        $generatedCode =<<<'GENERATED_CODE'
                public function __construct(Dependency $dependency, string $redaktiloFilename)
                {
                    $this->dependency = $dependency;
                    $this->filename = $redaktiloFilename;    
                }
            GENERATED_CODE
        ;

        $redaktiloEditor->hasBelow($redaktiloFile, InsertConstructorHandler::CONSTRUCTOR, 0)->willReturn(false);
        $redaktiloEditor->hasBelow($redaktiloFile, InsertConstructorHandler::METHOD, 0)->willReturn(true);
        $redaktiloEditor->jumpBelow($redaktiloFile, InsertConstructorHandler::METHOD, 0)->shouldBeCalled();
        $redaktiloEditor->insertAbove($redaktiloFile, '')->shouldBeCalled();
        $prettyPrinter->generateCode($modelMethod)->willReturn($generatedCode);
        $redaktiloEditor->insertAbove($redaktiloFile, $generatedCode)->shouldBeCalled();
        $redaktiloEditor->insertBelow($redaktiloFile, '')->shouldBeCalled();

        $this->handle($insertConstructor);
    }
```

## Something still feels wrong

Now pay attention to the two following lines we've removed:

```php
        $redaktiloFile->decrementCurrentLineNumber(1)->shouldBeCalled();
        $redaktiloFile->getLine()->willReturn('    const CONSTANT = 42;');
```

After running the tests, I get an error:

> Exception `Gnugat\Redaktilo\Exception\InvalidLineNumberException("The line number should be positive")` has been thrown.

When the Redaktilo File is first instantiated in our test method, it is
initialised with a "current line number" set to `0`. Since Redaktilo's Editor
is mocked, it doesn't update the file's "current line number" as it would in
a real situation. Our SUT, `InsertConstructorHandler`, however calls directly
`decrementCurrentLineNumber` on the file, which ends up trying to set
"current line number" to `-1`, hence the exception.

To make the test pass, we could add a call to Redaktilo's File
`setCurrentLineNumber()`, for example:

```php
        $redaktiloEditor->hasBelow($redaktiloFile, InsertConstructorHandler::CONSTRUCTOR, 0)->willReturn(false);
        $redaktiloEditor->hasBelow($redaktiloFile, InsertConstructorHandler::METHOD, 0)->willReturn(true);
        $redaktiloEditor->jumpBelow($redaktiloFile, InsertConstructorHandler::METHOD, 0)->shouldBeCalled();
        $redaktiloFile->setCurrentLineNumber(11);
        $redaktiloEditor->insertAbove($redaktiloFile, '')->shouldBeCalled();
        $prettyPrinter->generateCode($modelMethod)->willReturn($generatedCode);
        $redaktiloEditor->insertAbove($redaktiloFile, $generatedCode)->shouldBeCalled();
        $redaktiloEditor->insertBelow($redaktiloFile, '')->shouldBeCalled();
```

But this feels wrong, and when something feels wrong with phpspec, it usually
means that this thing is wrong. But what?

## Don't mock what you don't own

Let's take a step back and look at the test again.
What are we trying to achieve here?

It is a test method, written with phpspec, that checks assertions on the
implementation details of the class under test `InsertConstructorHandler`,
by setting up mocks for the Redaktilo library.

2014 me would think that's perfectly reasonable, and would probably struggle
to identify the issue. But 2024 me can tell straight away from the above
paragraph what the issue is.

I've actually always had some issue understanding the advice
"don't mock what you don't own".
How do we really define what we own, and what we don't?

* do I own a third party library I've installed in my application (eg Guzzle as a HTTP client to do curl requests)?
* do I own a "third party" library, that I've actually developed and then installed in my application (eg Redaktilo)?
* do I own abstractions I've built on top of these libraries?
* do I own the framework I've installed (eg Symfony, and its components like Form)?
* do I own the RAD controllers (ie are they part of my application, or of the framework)?
* do I own my own implementations of extension points (eg custom EventListeners)?
* do I own business code in the application that was initially designed for other part of the system (ie from another Bounded Context)?
* do I own code in the application that I haven't written?

The answer to these questions probably depends on the context, but here in
`InsertConstructorHandler`, it certainly feels like Redaktilo, a third party
library (which I've developed), is "something that I don't own" and therefore
shouldn't be mocked.

Now that we have identified the problem, how do we fix it?

## Behaviour Driven Development, it's all words

Let's re-read the first paragraph of the previous section, and more specifically:

> It is a test method, **written with phpspec**, that checks assertions on the
> implementation details of the class under test `InsertConstructorHandler`,
> by setting up mocks for the Redaktilo library.

And when reading the test method, we get a lot of "has below" and "jump below"
and "insert above". This is all implementation detail. And this is all
Redaktilo's (clunky) language.

**_Our test method is a one to one translation of the_ implementation details**.

phpspec is a specBDD framework. One of the core of Behaviour Driven Development
is to drop the "unit testing" terminology and use a slightly different
vocabulary instead:

- instead of the verb "to test", use "to specify"
- instead of "unit", use "behaviour"
- instead of "test method", use "example" 
- instead of "assertion", use "expectation"
- instead of "mock", use "collaborator"
- and why not switch the words "class under test" for "use case"
  
> See Liz Keogh. 2009. [Translating TDD to BDD](https://lizkeogh.com/2009/11/06/translating-tdd-to-bdd/)

This might not seem like much, or very useful,
but in reality the language used is key to changing our perspective.

To be able to have an example that checks expectations on a specific use case,
we first need to define the behaviour we want to describe in plain English:

> If the class doesn't already have a constructor
> But it has an existing method,
> As well as potentially a constant, or property definition
> Then the generated code for the new constructor
> Should be inserted above the existing method, separated by an empty line
> And it should also be under the constant and property definitions, also separated by an empty line

We then try our best to translate that into code. To use the exact same vocabulary.
This cannot be done by mocking Redaktilo, which has its own vocabulary.

So we have to extract the Redaktilo implementation details and hide them in
classes that have descriptive names which are relevant to our use case.

Creating a new abstraction layer, essentially.

Here's our new and improved "example":

```php
    function it_inserts_constructor_above_methods_but_under_constants_and_properties(
        DoesClassAlreadyHaveConstructor $doesClassAlreadyHaveConstructor,
        DoesClassAlreadyHaveMethods $doesClassAlreadyHaveMethod,
        PrettyPrinter $prettyPrinter,
        InsertGeneratedConstructorAboveExistingMethods $insertGeneratedConstructorAboveExistingMethods,
    ) {
        $inFile = Redaktilo\File::fromString(<<<'FILE'
            <?php 
                  
            namespace Vendor\Project;
              
            class MyClass
            { 
                const CONSTANT = 42;
                
                public function existingMethod()
                {
                }
            } 
            FILE
        );
        $modelConstructor = (new Model\Method('__construct'))
            ->addArgument(new Model\Argument('Vendor\Project\Dependency', 'dependency'))
            ->addArgument(new Model\Argument('string', 'filename'))
        ;                      
        $insertConstructor = new InsertConstructor($inFile, $modelConstructor);

        $generatedConstructor =<<<'GENERATED_CODE'
                public function __construct(Dependency $dependency, string $redaktiloFilename)
                {
                    $this->dependency = $dependency;
                    $this->filename = $redaktiloFilename;    
                }
            GENERATED_CODE
        ;

        $doesClassAlreadyHaveConstructor->check($inFile)->withReturn(false);

        $doesClassAlreadyHaveMethod->check($inFile)->withReturn(true);
        $prettyPrinter->generateCode($modelMethod)->willReturn($generatedConstructor);
        $insertGeneratedConstructorAboveExistingMethods->insert($generatedConstructor, $inFile)->shouldBeCalled();

        $this->handle($insertConstructor);
    }
```

It no longer has `Redaktilo\Editor`.

It now has:

* `DoesClassAlreadyHaveConstructor->check(Redaktilo\File $inFile): bool`
  - it will call `$this->redaktiloEditor->hasBelow($inFile, InsertConstructorHandler::CONSTRUCTOR, 0)`;
* `DoesClassAlreadyHaveMethods->check(Redaktilo\File $inFile): bool`
  - it will call `$this->redaktiloEditor->hasBelow($inFile, InsertConstructorHandler::METHOD, 0);`
* `InsertGeneratedConstructorAboveExistingMethods->insert(string $generatedConstructor, Redaktilo\File $inFile): void`
  - it will call:
    + `$this->redaktiloEditor->jumpBelow($inFile, InsertConstructorHandler::METHOD, 0);`
    + `$this->redaktiloEditor->insertAbove($inFile, '');`
    + `$this->redaktiloEditor->insertAbove($inFile, $generatedCode);`
    + `$this->redaktiloEditor->insertBelow($inFile, '');`

And it still has:

* `Model\Method`, this is one of the inputs of our use case, it seems fine as is
* `Redaktilo\File`, though the variable has been renamed to `$inFile`
* `PrettyPrinter`, as far as I can tell, this collaborator still describes the behaviour we want

## It's all about trade offs

I've also taken the liberty to rename a couple of things, to make the intent
more explicit:

* `$redaktiloFile` becomes `$inFile`, I've taken a liking to having code read
  like sentences (insert generated code in file)
* `it_inserts_constructor_in_class_that_has_constants_and_methods` becomes
  `it_inserts_constructor_above_methods_but_under_constants_and_properties`,
  as I think that describes the use case a bit better (though in the
  implementation, we end up not caring about constants and properties, as
  we generate the constructor above methods, which we expect to be below
  constants and properties)

But there are more changes that have been introduced as a result of this new
abstraction layer. On the positive side, we got:

+ more readable code -- and by that I mean more explicit intent
+ decoupling our "business logic" from "code we don't own"
  (ie third party library, or "implementation details")

On the negative side:

- we have introduced an abstraction layer
- we'll have to introduce new classes to specify the other scenarios
  (`InsertGeneratedConstructorAtTheEndOfTheClass`
  when there are no methods in the class)

While there is value in the code at the beginning of this article, as it worked
just fine as it was, I personally value the new version more, even with the
drawbacks they bring.

Having an executable specification that results in a code that explicitly
describes its intent is, in my humble opinion, quite a worthy improvement
indeed.

> **Note**: also, while the initial version of the code "worked", it did come
> with its own drawbacks. It takes some time to understand what the code does
> (the "jump above and below" mumbo jumbo isn't very helpful), and it was
> coupled to a third party library, meaning tying us to its upgrade policy
> and making us subject to its backward incompatible changes.

## phpspec isn't a test framework

phpspec is highly opinionated, has very intentional "limitations", and has this
knack of making you feel like something is wrong -- when you're indeed doing
something you shouldn't be doing.

It's not a testing framework, no, it's a designing / modeling tool.
