---
layout: post
title: "eXtreme Legacy 1: Dockerizing a 2005 LAMP app"
tags:
    - docker
    - extreme-legacy
---

> 🤘 From the abyssal depths of forgotten servers,
> Docker the Void-Walker awakens to drag ancient LAMP stack from their tombs,
> wrapping them in the obsidian chains of containerization! 🔥

Back in 2005, I learned how to write Linux/Apache/MySQL/PHP websites thanks
to the Site du Zero (SdZ), which is now known as [Open Classrooms](https://openclassrooms.com/en/).

I also used to play a web-browser game, similar to [OGame](https://fr.wikipedia.org/wiki/OGame),
called BisouLand (SkySwoon). Turns out its creator also built it through SdZ tutorials!

Fast forward 20 years later (today),
I received a message on LinkedIn from a CTO asking me the following:

> 💬 "Are you willing to work with **eXtreme Legacy** code on occasion?"

I wondered to myself: what is eXtreme Legacy code? And I immediately remembered BisouLand.

You see, back in 2011,
its creator had made it Open Source on github and made me code collaborator...

So I _do_ have access to a 2005 LAMP stack website,
cobbled together by someone learning stuff on the go from the internet.

What would it take, in 2025, to get an eXtreme Legacy app up and running?

This is what we're going to find out in this series.

Today's first article is about getting it to run, at least locally.

* [The Project](#the-project)
* [Containerisation](#containerization)
* [Conclusion](#conclusion)

## The Project

The [version 1](https://github.com/pyricau/bisouland/tree/v1) has the following tree directory:

```
web/
├── .htaccess
├── checkConnect.php
├── deconnexion.php
├── favicon.ico
├── images/
├── includes/
│   ├── bisouStyle2.css
│   ├── compteur.js
│   ├── newbisouStyle2.css
│   └── prev.js
├── index.php
├── phpincludes/
│   ├── accueil.php
│   ├── action.php
│   ├── aide.php
│   ├── attaque.php
│   ├── bd.php
│   ├── bisous.php
│   ├── confirmation.php
│   ├── connected.php
│   ├── connexion.php
│   ├── erreur404.php
│   ├── evo.php
│   ├── fctIndex.php
│   ├── nuage.php
│   ├── ...
│   ├── pages.php
│   └── yeux.php
└── redirect.php
```

The `.htaccess` file contains URL rewrite rules for Apache:

```
RewriteEngine on
RewriteRule (.+)\.confirmation\.html$ /index.php?page=confirmation&id=$1
RewriteRule (.+)\.bisous\.html$ /index.php?page=bisous&cancel=$1
RewriteRule (.+)\.(.+)\.nuage\.html$ /index.php?page=nuage&saut=1&sautnuage=$1&sautposition=$2
RewriteRule (.+)\.nuage\.html$ /index.php?page=nuage&nuage=$1
RewriteRule (.+)\.(.+)\.action\.html$ /index.php?page=action&nuage=$1&position=$2
RewriteRule (.+)\.(.+)\.yeux\.html$ /index.php?page=yeux&Dnuage=$1&Dpos=$2
RewriteRule (.+)\.html$ /index.php?page=$1
ErrorDocument 404 /erreur404.html
```

There are no Database schema, but a quick scan at the files will reveal the use
of MySQL, for example `web/phpincludes/bd.php`:

```php
<?php

function bd_connect() {
        mysql_pconnect("HOST", "USER", "PASSWORD");
        mysql_select_db("DATABASE");
}
```

As for the code architecture, the file `web/index.php` acts as a
front controller that displays the layout of the website, and then includes
a file from `web/phpincludes/` for the actual page content.

The HTML is mixed with the MySQL queries, session managemenet, game logic
and any other PHP code. Code and comments are written in French, and there are
several encoding issues.

Here's an extract from `web/index.php`:

```php
<?php

header('Content-type: text/html; charset=ISO-8859-1'); 

session_start();
ob_start();
include 'phpincludes/bd.php';
bd_connect();
include('phpincludes/fctIndex.php');

//Si la variable $_SESSION['logged'] n'existe pas, on la créée, et on l'initialise a false
if (!isset($_SESSION['logged'])) $_SESSION['logged'] = false;

//Si on est pas connecté.
if ($_SESSION['logged'] == false)
{
  $id=0;
  //On récupère les cookies enregistrés chez l'utilisateurs, s'ils sont la.
  if (isset($_COOKIE['pseudo']) && isset($_COOKIE['mdp']))
  {
    $pseudo = htmlentities(addslashes($_COOKIE['pseudo']));
    $mdp = htmlentities(addslashes($_COOKIE['mdp']));
    //La requête qui compte le nombre de pseudos
    $sql = mysql_query("SELECT COUNT(*) AS nb_pseudo FROM membres WHERE pseudo='".$pseudo."'");
    if (mysql_result($sql,0,'nb_pseudo') != 0)
    {
      //Sélection des informations.
      $sql_info = mysql_query("SELECT id, confirmation, mdp, nuage FROM membres WHERE pseudo='".$pseudo."'");
      $donnees_info = mysql_fetch_assoc($sql_info);
      //Si le mot de passe est le même (le mot de passe est déjà crypté).
      if ($donnees_info['mdp'] == $mdp)
      {
        //Si le compte est confirmé.
        if ($donnees_info['confirmation'] == 1)
        {
          //On modifie la variable qui nous indique que le membre est connecté.
          $_SESSION['logged'] = true;
          $page='cerveau';
        }
      }
    }
  }
}

if ($_SESSION['logged'] == true)
{
  //l'id du membre.
  $id=$_SESSION['id'];

  //Fonction destinée à l'administration
  if (isset($_POST['UnAct']) && $id==12)
  {
    actionAdmin();
  }

  $sql_info = mysql_query(
    "SELECT timestamp, coeur, bouche, amour, jambes, smack, baiser, pelle, tech1, tech2, tech3, tech4, dent, langue, bloque, soupe, oeil"
    ." FROM membres WHERE id='".$id."'"
  );
  $donnees_info = mysql_fetch_assoc($sql_info);
  //On récupère le nombre de points d'amour.
  $amour = $donnees_info['amour'];
?>

<!DOCTYPE html>
<html>
<head>
  <meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1" /> 
  <link rel="stylesheet" media="screen" type="text/css" title="bisouStyle2" href="includes/bisouStyle2.css" /> 
  <link rel="shorcut icon" href="http://bisouland.piwai.info/favicon.ico"/>
  <meta http-equiv="Content-Language" content="fr" />
</head>
<body>
  <div id="speedbarre">
  <?php if ($_SESSION['logged'] == true)
    {?>
	  <?php echo formaterNombre(floor($amour)); ?>
    <?php
    }
    else
    {
    ?>
    <a href="connexion.html">Connexion</a>
    <?php } ?>
  </div>

  <div id="corps">
    <?php
    include('phpincludes/pages.php');
	if (isset($array_pages[$page]))
	{
      include('phpincludes/'.$array_pages[$page]);
	}
	else
	{
      include('phpincludes/erreur404.php');
	}
    ?>
    </div>
</body>
</html>
```

😵

In addition to the spaghetti code, we can immediately spot security issues.
But we cannot fix anything until we can manually test the website,
so how do we get it to run?

## Containerisation

Back in 2005, the most common versions of the LAMP stack were:

* Apache: 2
* MySQL: MySQL 4.0 - 5.0
* PHP 4.3 - 5.1

Applications written for MySQL 4.0 and PHP 4.3 can be run up to MySQL 5.7
and PHP 5.6. Some deprecation notices would be issued, but in terms of backward
compatibility that's how far we can stretch things.

So let's create a `Dockerfile` that will have Apache 2, PHP 5.6 and MySQL 5.7:

```
# syntax=docker/dockerfile:1

FROM php:5.6-apache

# Update sources.list to use archive repositories for Debian Stretch
RUN sed -i 's/deb.debian.org/archive.debian.org/g' /etc/apt/sources.list \
    && sed -i 's/security.debian.org/archive.debian.org/g' /etc/apt/sources.list \
    && sed -i '/stretch-updates/d' /etc/apt/sources.list

# Install system dependencies and PHP extensions in single layer
RUN docker-php-ext-install mysql \
    && a2enmod rewrite

# Set working directory
WORKDIR /var/www/html

# Copy application files with proper ownership
COPY --chown=www-data:www-data web/ /var/www/html/
```

With the following `compose.yaml`, we'll set up the Apache and MySQL servers:

```yaml
name: skyswoon-monolith

services:
  web:
    build: .
    ports:
      - "8080:80"
    volumes:
      - ./web:/var/www/html
    depends_on:
      - db
    environment:
      DATABASE_HOST: ${DATABASE_HOST}
      DATABASE_USER: ${DATABASE_USER}
      DATABASE_PASSWORD: ${DATABASE_PASSWORD}
      DATABASE_NAME: ${DATABASE_NAME}
    restart: unless-stopped

  db:
    image: mysql:5.7
    platform: linux/amd64
    environment:
      MYSQL_ROOT_PASSWORD: ${MYSQL_ROOT_PASSWORD}
      MYSQL_DATABASE: ${DATABASE_NAME}
      MYSQL_USER: ${DATABASE_USER}
      MYSQL_PASSWORD: ${DATABASE_PASSWORD}
    volumes:
      - mysql_data:/var/lib/mysql
    ports:
      - "127.0.0.1:3306:3306"
    restart: unless-stopped

volumes:
  mysql_data:
```

You might notice that I've mentioned some environment variables,
to configure the database. These will need to be set in a `.env` file:

```
# Database
DATABASE_HOST=db
DATABASE_USER=database_user
DATABASE_PASSWORD=database_password
DATABASE_NAME=database_name
# MySQL root password (for Docker)
MYSQL_ROOT_PASSWORD=mysql_root_password
```

When the `docker compose up` is run,
Docker Composer automatically reads from `.env` and sets the environment variable,
then PHP will copy these into the `$_ENV` array super global,
so we can get the values like so in `web/phpincludes/bd.php`:

```php
<?php

function bd_connect()
{
    mysql_pconnect(
        $_ENV['DATABASE_HOST'],
        $_ENV['DATABASE_USER'],
        $_ENV['DATABASE_PASSWORD'],
    );
    mysql_select_db($_ENV['DATABASE_NAME']);
}
```

Last but not least, I'm adding a `Makefile`, to avoid having to type long
`docker compose build; docker compose up` commands: [see file in github](https://github.com/pyricau/bisouland/blob/b31597c47a49e0dd2b87fbd55bd608530f81efec/Makefile).

> **Super Secret Tip**:
> I've written about [My Symfony Dockerfile](/2025/08/06/my-symfony-dockerfile.html),
> and [My Symfony Makefile](/2025/08/06/my-symfony-makefile.html).

## Conclusion

> 💻 Source code:
> * [Before our changes](https://github.com/pyricau/bisouland/tree/4.0.0)
> * [After containerisation](https://github.com/pyricau/bisouland/tree/4.0.6)

<img alt="BisouLand screenshot" src="/images/xl-1-bisouland-screenshot.png" width="100%" />

And we did it! now by typing:

```console
make build; make up
```

We get BisouLand running live, 20 years after its conception.

You can visit it there: http://localhost:8080/accueil.html.

> ⁉️ _What do you mean it doesn't work? It works on my machine!_
