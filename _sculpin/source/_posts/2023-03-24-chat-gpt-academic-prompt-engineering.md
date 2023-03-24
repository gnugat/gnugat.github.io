---
layout: post
title: "ChatGPT: fluff or not? Academic Prompt Engineering"
tags: ChatGPT
---

Now that a couple of months have passed since its over hyped launch,
surely [ChatGPT](https://openai.com/blog/chatgpt/) has found some
use cases where it could be of any actual use. Or is it all fluff? Let's find out.

In my quest to find a use for ChatGPT in my day to day developer activity,
I've stumbled upon this online course website:
[Learn Prompting](https://learnprompting.org/]),
an initiative lead by [Sander Schulhoff](https://trigaten.github.io/),
with contributions from [Towards AI](https://towardsai.net/).

Granted, this doesn't bring me anywhere close to my goal...
Yet, this is in stark contrast to all the resources that I've found so far,
which are usually "hey I tried this hack and it worked", with no explanations
on why.

Let me walk you through the different Prompt Engineering techniques,
and why they work, with some academic backing, so we can learn a thing or two.

> **Note**: It was extremely tempting to describe how ChatGPT works,
> but I didn't want the explanations to detract from the focus of the article
> (which is academic backed prompt engineering).
> I recommend these short articles for a detailed explanations:
> * [GPT 3.5 model](https://iq.opengenus.org/gpt-3-5-model/)
> * [Everything I (Vicki Boykis) understand about ChatGPT](https://gist.github.com/veekaybee/6f8885e9906aa9c5408ebe5c7e870698)

## [X-Shot Prompting](https://learnprompting.org/docs/basics/standard_prompt)

X-Shot prompting allows Large Language Models to improve their accuracy,
on previously unseen data, without the need to update their training parameters,
by including examples in the prompt:

```
Extract the brand, product name and format from this item "Magnum White Chocolate Ice Cream 8 x 110 ml":
* brand: Magnum
* product name: White Chocolate Ice Cream
* format: 8 x 110 ml

Extract the brand, product name and format from this item "Birds Eye Garden Peas, 375g (Frozen)":
* brand: Birds Eye
* product name: Garden Peas
* format: 375g

Extract the brand, product name and format from this item "PG tips 160 Original Tea Bags":
* brand: PG tips
* product name: Original Tea Bags
* format: 160

Extract the brand, product name and format from this item "233g, Golden Eggs Chocolate Egg, Galaxy":
```

There's a distinction between Few-Shot, One-Shot and Zero-Shot prompting
(referring to how many examples are included in the prompt).

Isn't Zero-Shot prompting just... Prompting? Well X-Shot isn't just about
having examples in the prompt, it's mainly about the capability of the model
to perform better on new data it wasn't trained on, so we're going to see
that "Zero-Shot" term used in conjunction with other techniques.

> See also, [Kris - All About AI](https://www.allabtai.com/)'s article:
> [X-Shot Prompting](https://www.allabtai.com/prompt-engineering-tips-zero-one-and-few-shot-prompting/)

## [Chain of Thought Prompting](https://learnprompting.org/docs/intermediate/chain_of_thought)

Few-Shot Chain of Thought prompting allows Large Language Models
to perform better on logic based tasks (such as solving arithmetic,
commonsense, and symbolic problems) by including in the examples
the reasoning steps:

```
Q: Roger has 5 tennis balls. He buys 2 more cans of tennis balls.
Each can has 3 tennis balls. How many tennis balls does he have now?

A: Roger started with 5 balls. 2 cans of 3 tennis balls each is 6 tennis balls.
5 + 6 = 11. The answer is 11.

Q: The cafeteria had 23 apples. If they use 20 to make lunch and bought 6 more,
how many apples do they have?
```

Zero-Shot Chain of Thought prompting can also be used to get better results
for these tasks, by including in the prompt a request to detail the reasoning
steps:

```
A juggler can juggle 16 balls. Half of the balls are golf balls,
and half of the golf balls are blue. How many blue golf balls are there?
Let's think step by step.
```

More specifically, ending the prompt with `Let's think step by step` proved
to provide the best results
(claim backed in the paper [CoT Prompting Elicits Reasoning in LLM](https://arxiv.org/abs/2201.11903)).

## [Generated Knowledge prompting](https://learnprompting.org/docs/intermediate/generated_knowledge)

Generated Knowledge prompting allows Large Language Models to perform better
on commonsense reasoning by having a first prompt requesting the generation
of knowledge on a topic, and then incorporating the output in a second prompt
that requests top perform the related commonsense task.

Here's the first prompt asking for knowledge generation:

```
Write 5 facts about test driven development
```

Then the second prompt which incorporates the output for the first prompt:

```
Here are 5 facts about TDD:
1. Test-driven development (TDD) is a software development process that emphasizes the creation of automated tests before any code is written. In TDD, developers write a failing test case first, then write code to pass the test, and then refactor the code to improve it.
2. TDD helps to ensure that the code is working correctly by testing it at every step of the development process. By creating tests first, developers can also ensure that their code meets the requirements and specifications of the project.
3. TDD can be used with a variety of programming languages and frameworks, and it is often used in agile development methodologies. It can also be used in combination with other testing techniques, such as behavior-driven development (BDD) and acceptance test-driven development (ATDD).
4. TDD can result in improved code quality, as developers are forced to think more deeply about the design of their code and the potential edge cases that their code may encounter. TDD can also result in faster development times, as bugs are caught early in the development process and can be fixed before they cause more significant issues.
5. TDD is not a silver bullet solution for software development and may not be suitable for all projects or teams. It can require additional time and effort upfront to write tests and ensure that they are passing, and it may require a cultural shift in the development team to fully adopt the TDD methodology.

With TDD, can I first write code that fails, then write a test and finally refactor the code to make the test pass?
```

> _Note: I've seen this as also being referred to as Chain Prompting._

## Takeways

The following prompt engineering techniques are proven by studies to improve
the output quality of Large Language Models:

* X-Shot: include examples in the prompt
* Chain of Thought: end the prompt with `Let's think step by step`
* Knowlegde Generated:
  * first ask to generate facts on a topic
  * then ask a question on the topic, including the previously generated facts

All in all, while I haven't found a practical use case for ChatGPT in my day to day developer activity,
it still seems worth exploring its potential for generating content. The quest continues.
