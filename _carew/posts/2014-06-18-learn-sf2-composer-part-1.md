---
layout: post
title: Learn Symfony2 - part 1: Composer
tags:
    - Symfony2
    - technical
    - Learn Symfony2 series
---

You don't know anything about the [Symfony2](http://symfony.com/) framework,
and you'd like a quick guide to learn how to use it, and how it works?

Then this article is for you :) .

Don't get me wrong: one day or another you'll have to read the
[documentation](http://symfony.com/doc/current/index.html), and you'll have to
practice a lot in order to master it. But for now this guide should be a good
start for you.

In the first article of this series, you'll learn about
[Composer](https://getcomposer.org/), which helps you with third party library
installation and updates.

## Creating the project

In order to understand how Symfony2 works, we won't use the
[Symfony Standard Edition](http://symfony.com/distributions), but rather start
from scratch with the bare minimum.

Let's create our project:

    mkdir knight
    cd knight
    git init

## Getting Composer

When developing a project the last thing you want is to waste your time
re-inventing the wheel, so you install third party libraries. Those libraries
have their own life cycle: they might release some bug fixes and new features
after you installed them, so you'll need to update them sometimes.

[Composer](https://getcomposer.org/) makes these things so easy you'll never
have to worry again about versions. First download it:

    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer

And we're done! If only every project were so easy to install... :)

## Installing and updating Symfony2

Actually, Symfony2 is only a name regrouping many libraries which can be used
individually (you can even use them in other frameworks, CMS or projects like
[Drupal](http://symfony.com/projects/drupal),
[phpBB](http://symfony.com/projects/phpbb),
[Laravel](http://symfony.com/projects/laravel),
[eZ Publish](http://symfony.com/projects/ezpublish),
[OroCRM](http://symfony.com/projects/orocrm) and
[Piwik](http://symfony.com/projects/piwik) did).

*Note*: Symfony2 libraries are called `components`.

Composer was made to install libraries, so let's use it:

    composer require 'symfony/symfony:~2.5' # install every single libraries in sf2

This command will do the following steps:

1. create a `composer.json` configuration file if it doesn't already exist
2. add `symfony/symfony: ~2.5` in it (useful for further `composer install`)
3. actually download symfony inside the `vendor/symfony/symfony` directory
4. create a `composer.lock` file

Later on, to update those dependencies you'll just have to run
`composer update`.

*Note*: a library on which you depend upon is called a `dependency`.

This will look in the `composer.lock` file to know which version has been
installed (e.g. 2.5.0) and then checks if there's any new version available.
For more information about how Composer handles versions, see
[Igor's article](https://igor.io/2013/01/07/composer-versioning.html).

This means that you can totally ignore the `vendor` directory:

    echo '/vendor/*' >> .gitignore

If your team wants to install your project, they'll just have to clone your
repository and then run `composer install` which runs into the following steps:

1. read the `composer.json` file to see the list of dependencies
2. read the `composer.lock` file to check the version installed by the commiter
3. download the dependencies with the version specified in the lock (even if new
   ones are available)

If a dependency is listed in `composer.json` but not in `composer.lock`,
Composer will download the last matching version and add it to the lock.

This means that everyone will have the same version installed! If you allow only
one person to run `composer update` you can guarantee this.

## Autloading

Because Composer knows where each classes of the installed libraries are, it
provides a nice feature:
[autoloading](http://www.php.net/manual/en/language.oop5.autoload.php).

Simply put, each time a class is called, Composer will automatically include the
file where it's declared.

Your own code too can benefit from it. We just need to edit the `composer.json`
file:

    {
        "require": {
            "symfony/symfony": "~2.5"
        },
        "autoload": {
            "psr-4": {
                "": "src/"
            }
        }
    }

And run the following command to take the changes into account:

    composer update

This tells Composer that we're going to follow the
[PSR-4](http://www.php-fig.org/psr/psr-4/) standard and that we're going to put
our sources in the `src` directory.

*Note*: PSR 4 requires you to:

* create one class per file
* give the same name to your file and your class
* use the path of the class for the namespace

For example: the file `src/Knight/ApplicationBundle/KnightApplicationBundle.php`
contains a class named `KnightApplicationBundle` located in the namespace
`Knight\ApplicationBundle`.

Don't worry too much about it for now.

## Conclusion

And that's everything you need to know about Composer for now. Let's commit our
work:

    git add -A
    git commit -m 'Installed Symfony2'

I hope this could help you, stay tuned for the next articles!

### Next articles

* {{ link('posts/2014-06-25-learn-sf2-empty-app-part-2.md', '2: Empty application') }}
* {{ link('posts/2014-07-02-learn-sf2-bundles-part-3.md', '3: Bundles') }}
* {{ link('posts/2014-07-12-learn-sf2-controllers-part-4.md', '4: Controllers') }}
* {{ link('posts/2014-07-20-learn-sf2-tests-part-5.md', '5: Tests') }}
* {{ link('posts/2014-07-23-learn-sf2-conclusion.md', 'Conclusion') }}
