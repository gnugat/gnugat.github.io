---
layout: post
title: "Turn your PHP app into a standalone binary"
tags:
    - php
---

> **TL;DR**:
> 
> 1. Prepare app for prod environment:
>    no dev deps, autoloading optimisation (classmap authoritative),
>    making `.env.local.php` from `.env`, no debug symfony cache, etc
> 2. Compile the PHAR with [Box](https://github.com/box-project/box)
> 3. Concatenate micro.sfx + dtk.phar into a self-contained binary with [static-php-cli](https://github.com/crazywhalecc/static-php-cli)

I've been building [DTK](https://github.com/gnugat/dtk), a PHP CLI tool that automates
the repetitive ceremony around the developer workflow:
open ticket, create branch, open PR, merge, deploy -
all wired together so you don't have to context-switch between your terminal,
your Kanban board, and GitHub.

It's a Symfony Console app, it runs fine with `php dtk`,
but distributing it to teammates means they need PHP installed at the right version,
with the right extensions, plus Composer.
That's friction I'd rather not ask anyone to deal with.

Turns out, PHP can produce a single self-contained binary, no PHP required on the target machine.
I learned this from a talk by Jean-François Lépine at Forum PHP 2025,
[PHP without PHP: Make Standalone Binaries from Your Code](https://www.youtube.com/watch?v=gqre9g4XV00),
which is in French, but [here's an English recap of it](https://github.com/gnugat/knowledge/blob/main/talks-recapped/2025-10-forum-php/012-php-without-php-make-standalone-binaries-from-your-code.md).

Surprisingly easy to set up. Here's how.

## The two ingredients

Two tools do all the work.

**Box** packages a PHP project into a `.phar` archive.
A `.phar` is a self-contained PHP archive: it includes all your source files and vendor
dependencies, and PHP can execute it directly.

**PHP Micro SFX**, part of the static-php-cli (SPC) project,
is a minimal static PHP binary with no external dependencies.
It reads whatever binary data is appended to it and executes it as a `.phar`.

Combine the two:

```
micro.sfx + app.phar = standalone binary
```

One file. No PHP needed on the target machine. Drop it, run it.

## Step 1: package the app as a PHAR

Box reads a `box.json` config file and produces the archive.
Here's the one for DTK:

```json
{
    "$schema": "https://box-project.github.io/box/schema.json",
    "main": "dtk",
    "output": "build/dtk.phar",
    "compression": "GZ",
    "check-requirements": false,
    "directories": [
        "config",
        "src",
        "var/cache/prod",
        "vendor"
    ],
    "files": [
        ".env.local.php"
    ]
}
```

A few things worth noting:

- `"main": "dtk"` is the entry point PHP file that Box will call when the PHAR is executed
- `"compression": "GZ"` compresses the archive contents, smaller file, same behaviour
- `"check-requirements": false` skips the PHP version and extension check at runtime,
  since we know the bundled micro binary already has everything we need
- `var/cache/prod` includes the pre-warmed Symfony cache,
  so the binary doesn't need to write to the filesystem on first run
- `.env.local.php` is a compiled version of the environment variables

## Step 2: get the micro binaries

[static-php-cli prebuilds micro SFX files](https://dl.static-php.dev/static-php-cli/common/)
for all major platforms and PHP versions, so you don't need to compile anything yourself.

In the DTK Dockerfile, I download them all at image build time:

```dockerfile
RUN for PLATFORM in linux-x86_64 linux-aarch64 macos-x86_64 macos-aarch64; do \
        curl -fsSL \
            -o /tmp/micro.tar.gz \
            "https://dl.static-php.dev/static-php-cli/common/php-${PHP_VERSION}-micro-${PLATFORM}.tar.gz" \
        && tar xzf /tmp/micro.tar.gz -C /usr/local/lib/ \
        && mv /usr/local/lib/micro.sfx "/usr/local/lib/micro-${PLATFORM}.sfx" \
        && rm /tmp/micro.tar.gz; \
    done
```

Windows has a separate download (a zip, not a tarball), but same idea.

The micro SFX from static-php-cli includes [a whole bunch of extensions](https://static-php.dev/en/guide/extensions.html),
so if you need some that are missing, or if you want the bare minimum, you'd need to compile
your own micro using SPC, that's more involved, but SPC has a `doctor --auto-fix`
command to help with the build environment setup.

## Step 3: assemble the binaries

With the PHAR built and the micro SFX files in place, combining them is a `cat` 😼:

```bash
cat micro-linux-x86_64.sfx dtk.phar > dtk-linux-x86_64
chmod +x dtk-linux-x86_64
```

That's it. The resulting file is a valid ELF binary (or Mach-O on macOS, PE on Windows)
that carries its own PHP interpreter alongside the application code.

Here's the full build script I use for DTK (`bin/mk-dtk-bin.sh`) that does all of it:

```bash
#!/usr/bin/env bash
set -euo pipefail

# Restore dev dependencies once finished
trap 'composer install --optimize-autoloader --quiet' EXIT

echo '  // Installing prod dependencies...'
composer install --no-dev --classmap-authoritative --quiet

echo '  // Compiling environment variables...'
php bin/mk-dtk-bin/dump-env-prod.php

echo '  // Warming up Symfony cache...'
APP_ENV=prod APP_DEBUG=0 php bin/console cache:warmup --quiet

echo '  // Building PHAR...'
mkdir -p build
php -d phar.readonly=0 /usr/local/bin/box compile

echo '  // Assembling binaries...'
for _PLATFORM in linux-x86_64 linux-aarch64 macos-x86_64 macos-aarch64 windows-x86_64; do
    case "${_PLATFORM}" in
        windows-*) _EXT='.exe' ; _CHMOD=false ;;
        *)         _EXT=''     ; _CHMOD=true  ;;
    esac

    cat "/usr/local/lib/micro-${_PLATFORM}.sfx" build/dtk.phar > "build/dtk-${_PLATFORM}${_EXT}"
    ${_CHMOD} && chmod +x "build/dtk-${_PLATFORM}${_EXT}"
done

echo '  // Generating checksums...'
sha256sum \
    build/dtk-linux-x86_64 \
    build/dtk-linux-aarch64 \
    build/dtk-macos-x86_64 \
    build/dtk-macos-aarch64 \
    build/dtk-windows-x86_64.exe \
    > build/checksums.txt

echo '  [OK] Binaries built'
```

A few things the script does before building the PHAR:

- **`composer install --no-dev --classmap-authoritative`**: strips dev dependencies
  and generates a fast classmap-only autoloader, smaller archive, faster startup.
- **`dump-env-prod.php`**: compiles `.env` files into `.env.local.php` so the binary
  doesn't need to parse `.env` files at runtime.
  (Replicates what `composer dump-env prod` from symfony/flex does,
  without requiring symfony/flex as a dependency.)
- **`cache:warmup`**: pre-generates the Symfony container so the binary
  doesn't need write access to the filesystem on first run.

The `trap` at the top restores dev dependencies when the script exits,
so the local dev environment is left intact after a build.

## What comes out

Running `make app-bin` in the Docker container produces:

```
build/dtk.phar
build/dtk-linux-x86_64
build/dtk-linux-aarch64
build/dtk-macos-x86_64
build/dtk-macos-aarch64
build/dtk-windows-x86_64.exe
build/checksums.txt
```

Five binaries, one per platform, from a single command, without leaving Docker.
Each one runs without PHP on the target machine.

## Constraints worth knowing

This is real PHP, the same interpreter, the same extensions, the same behaviour.
A few things to be aware of:

**FFI is not available.** Foreign Function Interface calls (PHP calling C libraries directly)
don't work in static builds. For a CLI tool this is unlikely to matter.

**Binary size.** A minimal PHP binary with no extensions is around 3 MB.
DTK, which only uses standard extensions, comes out much smaller than a full PHP install.
Not Go-binary small, but perfectly acceptable for a CLI tool distributed via GitHub Releases.

**Startup time.** There's a small overhead compared to running `php dtk` directly:
PHAR extraction adds a few milliseconds, and the static build uses musl libc rather
than glibc, which is slightly slower.
For a developer tool where the user is waiting hundreds of milliseconds anyway, this doesn't matter.

**Not for web apps.** This is for CLI / TUI / scripts, for web PHP apps,
use [FrankenPHP](https://frankenphp.dev/) instead.
It's a production-proven PHP app server built on top of static-php-cli that handles
all the complexity, and it ships as a standalone binary too.

## A surprisingly short path

The whole thing (Box config, Dockerfile setup, build script) took an afternoon.
Most of that time was reading the static-php-cli docs and figuring out the Docker layering.
The actual concatenation step (`cat micro.sfx app.phar > binary`) was the part that surprised me most:
something that powerful should not be that simple :D !

If you're building a PHP CLI tool meant to be distributed to people who shouldn't need
to care about PHP, this is the approach. It works, it's well-supported
(FrankenPHP, Laravel Herd, and NativePHP all use static-php-cli under the hood),
and the tooling is solid.

If you want to see a real-world example of a PHP project that compiles its own micro binaries
(including the SPC setup), look at [Castor](https://github.com/jolicode/castor).
Castor is a task runner / script launcher for PHP (think Make or Taskfile, but in PHP)
and it ships prebuilt binaries for all platforms.
Its build setup is a good reference for when you outgrow the prebuilt micro SFX files
and need to compile your own with a custom extension set.

The full DTK source used in this article is available at
[github.com/gnugat/dtk/tree/v0.1.0](https://github.com/gnugat/dtk/tree/v0.1.0).
