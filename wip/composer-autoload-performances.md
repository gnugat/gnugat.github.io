<p>Programming languages usually allow us to split our code in many files.</p>

<p>In PHP, this is done via <a href="http://php.net/manual/en/function.include.php">include</a>
functions. However calling it directly might be cumbersome as:</p>

<ul>
<li>we need to know the path to include (what happens if we want to add, move or remove a file? Especially with third party libraries)</li>
<li>we want to require the file exactly once (or else we get a Fatal Error: use of non existing class / cannot redeclare existing class)</li>
</ul>

<p>PHP provides an automatic way to include necessary files: <a href="http://php.net/manual/en/language.oop5.autoload.php">autoloading</a>.
If we try to use a non existing class, trait or interface then it's going to check
if registered "autoloader" can include them.</p>

<p><a href="https://getcomposer.org/">Composer</a>, the PHP package manager, registers a powerful
and efficient autoloader. In this article we'll have a look at its performance
using <a href="http://blackfire.io/">Blackfire</a> to profile it.</p>

<h2 id="composer-optimizations">Composer Optimizations</h2>

<p>Composer <code>install</code> and <code>update</code> commands both take some interresting options.
In this section we'll have a look at <code>--optimize-autoloader</code> (<code>-o</code>)
and <code>--classmap-authoritative</code> (<code>-a</code>).</p>

<h3 id="optimize-autoloader">Optimize autoloader</h3>

<p>With the <code>--optimize-autoloader</code> option, Composer will generate a
<code>vendor/composer/autoload_classmap.php</code> file containing an array associating
Fully Qualified Class Names (FQCN) to the path of their files.</p>

<p>It is then used when trying to autoload a class using a simple <code>isset</code>.</p>

<p>If the class isn't in the class map, then Composer will try to convert the class name into a file path (first using
<a href="www.php-fig.org/psr/psr-4/">PSR-4</a> convention, then <a href="www.php-fig.org/psr/psr-0/">PSR-0</a>),
and then it will call <code>file_exists</code> using all registered paths until the file is found.</p>

<p>As we can see, the class map is quite helpful in boosting autoloading performances,
without any downside (calling once <code>isset</code>, even if the result is false, is negligeable)
making the <code>-o</code> option a must have in any situations.</p>

<h3 id="class-map-authoritative">Class map authoritative</h3>

<p>By default Composer acts in a secure way: if a class doesn't exist in the class
map it will try to autoload it. This can happen for the following reasons:</p>

<ul>
<li>a new class has been created, and the class map hasn't been updated</li>
<li>we use a combination of other autoloaders</li>
</ul>

<p>While developing an application we might create new classes, so the first use case
is helpful. In production there are a few chances thastream_resolve_include_patht no new classes will be created,
making the fallback unnecessary.</p>

<p>If we use another autoloader, then the fallback will actually slow down our autoloading.</p>

<h3 id="conclusion">Conclusion</h3>

<p>Always running Composer <code>install</code> and <code>update</code> with <code>-o</code> option is an easy way to
improve autoloading performances.</p>

<p>When using Composer with another autoloader it might be worth using <code>-a</code> option
in production environment (or also in development environment, as long as we
remember to update the class map for every class we create).</p>

<h2 id="composer-overhead">Composer overhead</h2>

<p>In this first section, we're going to check Composer's overhead by including it without
autoloading anything.</p>

<h3 id="0-dependencies">0 dependencies</h3>

<p>Create the following <code>composer.json</code> file:</p>

<pre><code>{
    "require": {
    }
}
</code></pre>

<p>Then create the following <code>index.php</code> file:</p>

<pre><code class="php">&lt;?php
// index.php

require __DIR__.'/vendor/autoload.php';
</code></pre>

<p>Finally run those commands:</p>

<pre><code>composer install -o --no-dev
php -S localhost:2501 &amp;
curl localhost:2501
blackfire curl localhost:2501
killall php
</code></pre>

<p>This should result in the following <a href="https://blackfire.io/profiles/532210e3-041d-4de1-812b-5275e3f98c0b/graph">profiling graph</a>:</p>

<iframe frameborder="0" allowfullscreen src="https://blackfire.io/profiles/532210e3-041d-4de1-812b-5275e3f98c0b/embed"></iframe>

<p>We can see that autoloading overhead is quite insignificant, its bottleneck being
<code>spl_autoload_call</code>.</p>

<h3 id="1-dependency">1 dependency</h3>

<p>We're now going to add one dependency (e.g. Symfony Yaml component) in <code>composer.json</code>:</p>

<pre><code>{
    "require": {
        "symfony/yaml": "^3.0"
    }
}
</code></pre>

<p>Then run the following commands:</p>

<pre><code>composer update -o --no-dev
php -S localhost:2501 &amp;
curl localhost:2501
blackfire curl localhost:2501
killall php
</code></pre>

<p>This time the <a href="https://blackfire.io/profiles/0569773f-922a-4dc5-ac22-cbc08b9f9408/graph">profiling graph</a>
should look like this:</p>

<iframe frameborder="0" allowfullscreen src="https://blackfire.io/profiles/0569773f-922a-4dc5-ac22-cbc08b9f9408/embed"></iframe>

<p>By having a look at the <a href="https://blackfire.io/profiles/compare/e0778bf9-33e7-4c27-b525-f3979921cc52/graph">comparison graph</a>,
we can see that additional calls were made for PSR 4 specific autoloading, but the
is still insignificant (the PSR 4 calls don't even appear in the "hot path").</p>

<h3 id="3-dependencies">3 dependencies</h3>

<p>We're going to add two more dependencies (e.g. Symfony Debug and Finder components) in <code>composer.json</code>:</p>

<pre><code>{
    "require": {
        "symfony/debug": "^3.0",
        "symfony/finder": "^3.0",
        "symfony/yaml": "^3.0"
    }
}
</code></pre>

<p>Then run the following commands:</p>

<pre><code>composer update -o --no-dev
php -S localhost:2501 &amp;
curl localhost:2501
blackfire curl localhost:2501
killall php
</code></pre>

<p>This should result in the follwing <a href="https://blackfire.io/profiles/4ceeb964-8c42-4004-b429-4a7744d369d4/graph">profiling graph</a>:</p>

<iframe frameborder="0" allowfullscreen src="https://blackfire.io/profiles/4ceeb964-8c42-4004-b429-4a7744d369d4/embed"></iframe>

<p>There's one new function call, related to PSR 0 autoloading, but apart from that
the graph looks similar. Let's confirm that assumption by checking the <a href="https://blackfire.io/profiles/compare/6fe552b2-6acb-4d6c-b072-f5fe54fac852/graph">comparison graph</a>:</p>

<iframe frameborder="0" allowfullscreen src="https://blackfire.io/profiles/compare/6fe552b2-6acb-4d6c-b072-f5fe54fac852/embed"></iframe>

<p>This helps us spot that for each new dependency, we're going to make an additional
call to <code>strlen</code> and <code>setPsr4</code> (or <code>set</code> depending on the dependecy's autoloading strategy).</p>

<blockquote>
  <p><strong>Note</strong>: <code>strlen</code> is quite cheap in PHP, as strings carry their length with them
  (no dynamic computations done).</p>
</blockquote>

<p>We can also see that <code>autoload_classmap</code> will take more and more time to load
(filesytem operations) and memory (probably because it's an array with more and more elements).</p>

<p>And of course as expected, the more dependencies we add, the more expensive
<code>spl_autoload_call</code> will be (~+100%), but note that it's currently insignificant
compared to the other calls (~1%).</p>

<blockquote>
  <p><strong>Note</strong>: Here's a reminder that for now, we're not autoloading any classes.</p>
</blockquote>

<h3 id="many-dependencies">Many dependencies</h3>

<p>We're going to add many dependencies (e.g. Symfony Components) in <code>composer.json</code>:</p>

<pre><code>{
    "require": {
        "symfony/asset": "^3.0",
        "symfony/browser-kit": "^3.0",
        "symfony/class-loader": "^3.0",
        "symfony/config": "^3.0",
        "symfony/console": "^3.0",
        "symfony/css-selector": "^3.0",
        "symfony/debug": "^3.0",
        "symfony/dependency-injection": "^3.0",
        "symfony/dom-crawler": "^3.0",
        "symfony/event-dispatcher": "^3.0",
        "symfony/expression-language": "^3.0",
        "symfony/filesystem": "^3.0",
        "symfony/finder": "^3.0",
        "symfony/form": "^3.0",
        "symfony/http-foundation": "^3.0",
        "symfony/http-kernel": "^3.0",
        "symfony/options-resolver": "^3.0",
        "symfony/process": "^3.0",
        "symfony/property-access": "^3.0",
        "symfony/property-info": "^3.0",
        "symfony/routing": "^3.0",
        "symfony/security": "^3.0",
        "symfony/serializer": "^3.0",
        "symfony/stopwatch": "^3.0",
        "symfony/templating": "^3.0",
        "symfony/translation": "^3.0",
        "symfony/validator": "^3.0",
        "symfony/var-dumper": "^3.0",
        "symfony/yaml": "^3.0"
    }
}
</code></pre>

<p>Then run the following commands:</p>

<pre><code>composer update -o --no-dev
php -S localhost:2501 &amp;
curl localhost:2501
blackfire curl localhost:2501
killall php
</code></pre>

<p>Now let's have a look at the <a href="https://blackfire.io/profiles/047c3640-6b6a-4f38-8554-030cd3757034/graph">profiling graph</a>:</p>

<iframe frameborder="0" allowfullscreen src="https://blackfire.io/profiles/047c3640-6b6a-4f38-8554-030cd3757034/embed"></iframe>

<p>We can see that autoloading overhead has drastically grown, but is still negligeable.
To get more insight we need to check the <a href="https://blackfire.io/profiles/compare/42af3ba9-e96f-41ca-a699-6e68e8738046/graph">comparison graph</a>:</p>

<iframe frameborder="0" allowfullscreen src="https://blackfire.io/profiles/compare/42af3ba9-e96f-41ca-a699-6e68e8738046/embed"></iframe>

<p>It is now clear that some of these dependencies use another autoloading strategy
(<code>file</code>, mainly used for functions or bootstraping), hence the additional 6 calls
to <code>composerRequire*</code>.</p>

<p>Those bootstrap files contain some logic, so we'll have to ignore calls like <code>file_exists</code>.</p>

<h3 id="conclusion">Conclusion</h3>

<p>Composer adds a small overhead that can be ignored. The more dependencies we
register, the bigger this overhead becomes (even if we don't use them).</p>

<h2 id="composer-no-development">Composer No Development</h2>

<p>As we've seen above, the less dependencies to autoload, the better. Projects
usually include files that wouldn't be used in production: tests, fixtures, etc.</p>

<p>While still useful in development mode, we might want to remove those
Composer <code>install</code> and <code>update</code> commands both take some interresting options.
In this section we'll have a look at <code>--no-dev</code>, <code>--optimize-autoloader</code> (<code>-o</code>)
and <code>--classmap-authoritative</code> (<code>-a</code>).</p>

<h3 id="no-development-dependencies%2Fautoloading">No development dependencies/autoloading</h3>

<p>Composer allows us to specify dependencies and autoloading that would only be
used for development purpose, for example test frameworks:</p>

<pre><code>{
    "autoload": {
        "psr-4": {
            "": "src"
        }
    },
    "autoload-dev": {
        "psr-4": {
            "": "tests"
        }
    },
    "require": {
        "symfony/yaml": "^3.0"
    },
    "require-dev": {
        "phpunit/phpunit": "^5.2"
    }
}
</code></pre>

<p>As we've seen in the previous section, the less dependencies we autoload, th</p>
