---
layout: post
title: Mars Rover, Locating package
tags:
    - mars rover series
    - CQRS
    - mono repo
---

In this series we're building the software of a Mars Rover, according to
the [following specifications](/2016/06/15/mars-rover-introduction.html).
It allows us to practice the followings:

* Monolithic Repositories (MonoRepo)
* Command / Query Responsibility Segregation (CQRS)
* Event Sourcing (ES)
* Test Driven Development (TDD)

We've already developed the first use case about landing the rover on mars,
and the second one about driving it. We're now going to start developing the
last one, requesting its location:

> Mars rover will be requested to give their current location (`x` and `y`
> coordinates and the orientation).

In this article we're going to create a new package for the location logic.

## Why a new package?

Until now we've been putting our Landing and Driving code in the `navigation`
package. It's a "write" type of logic: an event occurs and we log it in the
Event Store.

On the other hand, requesting the location of the rover is a "read" type of
logic, since we've decided to follow the CQRS principle we're going to
separate them and put it in its own package.

The benefit of this approach can become more apparent if we decide to create
web APIs to control our Mars Rover and replicate the data accross multiple
servers: we could put the "write" endpoints on a single "Publishing" server,
and then put the "read" endpoints on many "Subsriber" servers.

The "Subscriber" servers only need to synchronize their data with the
"Publisher" server, allowing us to scale.

## Creating the `location` package

We can start by creating the directory:

```
git checkout -b 5-location
mkdir -p packages/location
cd packages/location
```

Composer needs us to set up the package by creating a `composer.json` file:

```
{
    "name": "mars-rover/location",
    "license": "MIT",
    "type": "library",
    "description": "Mars Rover - Location",
    "autoload": {
        "psr-4": { "MarsRover\\Location\\": "src/MarsRover/Location" }
    },
    "require": {
        "php": "^7.0"
    },
    "require-dev": {
        "memio/spec-gen": "^0.6"
    }
}
```

We've decided to use [phpspec](http://phpspec.net/) as a test framework, and
to get the most of it we'd like to use its [SpecGen](http://memio.github.io/spec-gen)
extension. To do so we need to create the `phpspec.yml.dist` file:

```
extensions:
    Memio\SpecGen\MemioSpecGenExtension: ~
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

That should be enough for a first commit:

```
git add -A
git commit -m '5: Created Location package'
```

## Adding `location` to the project

Let's go back to the project's root:

```
cd ../../
```

All we need to do is to add a new line in the `require` section of our
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
        "mars-rover/event-sourcing": "*@dev",
        "mars-rover/location": "*@dev",
        "mars-rover/navigation": "*@dev",
        "php": "^7.0"
    },
    "require-dev": {
        "phpspec/phpspec": "^3.0"
    }
}
```

Actually, we also need to add a new section in `phpspec.yml.dist`:

```
suites:
    event-sourcing:
        namespace: 'MarsRover\EventSourcing'
        src_path: packages/event-sourcing/src
        spec_path: packages/event-sourcing

    location:
        namespace: 'MarsRover\Location'
        src_path: packages/location/src
        spec_path: packages/location

    navigation:
        namespace: 'MarsRover\Navigation'
        src_path: packages/navigation/src
        spec_path: packages/navigation
```

And that's it! We are now able to run Composer and then phpspec:

```
composer update --optimize-autoloader
vendor/bin/phpspec run
```

That should be enough for a second commit:

```
git add -A
git commit -m '5: Added location package to main project'
```

## Conclusion

In order to keep the "write" logic in the `navigation` package separated
from the "read" logic, we've created a new `location` package.

## What's next

In the next article, we'll start creating the `LocateDriverHandler` class.
