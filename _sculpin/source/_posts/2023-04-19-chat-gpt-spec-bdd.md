---
layout: post
title: "ChatGPT: fluff or not? SpecBDD"
tags:
    - ChatGPT
    - TDD
    - BDD
    - specBDD
    - specgen
    - phpspec
    - phpunit
---

Now that a couple of months have passed since its over hyped launch,
surely [ChatGPT](https://openai.com/blog/chatgpt/) has found some
use cases where it could be of any actual use. Or is it all fluff? Let's find out.

In my quest to find a use for ChatGPT in my day to day developer activity,
I've finally found a helpful scenario!

Let me walk you through my findings about ChatGPT and its "Spec Gen" capacity,
so we can learn a thing or two.

## Spec Gen

When tasked to write a feature, I first write a unit test that specifies the
behaviour, for example:

```
<?php

namespace spec\Vendor\Project;

use Vendor\Project\Service\Filesystem;
use Vendor\Project\File;
use PhpSpec\ObjectBehavior;

class TextEditorSpec extends ObjectBehavior
{
    private const FILENAME = '/tmp/file.txt';
    private const FORCE_FILE_CREATION = true;

    function let(Filesystem $filesystem): void
    {
        $this->beConstructedWith($filesystem);
    }

    function it_creates_new_files(File $file, Filesystem $filesystem): void
    {
        $filesystem->exists(self::FILENAME)->willReturn(false);
        $filesystem->create(self::FILENAME)->willReturn($file);

        $this->open(self::FILENAME, self::FORCE_FILE_CREATION)->shouldBe($file);
    }
}
```

When using [phpspec](https://phpspec.net/en/stable/),
especially with the extension [spec-gen](https://github.com/memio/spec-gen),
running the test will bootstrap for me the corresponding class:

```
<?php

namespace Vendor\Project;

use Vendor\Project\Service\Filesystem;

class TextEditor
{
    private $filesystem;

    public function __construct(Filesytem $filesystem)
    {
        $this->filesystem = $filesystem;
    }

    public function open(string $argument1, bool $argument2)
    {
    }
}
```

That's pretty good, but it could be better: what if it was able to generate the complete code?

## GPT Gen

Let's forget about phpspec and use instead [PHPUnit](https://phpunit.de/),
but still with the [Prophecy](https://github.com/phpspec/prophecy)
Mocking framework.

Let's ask ChatGPT. Here's the priming prompt:

> **USER**:
> Act as an expert PHP developer,
>   who's been writing high quality API code for 20 years.
> Acknowledge with "ok".

Because ChatGPT's Large Language Model (LLM) is able to generate a wide range
of text (conversation, essays, movie script, poetry, etc), assigning it a role
helps it narrow down its context, hence improving its accuracy for the task we
want it to complete: writing PHP code, on a professional level
(persona/role prompt engineering technique).

We also need to consider the Goldfish Memory issue of ChatGPT: it only takes
into account the last ~4000 tokens to generate its response, so asking it to
give us a short reply helps us save some space.

> **ChatGPT**: ok

LLMs perform better when given some examples, and indeed before asking it to
generate code we might want to give ChatGPT some of our code samples
(X-Shot prompt engineering technique).

Since coding also requires some level of logic, it is also helpful to include
reasoning steps (Chain of Thought prompt engineering technique).

Similarly, asking the LLM to first generate some topic related knowledge,
and then reuse that in the further prompts will also increase our success rate
(Generated Knowledge prompt engineering technique).

With this in mind, here's the second prompt that provides a test class example:

> **USER**: Here's an example of test class from the project you're working on:

```
<?php

declare(strict_types=1);

namespace tests\Ssc\Btlr\Cht\Message\Templates\Prompts;

use Ssc\Btlr\App\Filesystem\ReadFile;
use Ssc\Btlr\App\Template\Replace;
use Ssc\Btlr\Cht\Message\Logs\Type;
use Ssc\Btlr\Cht\Message\Logs\WriteLog;
use Ssc\Btlr\Cht\Message\Templates\Prompts\Template;
use tests\Ssc\Btlr\AppTest\BtlrServiceTestCase;

class TemplateTest extends BtlrServiceTestCase
{
    /**
     * @test
     */
    public function it_creates_prompt_from_template(): void
    {
        // Fixtures
        $thoseParameters = [
            'last_messages' => 'USER (1968-04-02T18:40:23+00:00): Write code for me, please',
        ];
        $forType = Type::AUGMENTED_PROMPT;
        $withConfig = [
            'chunk_memory_size' => 15,
            'llm_engine' => 'chatgpt-gpt-3.5-turbo',
            'logs_filename' => './var/cht/logs',
            'prompt_templates_filename' => './templates/cht/prompts',
        ];

        $template = "LAST MESSAGES:\n%last_messages%\nBTLR:\n";
        $prompt = "LAST MESSAGES:\n{$thoseParameters['last_messages']}\nBTLR:\n";
        $data = [
            'entry' => $prompt,
        ];

        // Dummies
        $readFile = $this->prophesize(ReadFile::class);
        $replace = $this->prophesize(Replace::class);
        $writeLog = $this->prophesize(WriteLog::class);

        // Stubs & Mocks
        $readFile->in("{$withConfig['prompt_templates_filename']}/{$forType['name']}.txt")
            ->willReturn($template);
        $replace->in($template, $thoseParameters)
            ->willReturn($prompt);
        $writeLog->for($data, $forType, $withConfig)
            ->shouldBeCalled();

        // Assertion
        $template = new Template(
            $readFile->reveal(),
            $replace->reveal(),
            $writeLog->reveal(),
        );
        self::assertSame($prompt, $template->replace(
            $thoseParameters,
            $forType,
            $withConfig,
        ));
    }
}
```

> **USER**:
> Acknowledge by describing how the use of fixtures, dummies, stubs, mocks
> and assertions allow to make sure the tested code is behaving as expected.
> And note the use of the special BtlrServiceTestCase parent class for `TemplateTest`.

By the way, the code is from my Super Secret Code project
[Btlr](https://github.com/gnugat/ssc-btlr).

Here's ChatGPT's response:

> **ChatGPT**:
> In this test class, fixtures are used to provide the necessary data for
> testing the `Template` class. The parameters and configuration are defined in
> `$thoseParameters` and `$withConfig` respectively, and the template and prompt
> strings are defined in `$template` and `$prompt`.
>
> Dummies are used to provide the interface of the `ReadFile`, `Replace`, and
> `WriteLog` classes, without providing any actual implementation, since these
> classes are not the focus of the test.
>
> Stubs are used to replace the implementation of `ReadFile` and `Replace`
> classes, by returning a fixed value when their respective methods are called.
> This ensures that the expected values are used for testing the `Template` class.
>
> Mocks are used to verify that the `WriteLog` class is called with the expected
> parameters. The `shouldBeCalled()` method ensures that the `for()` method of
> `WriteLog` class is actually called during the test.
>
> Finally, the assertion compares the result returned by the `replace()` method
> of the `Template` class with the expected prompt string.
> 
> The `BtlrServiceTestCase` class is a special parent class that sets up a test
> environment for the Btlr service, which can include initializing dependencies,
> connecting to databases, and setting up configurations. This helps to ensure
> that tests are run in a consistent and isolated environment, and makes it easier
> to write tests for the Btlr service.

ChatGPT doesn't have access to the project and its code, it only knows what we've
provided in the conversation so far.

So for example it took a wild guess at what `BtlrServiceTestCase` does and got
it wrong, but for our purpose this is good enough.

The third prompt is an example of the corresponding class:

> **USER**:
> When tasked with generating the corresponding `Template` class, from the above
> `TemplateTest` test class, here's the code you wrote:

```
<?php

declare(strict_types=1);

namespace Ssc\Btlr\Cht\Message\Templates\Prompts;

use Ssc\Btlr\App\Filesystem\ReadFile;
use Ssc\Btlr\App\Template\Replace;
use Ssc\Btlr\Cht\Message\Logs\WriteLog;

class Template
{
    public function __construct(
        private ReadFile $readFile,
        private Replace $replace,
        private WriteLog $writeLog,
    ) {
    }

    public function replace(
        array $thoseParameters,
        array $forType,
        array $withConfig,
    ): string {
        $template = $this->readFile->in(
            "{$withConfig['prompt_templates_filename']}/{$forType['name']}.txt",
        );
        $prompt = $this->replace->in($template, $thoseParameters);
        $this->writeLog->for([
            'entry' => $prompt,
        ], $forType, $withConfig);

        return $prompt;
    }
}
```

> **USER**: Acknowledge by describing how the test class got translated into its
> corresponding class.

To which ChatGPT replies:

> **ChatGPT**:
> The `TemplateTest` test class served as a guide for implementing the
> `Template` class.
>
> First, the constructor of `Template` class takes three dependencies, which
> are also injected in the `TemplateTest` class as dummies or mocks.
>
> Next, the `replace()` method of `Template` class has the same signature as
> the test method `it_creates_prompt_from_template()`, with the addition of a
> return type declaration for the prompt string.
> 
> The implementation of `replace()` method in `Template` class uses the
> injected `ReadFile` instance to read the template string from the filesystem,
> using the `$forType['name']` parameter to construct the file path.
> It then uses the injected `Replace` instance to replace placeholders in the
> template with values provided in the `$thoseParameters` array, resulting in
> a `$prompt` string.
>
> Finally, the method calls the injected `WriteLog` instance with the `$prompt`,
> `$forType`, and `$withConfig` parameters, which logs the prompt for the given
> type and configuration.
>
> Overall, the implementation of the `Template` class closely follows the
> structure of the `TemplateTest` class, and the use of dependency injection
> ensures that the class can be easily tested in isolation from its
> dependencies.

With ChatGPT noting that the corresponding class closely follows the structure
of its test, it should be now ready.

Let's give it a new test class, and ask it to generate the corresponding code:

> **USER**: Brilliant. Now, in the same coding style as `TemplateTest` and
> `Template`, you are tasked to write a the corresponding code for the
> following `ReplyTest` test class:

```
<?php

declare(strict_types=1);

namespace tests\Ssc\Btlr\Cht\Message;

use Ssc\Btlr\Cht\Message\Logs\Type;
use Ssc\Btlr\Cht\Message\Logs\WriteLog;
use Ssc\Btlr\Cht\Message\Memory\Consolidate;
use Ssc\Btlr\Cht\Message\Reply;
use Ssc\Btlr\Cht\Message\Reply\Augment;
use Ssc\Btlr\Cht\Message\Reply\UsingLlm;
use tests\Ssc\Btlr\AppTest\BtlrServiceTestCase;

class ReplyTest extends BtlrServiceTestCase
{
    /**
     * @test
     */
    public function it_replies_to_user_prompt_using_llm(): void
    {
        // Fixtures
        $userPrompt = 'Write code for me, please';
        $withConfig = [
            'chunk_memory_size' => 15,
            'llm_engine' => 'chatgpt-gpt-3.5-turbo',
            'logs_filename' => './var/cht/logs',
            'prompt_templates_filename' => './templates/cht/prompts',
        ];

        $userPromptData = [
            'entry' => $userPrompt,
        ];
        $augmentedPrompt = "USER: {$userPrompt}\nBLTR:";
        $modelCompletion = "I'm sorry, dev. I'm afraid I can't do that.";
        $modelCompletionData = [
            'entry' => $modelCompletion,
            'llm_engine' => $withConfig['llm_engine'],
        ];

        // Dummies
        $augment = $this->prophesize(Augment::class);
        $consolidate = $this->prophesize(Consolidate::class);
        $usingLlm = $this->prophesize(UsingLlm::class);
        $writeLog = $this->prophesize(WriteLog::class);

        // Stubs & Mocks
        $writeLog->for($userPromptData, Type::USER_PROMPT, $withConfig)
            ->shouldBeCalled();
        $augment->the($userPrompt, $withConfig)
            ->willReturn($augmentedPrompt);
        $usingLlm->complete($augmentedPrompt)
            ->willReturn($modelCompletion);
        $writeLog->for($modelCompletionData, Type::MODEL_COMPLETION, $withConfig)
            ->shouldBeCalled();
        $consolidate->memories($withConfig)
            ->shouldBeCalled();

        // Assertion
        $reply = new Reply(
            $augment->reveal(),
            $consolidate->reveal(),
            $usingLlm->reveal(),
            $writeLog->reveal(),
        );
        self::assertSame($modelCompletion, $reply->to(
            $userPrompt,
            $withConfig,
        ));
    }
}
```

> **USER**: Acknowledge by generating the code for the `Reply` class.

And here's what ChatGPT came up with:

> **ChatGPT**: Sure thing! Here's the code for the `Reply` class based on the
> `ReplyTest` test class:

```
<?php

declare(strict_types=1);

namespace Ssc\Btlr\Cht\Message;

use Ssc\Btlr\Cht\Message\Logs\Type;
use Ssc\Btlr\Cht\Message\Logs\WriteLog;
use Ssc\Btlr\Cht\Message\Memory\Consolidate;
use Ssc\Btlr\Cht\Message\Reply\Augment;
use Ssc\Btlr\Cht\Message\Reply\UsingLlm;

class Reply
{
    public function __construct(
        private Augment $augment,
        private Consolidate $consolidate,
        private UsingLlm $usingLlm,
        private WriteLog $writeLog,
    ) {
    }

    public function to(string $userPrompt, array $withConfig): string
    {
        $userPromptData = [
            'entry' => $userPrompt,
        ];

        // Augment the user prompt
        $augmentedPrompt = $this->augment->the($userPrompt, $withConfig);

        // Use LLM to generate a model completion
        $modelCompletion = $this->usingLlm->complete($augmentedPrompt);

        // Log the user prompt and model completion
        $this->writeLog->for($userPromptData, Type::USER_PROMPT, $withConfig);
        $modelCompletionData = [
            'entry' => $modelCompletion,
            'llm_engine' => $withConfig['llm_engine'],
        ];
        $this->writeLog->for($modelCompletionData, Type::MODEL_COMPLETION, $withConfig);

        // Consolidate the memories
        $this->consolidate->memories($withConfig);

        return $modelCompletion;
    }
}
```

> **ChatGPT**: This `Reply` class has a `to` method that takes a user prompt
> and a configuration array as input, and returns the model completion
> generated by LLM.
> The `Reply` class constructor takes in four dependencies: `Augment`,
> `Consolidate`, `UsingLlm`, and `WriteLog`, and stores them as private
> properties.
> The `to` method then uses these dependencies to augment the user prompt,
> generate the model completion, log both the user prompt and the model
> completion, and consolidate the memories.

Which is pretty much spot on.

I'd personnally have written something slightly different (no comments, have
 `writeLog` for the user prompt at the begining of the method, and possibly
not have any intermediate variables).

But I can easily apply those changes!

## Takeways

Thanks to Prompt Engineering (with techniques such as Role / Persona priming
prompt, X-Shot, Chain of Thought and Generated Knowledge), it is possible
to ask ChatGPT to generate code.

I'm personally using the following prompts to generate the corresponding code
for a given Test Class.

Priming Prompt:

> Act as an expert PHP developer, who's been writing high quality API code for 20 years.
> Acknowledge with "ok".

Test Class example prompt:

> Here's an example of test class from the project you're working on:
>
> `%example_test_class_code%`
>
> Acknowledge by describing how the use of fixtures, dummies, stubs, mocks
> and assertions allow to make sure the tested code is behaving as expected.
> And note the use of the special BtlrServiceTestCase parent class for
> `%example_test_class_name%`.

Corresponding class example prompt:

> When tasked with generating the corresponding `%example_class_name%` class,
> from the above `%%example_test_class_name` test class, here's the code you wrote:
>
> `%example_class_code%`
>
> Acknowledge by describing how the test class got translated into its
> corresponding class.

Code generation request from Test Class prompt:

> Brilliant. Now, in the same coding style as `%example_test_class_name%` and
> `%example_class_name%`, you are tasked to write a the corresponding code for
> the following `%test_class_name%` test class:
>
> `%test_class_code%`
>
> Acknowledge by generating the code for the `%class_name%` class.

Now, what if you're not practicing Test Driven Development?

I suppose you can tweek it to get ChatGPT to generate tests for you:

* Use the same priming prompt
* Then use the class example prompt
* Next use the "corresponding" test example prompt
* Finally provide a class and ask ChatGPT to generate its corresponding test

All in all, the exploration of ChatGPT's text generation potential turned out
to be quite worthwhile, as I ended up finding a practical use case for it in my
day to day developer activity.

Yet I suspect there's plenty more scenarions where ChatGPT can help, so I guess
the quest continues.
