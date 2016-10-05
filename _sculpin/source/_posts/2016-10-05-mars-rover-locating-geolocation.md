---
layout: post
title: Mars Rover, Locating geolocation
tags:
    - mars rover series
    - mono repo
    - CQRS
---

In this series we're building the software of a Mars Rover, according to
the [following specifications](/2016/06/15/mars-rover-introduction.html).
It allows us to practice the followings:

* Monolithic Repositories (MonoRepo)
* Command / Query Responsibility Segregation (CQRS)
* Event Sourcing (ES)
* Test Driven Development (TDD)

We've already developed the first use case about landing the rover on mars,
and the second one about driving it. We're now developing the last one,
requesting its location:

> Mars rover will be requested to give its current location (`x` and `y`
> coordinates and the orientation).

In this article we're going to create a new package for the geolocation value
objects (`Location`, `Coordinates` and `Orientation`).

## Creating the `geolocation` package

We can start by creating the directory:

```
git checkout 5-location
mkdir -p packages/geolocation
cd packages/geolocation
```

Composer needs us to set up the package by creating a `composer.json` file:

```
{
    "name": "mars-rover/geolocation",
    "license": "MIT",
    "type": "library",
    "description": "Mars Rover - Geolocation",
    "autoload": {
        "psr-4": { "MarsRover\\Geolocation\\": "src/MarsRover/Geolocation" }
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
git commit -m '5: Created Geolocation package'
```

## Adding `geolocation` to the project

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
        "mars-rover/geolocation": "*@dev",
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

    geolocation:
        namespace: 'MarsRover\Geolocation'
        src_path: packages/geolocation/src
        spec_path: packages/geolocation

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
git commit -m '5: Added geolocation package to main project'
```

## Adding `geolocation` to `navigation`

Now let's go to the `navigation` package:

```
cd packages/navigation
```

All we need to do is to add a new line in the `require` section of our
`composer.json` file:

```
{
    "name": "mars-rover/navigation",
    "license": "MIT",
    "type": "library",
    "description": "Mars Rover - Navigation",
    "autoload": {
        "psr-4": { "MarsRover\\Navigation\\": "src/MarsRover/Navigation" }
    },
    "repositories": [
        {
            "type": "path",
            "url": "../*"
        }
    ],
    "require": {
        "mars-rover/event-sourcing": "*@dev",
        "mars-rover/geolocation": "*@dev",
        "php": "^7.0"
    },
    "require-dev": {
        "memio/spec-gen": "^0.6"
    }
}
```

And that's it! We are now able to run Composer and then phpspec:

```
composer update --optimize-autoloader
vendor/bin/phpspec run
```

That should be enough for a third commit:

```
git add -A
git commit -m '5: Added geolocation package to navigation package'
```

## Adding `geolocation` to `location`

Now let's go to the `location` package:

```
cd ../location
```

This time, in addition to a new line in the `require` section we also need to
add a new `repositories` section to our `composer.json` file:

```
{
    "name": "mars-rover/location",
    "license": "MIT",
    "type": "library",
    "description": "Mars Rover - Location",
    "autoload": {
        "psr-4": { "MarsRover\\Location\\": "src/MarsRover/Location" }
    },
    "repositories": [
        {
            "type": "path",
            "url": "../*"
        }
    ],
    "require": {
        "mars-rover/geolocation": "*@dev",
        "php": "^7.0"
    },
    "require-dev": {
        "memio/spec-gen": "^0.6"
    }
}
```

And that's it! We are now able to run Composer and then phpspec:

```
composer update --optimize-autoloader
vendor/bin/phpspec run
```

That should be enough for a fourth and last commit:

```
git add -A
git commit -m '5: Added geolocation package to location package'
```

## Conclusion

We've now created a `geolocation` package that is shared between `navigation`
and `location`, keeping them both separate.

## What's next

In the next article, we'll start moving our value objects to our new package.
