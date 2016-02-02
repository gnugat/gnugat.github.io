<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="utf-8">
    <title>The Ultimate Developer Guide to Symfony &mdash; Loïc Faugeron &mdash; Technical Blog</title>
    <meta name="description" content="Technical articles about Symfony and TDD">
    <meta name="author" content="Loïc Faugeron">

    <meta name="viewport" content="width=device-width, initial-scale=1">

    <link rel="canonical" href="/wip/nag-nag-nag.md"/>
        <link rel="alternate" href="http://gnugat.github.io/feed/atom.xml" type="application/atom+xml" title="Loïc Faugeron"/>
    
    <link href="http://fonts.googleapis.com/css?family=Raleway:400,300,600" rel="stylesheet" type="text/css">

    <link rel="stylesheet" href="http://gnugat.github.io/css/normalize.css">
    <link rel="stylesheet" href="http://gnugat.github.io/css/skeleton.css">
    <link rel="stylesheet" href="http://gnugat.github.io/css/dop-dop-dop.css">
    <link rel="stylesheet" href="http://gnugat.github.io/css/highlight_9_0_0_monokai_sublime.min.css">
</head>
<body>
    <div class="container">
        <header class="title">
            <h1>
                <a href="http://gnugat.github.io/">Loïc Faugeron</a>
                <span class="sub-title">Technical Blog</span>
            </h1>
        </header>

        <article>
            <header>
                <h2>
    The Ultimate Developer Guide to Symfony
    <span class="sub-title">03/02/2016</span>
</h2>
                            <nav>
                                                            <a class="button " href="http://gnugat.github.io/tags/symfony">symfony</a>
                                                            <a class="button " href="http://gnugat.github.io/tags/ultimate%20symfony%20series">ultimate symfony series</a>
                    </nav>
                </header>

                <p><a href="http://symfony.com">Symfony</a> provides many standalone libraries (also known as
"Components") that help us build applications.</p>

<p>In this guide we'll see the main ones that allow us to build an application:</p>

<ul>
<li><a href="#http-kernel">HTTP Kernel</a></li>
<li><a href="#event-dispatcher">Event Dispatcher</a></li>
<li><a href="#routing">Routing</a></li>
<li><a href="#dependency-injection">Dependency Injection</a></li>
<li><a href="#console">Console</a></li>
</ul>

<h2 id="http-kernel">HTTP kernel</h2>

<p>Symfony provides a <a href="http://symfony.com/doc/current/components/http_kernel/introduction.html">HttpKernel component</a><code>which follows the HTTP protocol: it converts a</code>Request<code>into a</code>Response`.</p>

<p>To do so, it goes through the following steps:</p>

<ol>
<li><code>kernel.request</code>: receive a Request (created using <a href="http://php.net/manual/en/language.variables.superglobals.php">PHP super globals</a>)</li>
<li><code>kernel.controller</code>: executes a Controller</li>
<li><code>kernel.view</code>: converts the Controller's returned value into a Response if necessary</li>
<li><code>kernel.response</code>: returns a Response</li>
<li><code>kernel.terminate</code>: actions done after the Response (clean ups, sending emails, etc)</li>
</ol>

<p>And optionally:</p>

<ul>
<li><code>kernel.exception</code>: handles errors</li>
</ul>

<p>It all revolves around the following interface:</p>

<pre><code class="php">&lt;?php

namespace Symfony\Component\HttpKernel;

use Symfony\Component\HttpFoundation\Request;
use Symfony\Component\HttpFoundation\Response;

interface HttpKernelInterface
{
    /**
     * @param Request $request
     * @param int     $type
     * @param bool    $catch
     *
     * @return Response
     */
    public function handle(Request $request, $type = 1, $catch = false);
}
</code></pre>

<h2 id="event-dispatcher">Event Dispatcher</h2>

<p>For each steps, Symfony dispatches an event using the <a href="http://symfony.com/doc/current/components/event_dispatcher/introduction.html">EventDispatcher component</a>
which allows the possibility to execute registered functions (also known as "Listeners").</p>

<p>It revolves around the following interface:</p>

<pre><code class="php">&lt;?php

namespace Symfony\Component\EventDispatcher;

interface EventDispatcherInterface
{
    /**
     * @param string   $eventName
     * @param callable $listener
     * @param int      $priority
     */
    public function addListener($eventName, $listener, $priority = 0);

    /**
     * @param string $eventName
     * @param Event  $event
     */
    public function dispatch($eventName, Event $event = null);
}
</code></pre>

<blockquote>
  <p><strong>Note</strong>: This snippet is a truncated version, the actual interface has methods
  to add/remove/get/check listeners and subscribers (which are similar to listeners).</p>
</blockquote>

<h3 id="kernel-request">Kernel Request</h3>

<p>Listeners that registered for <code>kernel.request</code> can modify the Request object.</p>

<p>Out of the box there's a <code>RouterListener</code> regitered which sets the following parameters
in <code>Request-&gt;attributes</code>:</p>

<ul>
<li><code>_route</code>: the route name that matched the Request</li>
<li><code>_controller</code>: a callable that will handle the Request and return a Response</li>
<li><code>_route_parameters</code>: query parameters exctracted from the Request</li>
</ul>

<p>An example of a custom Listener could be one that decodes JSON content and sets
it in <code>Request-&gt;request</code>:</p>

<pre><code class="php">&lt;?php

namespace AppBundle\EventListener;

use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Event\GetResponseEvent;

/**
 * PHP does not populate $_POST with the data submitted via a JSON Request,
 * causing an empty $request-&gt;request.
 *
 * This listener fixes this.
 */
class JsonRequestContentListener
{
    /**
     * @param GetResponseEvent $event
     */
    public function onKernelRequest(GetResponseEvent $event)
    {
        $request = $event-&gt;getRequest();
        $hasBeenSubmited = in_array($request-&gt;getMethod(), array('PATCH', 'POST', 'PUT'), true);
        $isJson = (1 === preg_match('#application/json#', $request-&gt;headers-&gt;get('Content-Type')));
        if (!$hasBeenSubmited || !$isJson) {
            return;
        }
        $data = json_decode($request-&gt;getContent(), true);
        if (JSON_ERROR_NONE !== json_last_error()) {
            $event-&gt;setResponse(new Response('{"error":"Invalid or malformed JSON"}', 400, array('Content-Type' =&gt; 'application/json')));
        }
        $request-&gt;request-&gt;add($data ?: array());
    }
}
</code></pre>

<p>Another example would be to start a database transaction:</p>

<pre><code>&lt;?php

namespace AppBundle\EventListener;

use PommProject\Foundation\QueryManager\QueryManagerInterface;
use Symfony\Component\HttpKernel\Event\GetResponseEvent;

class StartTransactionListener
{
    /**
     * @var QueryManagerInterface
     */
    private $queryManager;

    /**
     * @param QueryManagerInterface $queryManager
     */
    public function __construct(QueryManagerInterface $queryManager)
    {
        $this-&gt;queryManager = $queryManager;
    }

    /**
     * @param GetResponseEvent $event
     */
    public function onKernelRequest(GetResponseEvent $event)
    {
        $this-&gt;queryManager-&gt;query('START TRANSACTION');
    }
}
</code></pre>

<blockquote>
  <p><strong>Note</strong>: <a href="http://pomm-project.org">Pomm</a> is used here as an example.</p>
</blockquote>

<h3 id="kernel-response">Kernel Response</h3>

<p>Listeners that registered for <code>kernel.response</code> can modify the Response object.</p>

<p>Out of the box there's a <code>ResponseListener</code> regitered which sets some Response
headers according to the Request's one.</p>

<h3 id="kernel-terminate">Kernel Terminate</h3>

<p>Listeners that registered for <code>kernel.terminate</code> can execute actions after the
Response has been served (if our wweb server uses FastCGI).</p>

<p>An example of a custom Listener could be one that rollsback a database transaction,
when running in test environment:</p>

<pre><code class="php">&lt;?php

namespace AppBundle\EventListener\Pomm;

use PommProject\Foundation\QueryManager\QueryManagerInterface;
use Symfony\Component\HttpKernel\Event\PostResponseEvent;

class RollbackListener
{
    /**
     * @var QueryManagerInterface
     */
    private $queryManager;

    /**
     * @param QueryManagerInterface $queryManager
     */
    public function __construct(QueryManagerInterface $queryManager)
    {
        $this-&gt;queryManager = $queryManager;
    }

    /**
     * @param PostResponseEvent $event
     */
    public function onKernelTerminate(PostResponseEvent $event)
    {
        $this-&gt;queryManager-&gt;query('ROLLBACK');
    }
}
</code></pre>

<blockquote>
  <p><strong>Note</strong>: We'll se later how to register this listener only for test environment.</p>
</blockquote>

<h3 id="kernel-exception">Kernel Exception</h3>

<p>Listeners that registered for <code>kernel.exception</code> can catch an exception and generate
an appropirate Response object.</p>

<p>An example of a custom Listener could be one that logs debug information and generates
a 500 Response:</p>

<pre><code class="php">&lt;?php

namespace AppBundle\EventListener;

use Psr\Log\LoggerInterface;
use Ramsey\Uuid\Uuid;
use Symfony\Component\HttpFoundation\Response;
use Symfony\Component\HttpKernel\Event\GetResponseForExceptionEvent;

class ExceptionListener
{
    /**
     * @var LoggerInterface
     */
    private $logger;

    /**
     * @param LoggerInterface $logger
     */
    public function __construct(LoggerInterface $logger)
    {
        $this-&gt;logger = $logger;
    }

    /**
     * @param GetResponseForExceptionEvent $event
     */
    public function onKernelException(GetResponseForExceptionEvent $event)
    {
        $exception = $event-&gt;getException();
        $token = Uuid::uuid4()-&gt;toString();
        $this-&gt;logger-&gt;critical(
            'Caught PHP Exception {class}: "{message}" at {file} line {line}',
            array(
                'class' =&gt; get_class($exception),
                'message' =&gt; $exception-&gt;getMessage(),
                'file' =&gt; $exception-&gt;getFile(),
                'line' =&gt; $exception-&gt;getLine()
                'exception' =&gt; $exception,
                'token' =&gt; $token
            )
        );
        $event-&gt;setResponse(new Response(
            json_encode(array(
                'error' =&gt; 'An error occured, if it keeps happening please contact an administrator and provide the following token: '.$token,
            )),
            500,
            array('Content-Type' =&gt; 'application/json'))
        );
    }
}
</code></pre>

<blockquote>
  <p><strong>Note</strong>: <a href="https://github.com/ramsey/uuid">Ramsey UUID</a> is used here to provide
  a unique token that can be referred to.</p>
</blockquote>

<h2 id="routing">Routing</h2>


            <footer>
                                    <hr />
            </footer>
        </article>

        <footer>
            <nav class="row">
                <a class="button three columns" href="http://gnugat.github.io/about">About</a>
                <a class="button three columns" href="http://gnugat.github.io/">Articles</a>
                <a class="button three columns" href="http://gnugat.github.io/feed/atom.xml">RSS</a>
                <a class="button three columns" href="https://github.com/gnugat/gnugat.github.io/tree/master/_sculpin">Sources</a>
            </nav>
        </footer>
    </div>

    <script src="http://gnugat.github.io/js/highlight_9_0_0.min.js"></script>
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
