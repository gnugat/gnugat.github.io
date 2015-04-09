---
layout: post
title:  Bootstrap the markdown files of your FOSS project
tags:
    - introducing tool
    - pet project
---

The one thing that will make developers use your Free or Open Source Software
(FOSS) project is its documentation. Without it, how can they know what it does,
or how to install it?

Last summer [William Durand wrote an article about it](http://williamdurand.fr/2013/07/04/on-open-sourcing-libraries/),
describing the minimum files your FOSS project should have, and what they should
contain.

After reading his article, maybe you did the same thing as me: you took your
courage with both hands and wrote thoroughly a decent documentation for the
project you were working on at the time.

Because it was tedious, you decided to copy those markdown files into your new
projects and adapt them.

But this too was tedious...

To solve this problem once for all I created **[fossil](https://github.com/gnugat/fossil)**:
it will bootstrap the markdown files of your FOSS projects, and it will even
create an installer for you!

It generates the following files out of skeletons:

* `CHANGELOG.md`
* `CONTRIBUTING.md`
* `LICENSE`
* `README.md`
* `VERSIONING.md`
* `bin/installer.sh`
* `doc` (or `Resources/doc` if the project is a bundle) directory:
    - `01-introduction.md`
    - `02-installation.md`
    - `03-usage.md`
    - `04-tests.md`

The best thing about it: you can run it on your new FOSS projects as well as
with your existing ones! By default it does not replace existing files (if you
want to, simply use the `-f` option).

**Fossil** supports different kind of projects: applications, libraries and
Symfony2 bundles. Here's a quick usage guide.

## Applications

The `doc` command allows you to generate the markdown files of your
applications, which can be a web application or a CLI tool just like **fossil**.

As you can see in the following example, it only requires 2 arguments:

    fossil doc 'acme/application' 'The ACME company'

### The [Github](https://github.com/) repository argument

Applications are installed by cloning the github repository, which makes it as
easy to update as to run `git pull`.

This argument is used in the installer script as well as in the installation
instructions.

You don't need to write the whole github URL, simply give the username and the
project name in the following format: `username/project-name`

### The license author argument

While the copyright's date can be computed, you need to provide the author's
name to generate the `LICENSE` file.

For now it only generates MIT licenses, but pull requests are welcomed :) .

### The path option

By default the files are created in the current directory, but you can target a
specific path:

    fossil doc 'acme/application' 'The ACME company' -p '/tmp/application'

### The force overwrite option

As mentioned earlier, **fossil** won't replace existing files by default: for
instance if your project already has a `README.md` and a `LICENSE` file it will
only generate the other ones.

But if you want to throw them away, you can use this option:

    fossil doc 'acme/project' 'The ACME company' -f

## Libraries

The `doc:library` command has the exact same arguments and options as the `doc`
one:

    fossil doc:library 'acme/library' 'The ACME company'

You can use the shortcut `d:l`:

    fossil d:l 'acme/library' 'The ACME company'

The difference between an application and a library lies in its installation:
the library is installed using [composer](http://getcomposer.org/).

### The composer package option

By default **fossil** assumes the composer package's name is the same as the
Github repository name (in the example it would be `acme/library`).
If it's not your case, use the following option:

    fossil d:l 'acme/library' 'The ACME company' -c 'acme/composer-package'

## Symfony2 Bundles

The `doc:bundle` command has almost the same arguments and options as the
`doc:library` one. It has an additional argument:

    fossil doc:bundle 'acme/demo-bundle' 'The ACME company' 'Acme\DemoBundle\AcmeDemoBundle'

You can use the shortcut `d:b`:

    fossil d:b 'acme/demo-bundle' 'The ACME company' 'Acme\DemoBundle\AcmeDemoBundle'

The difference between a library and a bundle is the documentation directory,
which is in `Resources/doc` instead of `doc`.

### The fully qualified classname argument

Another difference is the installation: the bundle needs to be added in the
application's kernel.

This will be detailed in the documentation, but it will also be taken care of
by the installer.

That's right, you read it right: when developers will run the installer, not
only will it download the bundle using composer, but it will also add its fully
qualified classname in the `app/AppKernel.php` file! Hooray!

The application's kernel will look like this afterwards:

    <?php
    // File: app/AppKernel.php

    use Symfony\Component\HttpKernel\Kernel;

    class AppKernel extends Kernel
    {
        public function registerBundles()
        {
            $bundles = array(
                // Other bundles...
                new Acme\DemoBundle\AcmeDemoBundle(),
            );

            if (in_array($this->getEnvironment(), array('dev', 'test'))) {
                // Other bundles...
            }

            return $bundles;
        }
    }

*Note*: because of the backslashes you should escape this argument using
quotes, just like in the example.

### The development tool option

By using this option, the bundle will be registered in the application only if
it runs in development or test environment:

    fossil d:b 'acme/demo-bundle' 'The ACME company' 'Acme\DemoBundle\AcmeDemoBundle' -d

The application's kernel will look like this afterwards:

    <?php
    // File: app/AppKernel.php

    use Symfony\Component\HttpKernel\Kernel;

    class AppKernel extends Kernel
    {
        public function registerBundles()
        {
            $bundles = array(
                // Other bundles...
            );

            if (in_array($this->getEnvironment(), array('dev', 'test'))) {
                // Other bundles...
                $bundles[] = new Acme\DemoBundle\AcmeDemoBundle();
            }

            return $bundles;
        }
    }

## You still need to write the documentation

After running **fossil** you still need to provide some information (for
instance the elevator pitch in `README.md`) by editing those files:

* `README.md`
* `doc/01-introduction.md`
* `doc/03-usage.md`
* `doc/04-tests.md`

But is that enough? While I think **fossil** automates as much things as
possible, there's still some part of your project that needs specific
documentation.

For example you could add recipes which describe common tasks, or a glossary
defining technical or business terms used in your project.

## Conclusion

Bootstrap the markdown files of your new and your old FOSS projects using
**[fossil](https://github.com/gnugat/fossil)**, and then complete the
documentation so everyone can see how awesome your work is!

Happy hacking!
