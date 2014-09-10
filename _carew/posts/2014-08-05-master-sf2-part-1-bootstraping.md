---
layout: post
title: Master Symfony2 - part 1: Bootstraping
tags:
    - Symfony2
    - technical
    - Master Symfony2 series
---

You know the basics of the [Symfony2](http://symfony.com/) framework
([Composer](https://getcomposer.org/), empty application, bundle, controller and
functional test with [PHPUnit](http://phpunit.de/)) and you want to learn more
about how to extend it (and understanding what you're doing)?

Then this series of articles is for you :) .

If you don't feel confident about the prerequisites, have a look at
{{ link('posts/2014-06-18-learn-sf2-composer-part-1.md', 'the Learn Symfony2 series') }}.
Don't worry, we'll start with a bit of practicing before starting to learn
anything new.

In the first article of this series, we'll discover our cutomer's needs and
we'll bootstrap our application.

## Our use case: creating a Fortune application

In order to have real world examples, we'll need a use case. The Knight of Ni
were pretty satisfied with our previous work, and they recommended us to
Nostradamus!

Nostradamus is a fortune teller and wants to jump on the internet bandwagon. He
wants us to create a
[fortune application](http://en.wikipedia.org/wiki/Fortune_%28Unix%29)
where users can submit quotes.

Our first task will be to create an empty application so we can start working.
We could use the [Symfony Standard Edition](http://symfony.com/distributions),
but in order to understand what really happens behind the scene we'll use an
emptier distribution.

## Installing Symfony2 Emptier Edition

First make sure to have the last version of [Composer](https://getcomposer.org/)
installed:

    curl -sS https://getcomposer.org/installer | php
    sudo mv composer.phar /usr/local/bin/composer

Then ask Composer to create the boilerplate of our application, using the
[Symfony2 Emptier Edition](https://github.com/gnugat/sf2-emptier):

    composer create-project 'gnugat/sf2-emptier' fortune '0.1.*'
    cd fortune

This distribution is similar to the empty application we created in the
{{ link('posts/2014-06-25-learn-sf2-empty-app-part-2.md', 'learn Symfony2 series') }}.
It contains the following files:

    .
    ├── app
    │   ├── AppKernel.php
    │   ├── cache
    │   │   └── .gitkeep
    │   ├── config
    │   │   ├── config_prod.yml
    │   │   ├── config_test.yml
    │   │   ├── config.yml
    │   │   ├── parameters.yml.dist
    │   │   └── routing.yml
    │   ├── logs
    │   │   └── .gitkeep
    │   └── phpunit.xml.dist
    ├── composer.json
    ├── LICENSE
    ├── README.md
    └── web
        └── app.php

Remove the documentation files:

    rm README.md LICENSE

Change the `composer.json` information:

    {
        "name": "nostradamus/fortune",
        "license": "proprietary",
        "type": "project",
        "description": "A collection of quotes",
        "autoload": {
            "psr-4": { "": "src/" }
        },
        "require": {
            "php": ">=5.3.17",

            "symfony/symfony": "~2.4"
        },
        "require-dev": {
            "phpunit/phpunit": "~4.1"
        }
    }

Next you'll have to configure the project specific parameters:

    cp app/config/parameters.yml.dist app/config/parameters.yml

Don't forget to edit `app/config/parameters.yml` and change the value of the
secret parameter:

    parameters:
        secret: hazuZRqYGdRrL8ATdB8kAqBZ

**Tip**: Use [random.org](https://www.random.org/passwords/?num=1&len=24&format=html&rnd=new)
to generate your secret token.

**Note**: For security reason, this parameter file is ignored by git. It means
that this file should be created on each installation.

Let's commit our hard work:

    git init
    git add -A
    git add -f app/logs/.gitkeep app/cache/.gitkeep
    git commit -m 'Created a Symfony2 Emptier application'

## Creating the Application Bundle

We will also need an Application bundle. First we create the directories:

    mkdir -p src/Fortune/ApplicationBundle

Then the Bundle class:

    <?php
    // File: src/Fortune/ApplicationBundle/FortuneApplicationBundle.php

    namespace Fortune\ApplicationBundle;

    use Symfony\Component\HttpKernel\Bundle\Bundle;

    class FortuneApplicationBundle extends Bundle
    {
    }

And finally register it in the application's kernel:

    <?php
    // File: app/AppKernel.php

    use Symfony\Component\HttpKernel\Kernel;
    use Symfony\Component\Config\Loader\LoaderInterface;

    class AppKernel extends Kernel
    {
        public function registerBundles()
        {
            return array(
                new Symfony\Bundle\FrameworkBundle\FrameworkBundle(),
                new Fortune\ApplicationBundle\FortuneApplicationBundle(), // <-- Here!
            );
        }

        public function registerContainerConfiguration(LoaderInterface $loader)
        {
            $loader->load(__DIR__.'/config/config_'.$this->getEnvironment().'.yml');
        }
    }

We're now ready to get started with our real concern, so let's commit our work:

    git add -A
    git commit -m 'Created ApplicationBundle'

### Apache configuration

In order for your website to be browsed, you'll need to configure your web
server. This configuration is well explained
[in the documentation](http://symfony.com/doc/current/cookbook/configuration/web_server_configuration.html),
so here's a dump of an apache vhost:

    <VirtualHost *:80>
        ServerName fortune.local

        DocumentRoot /home/loic.chardonnet/Projects/gnugat/fortune/web

        ErrorLog "/home/loic.chardonnet/Projects/gnugat/fortune/app/logs/apache_errors.log"
        CustomLog "/home/loic.chardonnet/Projects/gnugat/fortune/app/logs/apache_accesses.log" common

        <Directory /home/loic.chardonnet/Projects/gnugat/fortune/web>
            Options Indexes FollowSymLinks MultiViews
            AllowOverride None
            Order allow,deny
            allow from all
            <IfModule mod_rewrite.c>
                RewriteEngine On
                RewriteCond %{REQUEST_FILENAME} !-f
                RewriteRule ^(.*)$ /app.php [QSA,L]
            </IfModule>
        </Directory>
    </VirtualHost>

If you run into some permission problem (like writing in `cache` and `logs`),
you might consider to change `APACHE_RUN_USER` and `APACHE_RUN_GROUP`
environment variables present in `/etc/apache2/envvars` to your own user and
group.

## Conclusion

Using Composer's `create-project` command with a Symfony2 Distribution is the
quickest way to bootstrap a project.

In the next article, we will start to work on our first User Story.

### Next articles

* {{ link('posts/2014-08-13-master-sf2-part-2-tdd.md', '2: TDD') }}
* {{ link('posts/2014-08-22-master-sf2-part-3-services.md', '3: Services') }}
* {{ link('posts/2014-08-27-master-sf2-part-4-doctrine.md', '4: Doctrine') }}
* {{ link('posts/2014-09-03-master-sf2-part-5-events.md', '5: Events') }}
* {{ link('posts/2014-09-10-master-sf2-part-6-annotations.md', '6: Annotations') }}
