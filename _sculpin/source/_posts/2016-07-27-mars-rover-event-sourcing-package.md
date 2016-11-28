---
layout: post
title: Mars Rover, Event Sourcing package
tags:
    - mars rover series
    - TDD
    - phpspec
    - event sourcing
    - mono repo
---

In this series we're building the software of a Mars Rover, according to the
[following specifications](/2016/06/15/mars-rover-introduction.html).
It will allow us to practice the followings:

* Monolithic Repositories (MonoRepo)
* Command / Query Responsibility Segregation (CQRS)
* Event Sourcing (ES)
* Test Driven Development (TDD)

Up until now, we've implemented the first use case, "Landing a rover on Mars":

> Mars Rovers need first to be landed at a given position. A position is
> composed of coordinates (`x` and `y`, which are both integers) and an
> orientation (a string being one of `north`, `east`, `west` or `south`).

In order to do so, we've:

* created a [navigation package](/2016/06/22/mars-rover-initialization.html)
* created [LandRover for input validation](/2016/06/29/mars-rover-landing.html)
* refactored it by:
    * extracting [Coordinates](/2016/07/06/mars-rover-landing-coordinates.html)
    * extracting [Orientation](/2016/07/13/mars-rover-landing-orientation.html)
* created [LandRoverHandler for the actual logic](/2016/07/20/mars-rover-landing-event.html)

In the last article, we wrote some Event Sourcing code:

* `Event`, a Data Transfer Object (DTO) that contains the name and the data
* `AnEventHappened`, which is actually an `Event` factory
* `EventStore`, a service responsible for "logging" `Event`s

In this article, we're going to extract them from the `navigation` package and
put them in their own `event-sourcing` package.

## Creating the `event-sourcing` package

We can start by creating the directory:

```
git checkout -b 3-event-sourcing
mkdir -p packages/event-sourcing
cd packages/event-sourcing
```

Composer needs us to set up the package by creating a `composer.json` file:

```
{
    "name": "mars-rover/event-sourcing",
    "license": "MIT",
    "type": "library",
    "description": "Mars Rover - Event Sourcing",
    "autoload": {
        "psr-4": { "MarsRover\\EventSourcing\\": "src/MarsRover/EventSourcing" }
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

That should be enough for a second commit:

```
git add -A
git commit -m '3: Created Event Sourcing package'
```

## Adding `event-sourcing` to the project

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
        "mars-rover/navigation": "*@dev",
        "php": "^7.0"
    },
    "require-dev": {
        "phpspec/phpspec": "^3.0@beta"
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
git commit -m '3: Added event-sourcing package to main project'
```

## Event Sourcing files

It's now time to move Event Sourcing files from `navigation` to
`event-sourcing`:

```
cd packages/event-sourcing
mkdir -p src/MarsRover/EventSourcing
mv ../navigation/src/MarsRover/Navigation/{EventStore.php,Event.php,AnEventHappened.php} ./src/MarsRover/EventSourcing/
```

We then need to change namespaces:

```
sed -i 's/Navigation/EventSourcing/g' ./src/MarsRover/EventSourcing/*
```

To continue those namespace changes we'll have to move back to the `navigation`
package:

```
cd ../navigation
```

Then rename the namespaces:

```
sed -i 's/Navigation\\Event;/EventSourcing\\Event;/g' ./spec/MarsRover/Navigation/*
sed -i 's/Navigation\\EventStore;/EventSourcing\\EventStore;/g' ./spec/MarsRover/Navigation/*
sed -i 's/Navigation\\AnEventHappened;/EventSourcing\\AnEventHappened;/g' ./spec/MarsRover/Navigation/*
```

We'll also need to add use statements to
`./src/MarsRover/Navigation/LandRoverHandler.php`:

```php
<?php

namespace MarsRover\Navigation;

use MarsRover\EventSourcing\{
    AnEventHappened,
    EventStore
};

class LandRoverHandler
{
    private $anEventHappened;
    private $eventStore;

    public function __construct(
        AnEventHappened $anEventHappened,
        EventStore $eventStore
    ) {
        $this->anEventHappened = $anEventHappened;
        $this->eventStore = $eventStore;
    }

    public function handle(LandRover $landRover)
    {
        $roverLanded = $this->anEventHappened->justNow(Events::ROVER_LANDED, [
            'x' => $landRover->getCoordinates()->getX(),
            'y' => $landRover->getCoordinates()->getY(),
            'orientation' => $landRover->getOrientation()->get(),
        ]);
        $this->eventStore->log($roverLanded);
    }
}
```

Since `navigation` now relies on `event-sourcing` classes, we need to add it in
`composer.json`:

```
{
    "name": "mars-rover/navigation",
    "license": "MIT",
    "type": "library",
    "description": "Mars Rover - Navigation",
    "autoload": {
        "psr-4": {
            "MarsRover\\EventSourcing\\": "src/MarsRover/EventSourcing",
            "MarsRover\\Navigation\\": "src/MarsRover/Navigation"
        }
    },
    "repositories": [
        {
            "type": "path",
            "url": "../*"
        }
    ],
    "require": {
        "mars-rover/event-sourcing": "*@dev",
        "php": "^7.0"
    },
    "require-dev": {
        "memio/spec-gen": "^0.6"
    }
}
```

As we can see, it's quite similar to what we've done in the project's root:
we've added a `repositories` section with the path to packages (`../`) and
then added `mars-rover/event-sourcing` to the `require` section, with the
version `*@dev` (any version, including unstable ones).

Let's run the tests:

```
vendor/bin/phpspec run
```

All green! We can now succesfully commit our new package:

```
cd ../../
git add -A
git commit -m '3: Moved Event Sourcing classes to their own package'
```

## Conclusion

We identified `AnEventHappened`, `Event` and `EventStore` as objects that
could be in their own package, so we created `event-sourcing` and moved them
in it. This also meant we had to add this package to the project's root and to
navigation.

## What's next

In the next article, we'll implement `AnEventHappened` and `Event`.
