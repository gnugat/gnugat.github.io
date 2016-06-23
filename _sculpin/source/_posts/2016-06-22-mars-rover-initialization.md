---
layout: post
title: Mars Rover, Initialization
tags:
    - mars rover series
    - mono repo
    - phpspec
---

In this series we're going to build the software of a Mars Rover, according to
the [following specifications](/2016/06/15/mars-rover-introduction.html).
It will allow us to practice the followings:

* Monolithic Repositories (MonoRepo)
* Command / Query Responsibility Segregation (CQRS)
* Event Sourcing (ES)
* Test Driven Development (TDD)

But first, we need to initialize our project.

## Creating the repository

Let's start by creating a new git repository:

```
mkdir rover
cd rover
git init
```

Since we're going to use [Composer](https://getcomposer.org/), we can create
a `composer.json` file:

```
{
    "name": "mars-rover/mars-rover",
    "license": "MIT",
    "type": "project",
    "description": "Mars Rover",
    "require": {
        "php": "^7.0"
    }
}
```

We're then going to ignore some third party library related stuff by
creating `.gitignore`:

```
# Third Party libraries
/vendor/
```

With this we've finished creating our repository. We can run composer:

```
composer install --optimize-autoloader
```

That should be enough for a first commit:

```
git add composer.json .gitignore
git commit -m '0: Created project'
```

## Creating the `navigation` package

By having a look at the [use cases](/2016/06/15/mars-rover-introduction.html#identifying-use-cases),
we can see that there's going to be "write-only" dedicated ones and "read-only"
dedicated ones:

1. Landing a Rover on Mars: is write only
2. Driving a Rover: is write only
3. Requesting the Rover's location: is read only

Since we'd like to follow the CQRS principle, we'll put the "write-only"
logic in a different package than the "read-only" logic. Landing and Driving
is all about navigation, so we'll create a `navigation` package:

```
git checkout -b 1-navigation
mkdir -p packages/navigation
cd packages/navigation
```

Composer needs us to set up the package by creating a `composer.json` file:

```
{
    "name": "mars-rover/navigation",
    "license": "MIT",
    "type": "library",
    "description": "Mars Rover - Navigation",
    "autoload": {
        "psr-4": { "MarsRover\\Navigation\\": "src/MarsRover/Navigation" }
    },
    "require": {
        "php": "^7.0"
    },
    "require-dev": {
        "memio/spec-gen": "^0.5",
        "phpspec/phpspec": "^3.0@beta"
    }
}
```

We've decided to use [phpspec](http://phpspec.net/) as a test framework, and
to get the most of it we'd like to use its [SpecGen](http://memio.github.io/spec-gen)
extension. To do so we need to create the `phpspec.yml.dist` file:

```
extensions:
  - Memio\SpecGen\MemioSpecGenExtension
```

> **Note**: For more information about phpspec
> [see this article](/2015/08/03/phpspec.html).

Finally, we can configure this package's git by creating a `.gitignore` file:

```
# Configuration
/phpspec.yml

# Third Party libraries
/vendor/
/composer.lock
```

With this we've finished creating our package. We can run Composer:

```
composer install --optimize-autoloader
```

That should be enough for a second commit:

```
git add -A
git commit -m '1: Created Navigation package'
```

## Adding `navigation` to the project

Let's go back to the project's root:

```
cd ../../
```

One benefit of MonoRepos is to be able to run all packages tests in one
command. To do so, we need to require `navigation` in our project's
`composer.json` file:

```
{
    "name": "mars-rover/mars-rover",
    "license": "MIT",
    "type": "project",
    "description": "Mars Rover",
    "repositories": [
        {
            "type": "path",
            "url": "./packages/*"
        }
    ],
    "require": {
        "mars-rover/navigation": "*@dev",
        "php": "^7.0"
    }
}
```

By default, Composer looks for packages only in [Packagist](https://packagist.org/).
By adding the new `repositories` section we can tell it to also check locally
in `./packages`, allowing us to add them in the `require` section.

Composer needs us to tell it what version of the package we'd like, but in
MonoRepos all packages share the same version, so we simply use `*` (any).
But to be able to use the latest changes, and not only the tagged one, we
have to specify the development stability (`@dev`).

Since we've decided to use phpspec for our test, we're also going to need to
require it in the project's development dependencies:

```
composer require --dev phpspec/phpspec:^3.0@beta
```

By default phpspec is going to look for test in the project's root. We need to
create a `phpspec.yml.dist` file to tell it to use `navigation`'s ones:

```
suites:
    navigation:
        namespace: 'MarsRover\Navigation'
        src_path: packages/navigation/src
        spec_path: packages/navigation
```

We'll also update `.gitignore` to ignore local configuration:

```
# Configuration
/phpspec.yml

# Third Party libraries
/vendor/
```

And that's it! We are now able to run Composer and then phpspec:

```
composer update --optimize-autoloader
./vendor/bin/phpspec run
```

That should be enough for a last commit:

```
git add -A
git commit -m '1: Added navigation package to main project'
```

Let's merge it to master:

```
git checkout master
git merge --no-ff 1-navigation
```

## Conclusion

With Composer we can create many packages inside a single repository. With this
MonoRepo, we can then execute all the tests in one command.

## What's next

In the next article we'll tackle down the "Landing a Rover on Mars" use case,
allowing us to showcase an example of Event Sourcing and TDD.
