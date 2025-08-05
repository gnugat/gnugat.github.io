---
layout: post
title: My Dotfiles
tags:
    - introducing-methodology
---

Through the storm of scattered settings, your [dotfiles](https://dotfiles.github.io/)
emerge as the lightning-born shepherds that bind chaos to your will.

* [Why?](#why)
* [What are dotfiles?](#what-are-dotfiles)
* [How to manage them?](#how-to-manage-them)
* [My system](#my-system)
* [My Framework](#my-framework)
* [Conclusion](#conclusion)

## Why?

[My dotfiles repository](https://github.com/gnugat/dotfiles) is how I backup,
restore and synchronise my shell / system preferences and settings.

I felt the need to do so back in 2014, when I had 3 computers
(personal desktop, personal laptop and work laptop) and wanted to keep the same
config across the different devices.

I now have one single device, yet this has proven very useful over the years,
especially any time I upgraded to a new device.

A decade ago, I tried my best to come up with a system that would:

* be simple
* be flexible
* stand the test of time

I'm happy to report I was successful in this,
and I was even able to add cross platform compability (macOS) in 2025.

## What are dotfiles?

The configuration files for most UNIX tools usually start with a dot (`.`),
hence the name "dot files".

Examples of such files are:

* `.bashrc`, configuring the bash shell
* `.vimrc`, setting up the powerful IDE
* `.gitconfig`, instructing git about your personal preferences

## How to manage them?

It's only this year that I started researching solutions on how to manage
dotfiles, in order to add support for macOS. There are so many tools:

* [GNU stow](https://www.gnu.org/software/stow/), which symlinks the files from your dotfiles repo
  to your home directory
* [chezmoi](https://www.chezmoi.io/), which adds templates and password manager support
* [yadm](https://yadm.io/), stands for Yet Another Dotfiles Manager,
  is similar to chezmoi but less complex
* [Nix home manager](https://github.com/nix-community/home-manager),
  which makes any changes to your configuration idempotent

I got really interested in [Ansible](https://docs.ansible.com/), which promised
to set up my computers in an automated way.

But then I realise the size of the configuration files were way longer than if
I did it in a simple bash script. I also didn't like the idea to have to learn,
and maintain knowledge of yet another tool.

So in the end I decided to stick with what I had set up.
And cross platform compatibility turned out to be a breeze to implement!

## My system

[My dotfile repository](https://github.com/gnugat/dotfiles) follows this file tree structure:

```
.
├── <xy>-<package>/
│   ├── _<package-manager>.sh
│   ├── config/
│   ├── install.sh
│   └── README.md
└── install.sh
```

The root `install.sh` script is just here to iterate through each **package**
sub directories, it'll find the local `install.sh` there and execute it.

Examples of packages I have there are:

```
.
├── 12-bash/
├── 13-curl/
├── 14-less/
├── 21-git/
├── 22-php/
├── 23-vim/
├── 24-tree/
└── 25-ack/
```

As for an example of what the inside of a package sub directory looks like:

```
12-bash/
├── _apt.sh
├── _brew.sh
├── config/
│   ├── bashrc
│   ├── prompt.sh
│   └── shopt.sh
├── install.sh
└── README.md
```

The role of the package's `install.sh` script is to:

1. call the appropriate `_<package-manager>.sh` script (`apt` for Ubuntu, `brew` for macOS)
2. copy / symlink the config from the repo to `~/.config`
3. execute any additional installation steps (eg install vim plugins, or register Environment Variables, etc)

For instance, here's the `install.sh` for bash:

```bash
#!/usr/bin/env bash
# File: /12-bash/install.sh
# ──────────────────────────────────────────────────────────────────────────────
# 💲 bash - GNU Bourne-Again SHell
# ──────────────────────────────────────────────────────────────────────────────

_SSDF_PACKAGE_DIR="$(dirname "$(readlink -f "${BASH_SOURCE[0]:-$0}")")"
SSDF_ROOT_DIR="$(realpath "${_SSDF_PACKAGE_DIR}/..")"
source "${SSDF_ROOT_DIR}/00-_ssdf/functions.sh"

_SSDF_PACKAGE_NAME="bash"

_ssdf_echo_section_title "Installing ${_SSDF_PACKAGE_NAME}..."

## ─────────────────────────────────────────────────────────────────────────────
## 📦 Call to `./_<package-manager>.sh` script.
## ─────────────────────────────────────────────────────────────────────────────

_ssdf_select_package_manager
_ssdf_install_with_package_manager "${_SSDF_PACKAGE_DIR}" "${SSDF_PACKAGE_MANAGER}"

## ─────────────────────────────────────────────────────────────────────────────
## 🔗 Symbolic links.
## ─────────────────────────────────────────────────────────────────────────────

mkdir -p "${HOME}/.config/bash"
cp -i "${_SSDF_PACKAGE_DIR}/config/bashrc" "${HOME}/.bashrc"
ln -nsf "${_SSDF_PACKAGE_DIR}/config/prompt.sh" "${HOME}/.config/bash/prompt.sh"
ln -nsf "${_SSDF_PACKAGE_DIR}/config/shopt.sh" "${HOME}/.config/bash/shopt.sh"

## ─────────────────────────────────────────────────────────────────────────────
## ➕ Additional config / install
## ─────────────────────────────────────────────────────────────────────────────

if [ -e "${HOME}/.bashrc" ]; then
    _ssdf_append_source \
        "${HOME}/.bashrc" \
        "${HOME}/.config/shell/common.sh"
    _ssdf_append_source \
        "${HOME}/.config/shell/prompt.local.sh" \
        "${HOME}/.config/bash/prompt.sh"
fi

_ssdf_echo_success "${_SSDF_PACKAGE_NAME} installed"

## ─────────────────────────────────────────────────────────────────────────────
## 🧹 Cleaning up local variables
## ─────────────────────────────────────────────────────────────────────────────

_ssdf_unset_envvars
```

## My Framework

> **Note**: Nothing you need to know or do in this section.
> But for the curious, here goes nothing!

Initially the scripts would use directly commands and bash syntax,
but in 2025 with the need for cross platform compatibility I've decided to create
a set of helper functions: they can be found in the
[ssdf](https://github.com/gnugat/dotfiles/tree/main/00-_ssdf) directory
(SSDF stands for Super Secret DotFiles).

Inside, we can find helpful documentation:

* how to use v3 compatible bash arrays,
  [the forever default version on macOS](https://apple.stackexchange.com/questions/238278/why-does-os-x-have-bash-v3-2-57)
* how to import (source) bash scripts using relative paths
* how BSD (macOS) and GNU (Ubuntu) sed differs

We can also find some cross platform scripts (`sed` and `grep <x> | sed`).

And we can find some functions which I use in the different scripts:

* `_ssdf_prepend_path "${HOME}/bin" "${HOME}/.local/bin"`:
  Prepends `bin` and `.local/bin` to PATH, if they exist and aren't already added
* `_ssdf_append_envvar ~/.config/shell/envvars.local.sh "ACKRC" "${HOME}/.config/ack/ackrc"`:
  Appends to `~/.config/shell/envvars.local.sh` the `ACKRC` with `~/.config/ack/ackrc`
* `_ssdf_unset_envvars`:
  [🗑️ Garbage Collectooooooooooooor~ 🎶🤘](https://www.youtube.com/watch?v=yup8gIXxWDU&t=185s)

---

Last but not least, the `quarry` (of Creation) folder is a repository of Blocks:
reusable templates that help bootstrap or extend packages.

Let's say I want to add settings for a new package (eg [Nerd Fonts](https://www.nerdfonts.com/)),
then I'll run:

```console
_SSDF_INPUT_PACKAGE_ID='31' \
    _SSDF_INPUT_PACKAGE_NAME='nerd-fonts' \
    _SSDF_INPUT_PACKAGE_EMOJI='🤓' \
    _SSDF_INPUT_PACKAGE_TITLE='Nerd Fonts' \
    _SSDF_INPUT_PACKAGE_SHORT_DESCRIPTION='Iconic font aggregator, collection, and patcher.' \
    bash ~/.dotfiles/00-_ssdf/quarry/0a01-new-package/1.0/install.sh
```

And badabim, badaboom, there's now a `31-nerd-fonts` folder with skeleton scripts
and bootstraped `README.md`.

Fun fact, `00-_ssdf/quarry/0a00-new-quarry-block` was used to bootstrap `00-_ssdf/quarry/0a01-new-package`.

This whole Quarry of Creation concept is a thing I've been toying with,
I'll probably write more about it in the future so stay tuned!

## Conclusion

To sum up, I use a git repository to backup my shell settings, so I can then
share them accross many devices.

And I also use some plain and simple bash script to restore and install them.

This might seem like a lot, it's been suiting me well for the past decade.
I hope this can inspire you to do something of your own!
