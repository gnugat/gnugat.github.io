<p><a href="http://www.slideshare.net/liuggio/benchmark-profile-and-boost-your-symfony-application-32123703">See Talk by Giulio De Donato</a></p>

<p>Composer autoloading:</p>

<pre><code>cd /tmp
mkdir autoloading-1
cd autoloading-1
composer require psr/log
composer remove psr/log
</code></pre>

<pre><code class="php">&lt;?php
// index.php

require __DIR__.'/vendor/autoload.php';
</code></pre>

<pre><code>composer install -o --no-dev
php -S localhost:2501 &amp;
blackfire curl localhost:2501
killall php
</code></pre>
