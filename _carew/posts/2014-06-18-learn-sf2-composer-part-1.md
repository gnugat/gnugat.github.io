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
practice a lot in order to master it. But forn now this guide should be a good
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

## Getting composer

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

Composer was made to install libraries, so let's use it:

    composer require 'symfony/symfony:~2.5' # install every single libraries in sf2

This will create a `composer.lock` file which helps Composer to know the
installed versions, and a `vendor` directory where you can find the downloaded
sources.

*Note*: Symfony2 libraries are called `components`.

Later on, to update those dependencies you'll just have to run:

    composer update

*Note*: a library on which you depend upon is called a `dependency`.

This will look in the `composer.lock` file to know which version has been
installed and then checks if there's any new versions. Because we specified
`~2.5` for Symfony2, this will only look for 2.5 bug fixes (for more information
about how composer handles versions, see
[Igor's article](https://igor.io/2013/01/07/composer-versioning.html)).

This means that you can totally ignore the `vendor` directory:

    echo '/vendor/*' >> .gitignore

If your team wants to install your project, they'll just have to clone your
repository and then run `composer install`.

## Autloading

Because Composer knows were each classes of the installed libraries are, it
provides a nice feature: [autoloading](http://www.php.net/manual/en/language.oop5.autoload.php)
(it automatically includes the classes you need).

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

And run `composer update` to take the changes into account.

This tells composer that we're going to follow the
[PSR-4](http://www.php-fig.org/psr/psr-4/) standard and that we're going to put
our sources in the `src` directory.

*Note*: PSR 4 requires you to:

* create one class per file
* give the same name to your file and your class
* use the path of the class for the namespace

For example: the file `src/Knight/AppBundle/KnightAppBundle.php` contains a
class named `KnightAppBundle` located in the namespace `Knight\AppBundle`.

Don't worry too much about it for now.

## Conclusion

And that's everything you need to know about composer for now. Let's commit our
work:

    git add -A
    git ci -m 'Installed Symfony2'

I hope this could help you, stay tuned for the next articles!
