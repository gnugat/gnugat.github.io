<p>Programming languages usually allow us to split our code in many files.</p>

<p>In PHP, this is done via <a href="http://php.net/manual/en/function.include.php">include</a>
functions. However calling it directly might be cumbersome as:</p>

<ul>
<li>we need to know the path to include (what happens if we want to add, move or remove a file? Especially with third party libraries)</li>
<li>we want to require the file exactly once (or else we get a Fatal Error: use of non existing class / cannot redeclare existing class)</li>
</ul>

<p>PHP provides an automatic way to include necessary files: <a href="http://php.net/manual/en/language.oop5.autoload.php">autoloading</a>.
If we try to use a non existing class, it's going to check if registered "autoloader"
can include them.</p>

<p><a href="https://getcomposer.org/">Composer</a>, the PHP package manager, registers a powerful
and efficient autoloader. In this article we'll have a look at its performance
overhead, using <a href="http://blackfire.io/">Blackfire</a> to profile it.</p>

<p>Our tests will consist of enabling autoloading without calling it, with more and
more dependencies registered.</p>

<h2 id="0-dependencies">0 dependencies</h2>

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

<h2 id="1-dependency">1 dependency</h2>

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

<h2 id="3-dependencies">3 dependencies</h2>

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

<h2 id="many-dependencies">Many dependencies</h2>

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

<p>Overall it confirms the logic that the more dependencies we add, even if we don't
use them, the more overhead we add to our autoloading.</p>
