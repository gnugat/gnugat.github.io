---
layout: post
title: Learn Symfony2 - part 2: Empty application
tags:
    - symfony
    - learn symfony2 series
    - deprecated
---

> **Deprecated**: This series has been re-written - see
> [The Ultimate Developer Guide to Symfony](/2016/02/03/ultimate-symfony-http-kernel.html)

This is the second article of the series on learning
[the Symfony2 framework](http://symfony.com/).
Have a look at the first one: [Composer](/2014/06/18/learn-sf2-composer-part-1.html).

In the first article we began to create an empty project with the following
files:

    .
    ├── composer.json
    ├── composer.lock
    └── .gitignore

Running `composer install` should create a `vendor` directory, which we ignored
in git.

Here's the [repository where you can find the actual code](https://github.com/gnugat/learning-symfony2/tree/1-composer).

We'll now see how to create an empty Symfony2 application.

## The front controller

First things first, we will create an index file which will act as a front
controller: it will be the only entry point of our application and will decide
which page to display.

Create its directory:

    mkdir web

Then the file:

    <?php
    // File: web/app.php

    use Symfony\Component\HttpFoundation\Request;

    require_once __DIR__.'/../vendor/autoload.php';
    require_once __DIR__.'/../app/AppKernel.php';

    $kernel = new AppKernel('prod', false);
    $request = Request::createFromGlobals();
    $response = $kernel->handle($request);
    $response->send();
    $kernel->terminate($request, $response);

First it includes Composer's autoloader: it will require every files needed.

Then we create an instance of our Kernel with the production environment and
the debug utilities disabled. This class acts like a web server: it takes a
HTTP request as input and returns a HTTP response as output.

`Request::createFromGlobals()` creates a representation of the HTTP request.
It is filled from PHP's variable super globals (`$_GET`, `$_POST`, etc).

The kernel then handles the request. To keep explanations short, let's simply
say that it will find the controller associated to the requested URL. It is the
controller's responsibility to return a representation of the HTTP response (see
`Symfony\Component\HttpFoundation\Response`).

The `$response->send()` method will simply call the PHP `header` function and
print a string representing the response's body (usually HTML, JSON or anything
you want).

Finally the `$kernel->terminate()` method will call any tasks which registered
to the `kernel.terminate` event. This alows you to return a response as fast as
possible and then execute some actions like sending emails.

*Note*: events aren't in the scope of this article, but they're worth
mentioning.

## Creating the application's kernel

[The HttpKernel component](http://symfony.com/doc/current/components/http_kernel/introduction.html)
provides you with a `Kernel` class, which we will extend.

Create the following directory:

    mkdir app

And then the kernel file:

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
            );
        }

        public function registerContainerConfiguration(LoaderInterface $loader)
        {
            $loader->load(__DIR__.'/config/config.yml');
        }
    }

This class will load the project's configuration. This is also where you
register the project's bundles. We'll talk more about bundles in the next
article, for now the only thing you need to know is that they're like plugins.

The Kernel has the responsibility to look at every registered bundle to retrieve
their configuration.

The `FrameworkBundle` defines some services and allows you to choose what to
enable via configuration.

*Note*: Services are objects which do one thing and do it well. They provide
exactly what they're called: a service. We'll learn more about them in one of
the next article.

We need to put some configuration in order to be able to make it work properly.

Create its directory:

    mkdir app/config

And the the YAML file:

    # File: app/config/config.yml
    framework:
        secret: "Three can keep a secret, if two of them are dead."

The `secret` parameter is used as a seed to generate random strings (for e.g.
CSRF tokens).

Now that we have our application structure, let's commit it:

    git add -A
    git commit -m 'Created application structure'

### Logs and cache

You'll also need to create `logs` and `cache` directories:

    mkdir app/{cache,logs}
    touch app/{cache,logs}/.gitkeep

Git doesn't allow to commit empty directory, hence the `.gitkeep` files.

Because files in these directories are temporaries, we'll ignore them:

    echo '/app/cache/*' >> .gitignore
    echo '/app/logs/*' >> .gitignore
    git add -A
    git add -f app/cache/.gitkeep
    git add -f app/logs/.gitkeep
    git commit -m 'Created temporary directories'

### Apache configuration

In order for your website to be browsed, you'll need to configure your web
server. This configuration is well explained
[in the documentation](http://symfony.com/doc/current/cookbook/configuration/web_server_configuration.html),
so here's a dump of an apache vhost:

    <VirtualHost *:80>
        ServerName knight.local

        DocumentRoot /home/loic.chardonnet/Projects/gnugat/knight/web

        ErrorLog "/home/loic.chardonnet/Projects/gnugat/knight/app/logs/apache_errors.log"
        CustomLog "/home/loic.chardonnet/Projects/gnugat/knight/app/logs/apache_accesses.log" common

        <Directory /home/loic.chardonnet/Projects/gnugat/knight/web>
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

A Symfony2 application follows this pattern: a front controller associate an URL
to a controller which takes a HTTP request and returns a HTTP response.

The next article will be all about bundles, so stay tuned :) .
