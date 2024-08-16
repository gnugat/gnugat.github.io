---
layout: post
title: "phpspec tip: don't mock SUT inputs"
tags:
    - phpspec
    - tdd
---

Looking at some old code of mine, I've found the following test:

```php
<?php

namespace spec\Memio\SpecGen\GenerateMethod;
  
use Memio\Model\File;
use Memio\Model\Method;
use Memio\Model\Objekt;
use Memio\SpecGen\GenerateMethod\GeneratedMethod;
use PhpSpec\Console\ConsoleIO;
use PhpSpec\ObjectBehavior;

class LogGeneratedMethodListenerSpec extends ObjectBehavior
{   
    function let(ConsoleIO $io)
    {
        $this->beConstructedWith($io);
    }

    function it_logs_the_generated_method(ConsoleIO $io, File $file, Method $method, Objekt $object)
    {
        $className = 'Vendor\Project\MyClass';
        $methodName = 'myMethod';
        $generatedMethod = new GeneratedMethod($file->getWrappedObject());
        $file->getStructure()->willReturn($object);
        $object->getName()->willReturn($className);
        $object->allMethods()->willReturn([$method]);
        $method->getName()->willReturn($methodName);
 
        $io->write(<<<OUTPUT
 
  <info>Generated <value>{$className}#{$methodName}</value></info>
 
 OUTPUT
        )->shouldBeCalled();

        $this->onGeneratedMethod($generatedMethod);
    }
}
```

And while reading it, one of the things that caught my attention was
**the setting up of mocks for SUT inputs**
(SUT means System Under Test, the class we're testing).

The purpose of this test is to specify how `LogGeneratedMethodListener` should
behave, through its interactions with the `ConsoleIO` collaborator.

But here, it's also specifying how `LogGeneratedMethodListener` interacts
with the input parameter `GeneratedMethod`.

`GeneratedMethod` encapsulates data relevant to the process of generating the
code for a Method. It doesn't have any critical behaviour:
we just call getters on it.

So my advice to you (me, from the past), would be to not bother creating Mocks
for it:

```php
<?php

namespace spec\Memio\SpecGen\GenerateMethod;
  
use Memio\Model\File;
use Memio\Model\Method;
use Memio\Model\Objekt;
use Memio\SpecGen\GenerateMethod\GeneratedMethod;
use PhpSpec\Console\ConsoleIO;
use PhpSpec\ObjectBehavior;

class LogGeneratedMethodListenerSpec extends ObjectBehavior
{   
    function let(ConsoleIO $io)
    {
        $this->beConstructedWith($io);
    }

    function it_logs_the_generated_method(ConsoleIO $io)
    {
        $className = 'Vendor\Project\MyClass';
        $methodName = 'myMethod';
        $generatedMethod = new GeneratedMethod((new File('src/MyClass.php'))
            ->setStructure((new Objekt($className))
                ->addMethod(new Method($methodName))
            )
        );
 
        $io->write(<<<OUTPUT
 
  <info>Generated <value>{$className}#{$methodName}</value></info>
 
 OUTPUT
        )->shouldBeCalled();

        $this->onGeneratedMethod($generatedMethod);
    }
}
```
