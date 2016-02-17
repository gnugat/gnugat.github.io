<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>The Ultimate Developer Guide to Symfony &mdash; Loïc Faugeron &mdash; Technical Blog</title>
    <meta name="description" content="Technical articles about Symfony and TDD">
    <meta name="author" content="Loïc Faugeron">

    <meta name="viewport" content="width=device-width, initial-scale=1">

    <link rel="canonical" href="/wip/another-ultimate-guide.md"/>
        <link rel="alternate" href="https://gnugat.github.io/feed/atom.xml" type="application/atom+xml" title="Loïc Faugeron"/>
    
    <link href="https://fonts.googleapis.com/css?family=Raleway:400,300,600" rel="stylesheet" type="text/css">

    <link rel="stylesheet" href="https://gnugat.github.io/css/normalize.css">
    <link rel="stylesheet" href="https://gnugat.github.io/css/skeleton.css">
    <link rel="stylesheet" href="https://gnugat.github.io/css/dop-dop-dop.css">
    <link rel="stylesheet" href="https://gnugat.github.io/css/highlight_9_0_0_monokai_sublime.min.css">
</head>
<body>
    <div class="container">
        <header class="title">
            <h1>
                <a href="https://gnugat.github.io/">Loïc Faugeron</a>
                <span class="sub-title">Technical Blog</span>
            </h1>
        </header>

        <article>
            <header>
                <h2>
    The Ultimate Developer Guide to Symfony
    <span class="sub-title">17/02/2016</span>
</h2>
                            <nav>
                                                            <a class="button " href="https://gnugat.github.io/tags/symfony">symfony</a>
                                                            <a class="button " href="https://gnugat.github.io/tags/ultimate%20symfony%20series">ultimate symfony series</a>
                    </nav>
                </header>

                <h2 id="project-skeleton">Project Skeleton</h2>

<p>Deciding how our project directory is organized is up to us, but for consistency
and convenience reasons we usually use "Distributions" which are project skeletons:</p>

<pre><code>composer create-project gnugat/symfony-empty-edition our-project
cd our-project
</code></pre>

<blockquote>
  <p><strong>Note</strong>: Here we've decided to use the <a href="https://github.com/gnugat/symfony-empty-edition">Symfony Empty Edition</a>
  which embeds the strict minimum.</p>
  
  <p>Another option could have been the <a href="https://github.com/symfony/symfony-standard">Standard Edition</a>
  which includes many tools commonly used to build full-stack websites.</p>
  
  <p>To find more distributions, <a href="http://symfony.com/distributions">check the official website</a>.</p>
</blockquote>

<p>The directory tree looks like this:</p>

<pre><code>.
├── app
│   └── config
│       ├── routings
│       └── services
├── bin
├── src
│   └── AppBundle
│       ├── Command
│       ├── Controller
│       ├── DependencyInjection
│       ├── EventListener
│       └── Service
├── var
│   ├── cache
│   └── logs
└── web
</code></pre>

<ul>
<li><code>app</code>: configuration</li>
<li><code>bin</code>: scripts</li>
<li><code>src</code>: our code</li>
<li><code>var</code>: temporary files</li>
<li><code>web</code>: public directory exposed via the web server</li>
</ul>


            <footer>
                                    <hr />
            </footer>
        </article>

        <footer>
            <nav class="row">
                <a class="button three columns" href="https://gnugat.github.io/about">About</a>
                <a class="button three columns" href="https://gnugat.github.io/">Articles</a>
                <a class="button three columns" href="https://gnugat.github.io/feed/atom.xml">RSS</a>
                <a class="button three columns" href="https://github.com/gnugat/gnugat.github.io/tree/master/_sculpin">Sources</a>
            </nav>
        </footer>
    </div>

    <script src="https://gnugat.github.io/js/highlight_9_0_0.min.js"></script>
    <script type="text/javascript">hljs.initHighlightingOnLoad();</script>
    <script type="text/javascript">
        var _gaq = _gaq || [];
        _gaq.push(['_setAccount', 'UA-47822314-1']);
        _gaq.push(['_trackPageview']);

        (function() {
            var ga = document.createElement('script'); ga.type = 'text/javascript'; ga.async = true;
            ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
            var s = document.getElementsByTagName('script')[0]; s.parentNode.insertBefore(ga, s);
        })();
    </script>
</body>
</html>
