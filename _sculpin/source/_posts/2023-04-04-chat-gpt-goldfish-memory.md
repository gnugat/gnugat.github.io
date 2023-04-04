---
layout: post
title: "ChatGPT: fluff or not? Goldfish Memory"
tags: ChatGPT
---

Now that a couple of months have passed since its over hyped launch,
surely [ChatGPT](https://openai.com/blog/chatgpt/) has found some
use cases where it could be of any actual use. Or is it all fluff? Let's find out.

In my quest to find a use for ChatGPT in my day to day developer activity,
I've stumbled upon this article:
[a 175-Billion-Parameter Goldfish](https://allenpike.com/2023/175b-parameter-goldfish-gpt),
from [Allen Pike](http://www.twitter.com/apike/).

Granted, this doesn't bring me anywhere close to my goal...
Yet, this peaked my developer interest, by opening a window on some of the
inner workings of ChatGPT.

Let me walk you through my findings about ChatGPT and its Goldfish Memory
problem, so we can learn a thing or two.

## The Goldfish Memory issue

When using ChatGPT, have you often encountered the frustrating
"Goldfish Memory" issue, where it forgets the early conversation's context,
resulting in responses that appear unrelated or inappropriate? 

This problem is due to how Large Language Models (LLMs), like OpenAI's GPT,
work.

They fundamentally are stateless functions that accept one prompt as an input,
and return a completion as an ouptut (I believe the output actually also
contains the prompt).

Consider the following first "user" prompt:

```
Hi, my name is Loïc
```

And its completion:

```
Hello Loïc, it's nice to meet you! How can I assist you today?
```

Now, if we were to send the following second user prompt:

```
What is my name?
```

The LLM wouldn't be able to return the expected completion `Your name's Loïc`,
because they only accept one single prompt, and the name is missing from that
second user prompt.

## LLM, but for chats

To build a chat system similar to ChatGPT, instead of sending directly the
user prompt to the LLM, we can create an "augmented" prompt which contains all
the previous user prompts and their completions, as well as the new user prompt,
in a conversation format:

```
User: Hi, my name is Loïc
Chatbot: Hello Loïc, it's nice to meet you! How can I assist you today?
User: What is my name?
Chatbot:
```

By sending this augmented prompt to the LLM, we'll now be able to get the
expected completion `Your name's Loïc`.

## Prompt Size Limit

But LLMs don't support unlimited sized prompts...

For the sake of the example, let's say the size limit is 5 lines,
and the conversation continued as follow:

```
User: Hi, my name is Loïc
Chatbot: Hello Loïc, it's nice to meet you! How can I assist you today?
User: What is my name?
Chatbot: Your name's Loïc
User: I'm a Lead Developer, my tech stack is: PHP, Symfony, PostgresSQL and git
Chatbot: Do you have any specific questions related to your tech stack?
User: I also follow these methodologies: SCRUM, TDD and OOP
Chatbot: Do you have any topics related to those methodologies that you'd like to discuss?
User: What is my name?
Chatbot:
```

Because of the 5 lines limit, the chat system needs to truncate the augmented
prompt before sending it to the LLM. A common solution seems to only keep the
latest messages. Which means the LLM would end up only getting the following
prompt:

```
Chatbot: Do you have any specific questions related to your tech stack?
User: I also follow these methodologies: SCRUM, TDD and OOP
Chatbot: Do you have any topics related to those methodologies that you'd like to discuss?
User: What is my name?
Chatbot:
```

And this is why ChatGPT is not able to answer the expected `Your name's Loïc`.

> Note: at the time of writing this article, ChatGPT's limit is shared between
> the prompt and the completion:
> * for the `gpt-3.5-turbo` model, the token limit is 4096
> * for `gpt-4` it's 8192
> Before being sent to the LLM, the input text is broken down into tokens:
> `Hi, my name is Loïc` is broken down into the following dictionary
> `['Hi', ',', ' my', ' name', ' is', ' Lo', 'ï', 'c']`, which is then converted
> into the following tokens `[17250, 11, 616, 1438, 318, 6706, 26884, 66]`.
> A single word might be broken down into multiple tokens, and tokenisation
> varies between models. The rule of thumb is to consider that a token is
> equivalent to 3/4 of a word.

## How to enable Infinite Memory?

So. Where do we go from here? How do we enable Infinite Memory for chatbots,
and more broadly LLMs?

One solution would be to periodically summarize parts of the conversation.

The summarization task itself can be done in a separate "summarizing" prompt:

```
Summarize the following conversation in a short sentence, in the past tense:
User: Hi, my name is Loïc
Chatbot: Hello Loïc, it's nice to meet you! How can I assist you today?
User: What is my name?
Chatbot: Your name is Loïc
```

Which should result in a completion similar to:

```
The user introduced themselves as Loïc, and the chatbot confirmed their name when asked.
```

The augmented prompt would then contain the summaries of older messages,
as well as recent ones:

```
Previously:
The user introduced themselves as Loïc, and the chatbot confirmed their name when asked.
The user discussed their tech stack (PHP, Symfony, PostgresSQL and Git) and methodologies (SCRUM, TDD and OOP) as a Lead Developer, and the chatbot asked if they have any specific questions related to them.
User: What is my name?
Chatbot:
```

Now the LLM should be able to give a completion equivalent to:

```
Your name is Loïc. Is there anything else I can help you with related to your tech stack or methodologies as a Lead Developer?
```

And that's the gist of it!

## Takeways

Augmenting the prompt with recent messages, as well as summaries of related
older ones, can allow LLMs to have Infinite Memory!

And that's when the "build a pet project" part of my brain started tingling,
sometimes I just can't resist the urge to build something to get a better
grasp on a concept that's intriguing me...

So I've started to code a small CLI app (with PHP and Symfony of course)
to explore the concepts.

There definitely are some challenges and limits to the summarization approach.

First would be how to select the chunks of conversation to summarize...
Do we create a new summary:

* every 4 messages?
* every hour? every day?
* every time the topic seems to change? How do we detect that?

Next is what summary to include in the prompt:

* a concatenation of all summaries?
* a summary of all the summaries?
* the summaries that are somehow related to the last messages or user prompt?

Which then brings another rabbit hole, namely how to search for relevant
summaries:

* using semantic search?
* using vector database?
* using graph database?

More on that once I've done some progress on the pet project. Anyway.

All in all, while I haven't found a practical use case for ChatGPT in my
day to day developer activity, it still seems worth exploring its potential
for generating content. The quest continues.
