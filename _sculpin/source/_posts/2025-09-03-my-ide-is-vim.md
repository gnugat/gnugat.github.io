---
layout: post
title: My IDE is Vim
tags:
    - introducing-tools
    - Vim
---

> The keyboards leak molten steel, as Vim motions carve runes through silicon,
> the code prostrates itself before the LSP's omniscient eye:
>
> * autocomplete rain Valhalla's arrows
> * diagnostics burn syntax errors and typos alike
> * go-to-definition shatters dimensional barriers like the Bifrost's rainbow bridge
>
> phpactor descends as the shape-shifting overlord who bends variables and
> transmutes classes into monuments of perfect refactors.
>
> XDebug breakpoints become lightning-riders galloping through Vim buffers.

In this article, I'll discuss why Vim is my favourite IDE
(not test/code editor, no, fully fledged IDE).

* [My history with IDEs](#my-history-with-ides)
* [Why Vim](#why-Vim)
* [What is an IDE](#what-is-an-ide)
* [Vim Motions](#vim-motions)
* [Conclusion](#conclusion)

## My history with IDEs

I started my programming journey in 2004 on [Smultron](https://en.wikipedia.org/wiki/Smultron),
since I was told the go-to app was Notepad++, but my parents had a mac.

When I migrated to Ubuntu in 2006, I simply switched to Gedit.
I remember learning vi at the time, just to be able to do things while ssh-ing
onto remote servers.

It was at University, in 2008, that I started to use a proper IDE: Emacs,
which was mandatory for all students.
I didn't mind though as I was happy to level up my geekiness,
and by that time I was developing a strong preference for the terminal.

But during my multiple internships and apprenticeships,
I was told that professionals used proper IDEs, and was made to use Eclipse and NetBeans.

I have to say I was never impressed with the lack of responsiveness from these tools.

When I started to work at SensioLabs in 2013, frustrated with how slow these IDEs were,
I switched to Sublime Text.

When I moved to the UK in 2014 and started to work for the startup Constant.Co,
I continued to use Sublime Text, to my colleague's amusement.

In 2015, Adam, who'd become our VP of Engineering, joined and we had a lot of
extremely interesting conversations. One of the many things he told me, which stuck with me,
regarding Text / Code Editors versus IDEs was:

> It's not the tool that matters, it's how well you learn, understand and use it.

This is when I decided to drop Sublime Text. And use Vim instead.

Before I talk more about Vim, I want to mention that after joining Telum Media in 2024,
I was made to use PhpStorm as it was mandatory. Same policy when I joined Bumble in 2025.

## Why Vim

In terms of preference, the terminal has always taken precedence over
the Graphical User Interface for me, and I tend to favour using the keyboard
(and shortcuts) over the mouse and gestures.

In retrospect, I think there's also a lot of noise that comes with the default
interface of Eclipse, NetBeans and PhpStorm, which I personally find distracting.

So I considered the two options in front of me: Emacs or Vim?
After finding out that Vim motions were supported in other IDEs, I made my choice.

## What is an IDE

> Why don't you use a proper IDE?

This is a question I often get when I mention I use Vim.

A "proper" IDE provides:

* syntax highlighting
* autocompletion, documentation
* diagnostics (marking errors and warnings)
* project navigation with: go to definition, find reference and usage
* refactoring actions

By integrating Vim with [LSP](https://en.wikipedia.org/wiki/Language_Server_Protocol)
we get all the features listed above.

Another important feature of IDEs is:

* step debugging

As it turns out, it's also possible to integrate Vim with those (eg xdebug).

Other integration, that some might add to the list of important things, are:

* testing (eg phpunit)
* version control (eg git)
* AI tooling (eg copilot)

These are also possible, but personally I much prefer to use directly the tools
for these from the terminal.

So. Can anyone let me know what I'm missing out from Vim, that I'd be getting
from "proper" IDEs?

## Vim Motions

Perhaps the biggest argument in favour of Vim would be the **Motions**:

* `h`, `j`, `k`, `l`: move one character Left, Down, Up, Right (LDUR)
* `0`, `^`, `$`: move to the first character of the line, first non whitespace character, last character
* `f{char}`, `t{char}`: move to next occurrence of character in the line, on the character or before it

They can be **Composed** with operators:

* `d`: deleting
* `y`: yank, aka copying
* `p`: paste
* `c`: change

For more Precision, **Text Objects** can be used:

* `w`: a word
* `s`: a sentence
* `p`: a paragraph

Here are a couple of examples:

* `dt;`: delete, until, character `;`: to cut everything before the semi colon
* `ci'`: change, inside, simple quotes: to replace text inside single quotes
  (works with double quote, parenthesis, curly braces, etc)

Making one's changes repeatable will unleash even more power:

* `d23d`: delete 23 lines
* `.`: replay previous action
* `qa`: register keystrokes in register `a`
* `@a`: replay keystrokes from register `a`

While there is a lot to learn, I'd say the Vim motions aren't too difficult to
memorize since they are mnemonic as much as possible.

They also have some logic in terms of direction: lowercase is forward
(`yf `: copy from cursor to next space, space included) and uppercase is backward
(`yF `: copy from cursor to _previous_ space, space included).

But I can attest that there's a lot to learn, and it's easy to plateau.
I've personally stuck with a small subset of these for a decade,
and have only decided this year (2025) to learn more (macros are AMAZING).

## Conclusion

When I was mandated to use PhpStorm at Telum Media in 2024,
I decided to give it a fair chance and use it exactly as intended.
But I wasn't convinced I gained any efficiency compared to Vim.

When the same requirement came up at Bumble in 2025,
I took a different approach: minimalistic UI, Vim motions enabled
(though support isn't perfect: I experienced issues with macros, for example).

This compromise will likely be my path forward: use Vim when possible,
and configure whatever I'm required to use to feel as Vim-like as possible.

The broader lesson? Unless there's a compelling reason,
forcing developers away from tools they've mastered is counterproductive.

Listen to Adam's wise advice:
Deep knowledge of one's workflow, getting proficient with one's tool
and seeking improvement matters more
than whatever software happen to be the most popular.
