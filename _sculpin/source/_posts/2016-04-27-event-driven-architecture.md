---
layout: post
title: Event Driven Architecture
---

Ever wondered how [nginx](http://nginx.com/) outperforms [Apache](https://httpd.apache.org/)
or what does [NodeJs](http://nodejs.org/) mean by "event-driven, non-blocking I/O"?

Then you're in luck! This article aims at answering the "how" question, we'll
explore the implementation details of Event Driven Architecture by:

1. implementing a simple (and inefficient) HTTP server
2. adding multiple client handling to it by creating an Event Loop
3. adding time control to it by creating a Scheduler
4. solving the callback hell issue by creating Deferrer and Promise
5. adding "non-blocking" capacity to "blocking" calls by using a Thread Pool

## A story of Input / Output

Input / Output (I/O) can refer to Client / Server communication through sockets,
for example a HTTP server.

[Compared to calculations, I/O is really slow!](https://gist.github.com/jboner/2841832#file-latency-txt)
To understand how this latency can be a performance bottleneck for our applications,
we're going to create a simple HTTP server implementation.

In order to do so, we need to make use of some system calls:

1. create a new "internet" [socket](http://linux.die.net/man/2/socket)
  (there are other types of sockets, e.g. unix ones)
2. [bind](http://linux.die.net/man/2/bind) this socket to a host and port
3. start to [listen](http://linux.die.net/man/2/listen) by creating a connection queue

From this point clients can ask the permission to connect to the socket, they're
going to be queued up until the given maximum in `listen` is reached, at which
point errors are going to be thrown everywhere.

To prevent this nightmare, our priority will be to keep this queue empty by calling
[accept](http://linux.die.net/man/2/accept): it's going to unqueue the first client
and return a new socket dedicated for it, allowing the "server" socket to accept
more clients.

At some point the client will send data in the socket: the HTTP Request. We'll
need to call [read](http://linux.die.net/man/2/read) to retrieve it. We usually
need to parse the received string, for example to create a Request value object
our HTTP application can understand.

The HTTP application could then return a Response value object that we'll need
to convert back to string and send it to the client using [write](http://linux.die.net/man/2/write).

Finally, once done we can call [close](http://linux.die.net/man/2/close) to get
rid of the client and start accepting more.

If we put everything in a loop that runs forever we can handle one client at a
time. Here's an implementation example (written in pseudo language):

```python
# Socket abstracts `socket`, `bind` and `listen`
http_server = new Socket(host, port, max_connections_to_queue)
while true:
    http_connection = http_server.accept()
    data = http_connection.read()
    request = http_request_parse(data)
    response = application(request)
    http_connection.write((string) response)
    http_connection.close()
```

In our loop, for each request we call 3 I/O operations:

* `accept`, this call will wait until a new connection is available
* `read`, this call will *wait* until some data is sent from the client
* `write`, this call will **wait** until the data is sent to the client

That's a lot of **waiting**! While we *wait* for data to be sent, more
clients can try to connect, be queued and eventually reach the limit.

In other words, waiting is blocking. If only we could do something else
while waiting...

## Hang on!

Turns out we can, thanks to polling system calls:

1. we first have to add sockets we want to use to a collection
2. we then call `poll` with the collection of sockets to watch
3. `poll` will **wait** until it detects activity on those, and returns the ones that are ready

As goes the saying: "Blocking. If it's not solving all your problems, you simply
aren't using enough of it".

> **Note**: There's actually many polling system calls:
>
> * `select`, a POSIX standard which takes 3 size fixed bitmap of sockets (read, write, error)
> * `poll`, another POSIX standard which takes an array of sockets
> * `epoll`, a stateful Linux specific system call equivalent to `select`/`poll`
> * `kqueue`, a stateful BSD (that includes Mac OS) specific system call equivalent to `select`/`poll`
> * `IOCP`, a Windows equivalent to `epoll`/`kqueue`
>
> For more information about those, check [epoll VS kqueue](http://www.eecs.berkeley.edu/~sangjin/2012/12/21/epoll-vs-kqueue.html).
> In our article `poll` will refer to polling in general, not to a specific implementation.

With this we can change the architecture of our HTTP server:

1. create the HTTP server socket
2. add it to the collection of sockets to watch
3. start our infinite loop:
   - wait until some sockets are ready
   - if the socket is the HTTP server one:
     1. `accept` it to get a HTTP client socket
     2. add the HTTP client socket to the collection of sockets to watch
   - if the socket is a HTTP client one:
     1. `read` it to get its data
     2. convert the data into a HTTP Request
     3. forward the HTTP Request to the application to get a HTTP Response
     4. convert the HTTP Response to a string and `write` it
     5. `close` the HTTP client socket
     6. remove the HTTP client socket from the collection of sockets to watch

Let's change our HTTP server to use `poll`:

```python
http_server = new Socket(host, port, max_connections_to_queue)
connections = new SocketCollection()
connections.append(http_server)
while true:
    connections_ready = poll(connections)
    for connection in connections_ready:
        if http_server == connection:
            http_connection = http_server.accept()
            connections.append(http_connection)
        else:
            data = connection.read()
            request = http_request_parse(data)
            response = application(request)
            connection.write((string) response)
            connection.close()
            connections.remove(connection)
```

Now we can see the advantage of polling: while waiting for data to be ready on
client sockets, we can now accept more connections on the server socket.

Before we continue, let's refactor our code a bit to abstract away the polling
logic:

```python
class EventLoop:
    function append(connection, callback):
        key = (int) connection
        self._connections[key] = connection
        self._callbacks[key] = callback

    function remove(connection):
        key = (int) connection
        self._connections.pop(key)
        self._callbacks.pop(key)

    function run():
        while true:
            connections_ready = poll(self._connections)
            for connection in connections_ready:
                key = (int) connection
                self._callbacks[key](connection, self)
```

We've named the class `EventLoop`: every time something happens (an *Event*) in
the *Loop*, we call the appropriate callback. Here's our HTTP server with the
`EventLoop`:

```python
function handle_http_request(http_connection, event_loop):
    data = http_connection.read()
    request = http_request_parse(data)
    response = application(request)
    http_connection.write((string) response)
    http_connection.close()
    event_loop.remove(http_connection)

function handle_http_connection(http_server, event_loop):
    http_connection = http_server.accept()
    event_loop.append(http_connection, handle_http_request)

http_server = new Socket(host, port, max_connections_to_queue)
event_loop = new EventLoop()
event_loop.append(http_server, handle_http_connection)
event_loop.run()
```

In the previous implementation, we couldn't make a distinction between client sockets,
with this refactoring we can split our application even more by waiting for
`write` to be ready (usually `poll` is able to make a distinction between sockets
ready to be read and sockets ready to be written).

If we don't have any connections, our server will spend most of its time waiting.
If only we could do something else while waiting...

## Wait a second!

Polling system calls usually take a `timeout` argument: if nothing happens for
the given time it's going to return an empty collection.

By combining it with a `OneOffScheduler`, we can achieve interesting things.
Here's an implementation:

```python
class OneOffScheduler:
    function append(interval, callback, arguments):
        self._callbacks[interval][] = callback
        self._arguments[interval][] = arguments

    function lowest_interval():
        return self._callbacks.keys().min()

    function tick():
        for interval, callbacks in self._callbacks:
            if time.now() % interval != 0:
                continue
            for id, callback in callbacks:
                arguments = self._arguments[interval][id]
                callback(arguments)
                self._callbacks[interval].pop(id)
                self._arguments[interval].pop(id)
```

By "ticking" the clock we check if any registered callback is due.
The `lowest_interval` method will allow us to set a smart timeout for `poll`
(e.g. no callback will mean no timeout, a callback with 5s interval will mean 5s timeout, etc).

Here's our `EventLoop` improved with the `OneOffScheduler`:

```python
class EventLoop:
    function constructor():
        self.one_off_scheduler = new OneOffScheduler()

    function append(connection, callback):
        key = (int) connection
        self._connections[key] = connection
        self._callbacks[key] = callback

    function remove(connection):
        key = (int) connection
        self._connections.pop(key)
        self._callbacks.pop(key)

    function run():
        while true:
            timeout = self.one_off_scheduler.lowest_interval()
            connections_ready = poll(self._connections, timeout)
            for connection in connections_ready:
                key = (int) connection
                self._callbacks[key](connection, self)
            self.one_off_scheduler.tick()
```

There are many `Scheduler` variants possible:

* periodic ones: instead of removing the callback once it's called, we could keep it for the next interval
* idle ones: instead of calling callback every time, we could only call them if nothing is ready

As goes the saying: "Scheduler. If it's not solving all your problems, you simply
aren't using enough of it".

We're now able to execute actions even if no actual events happened. All we need
is to register in our `EventLoop` a callback. And in this callback we can also
register a new callback for our `EventLoop`. And in this callback...

## Async what you did here...

That's a lot of nested callbacks! It might become hard to understand the
"flow of execution" of our application: we're used to read "synchronous" code,
not "asynchronous" code.

What if I told you there's a way to make "asynchronous" code look like "synchronous"
code? One of the way to do this is to implement [promise](http://wiki.commonjs.org/wiki/Promises/A):

1. Create a `Deferrer`
2. ask politely the `Deferrer` to create a `Promise`
   - when creating the `Promise`, the `Deferrer` injects into it a `resolver` callback
3. register a `on_fulfilled` callback in the `Promise`
   - the `Promise` calls the injected `resolver` callback with the given `on_fulfilled` callback as argument
   - this sets `on_fulfilled` callback as an attribute in `Deferrer`
4. tell the `Deferrer` that we finally got a `value`
   - the `Deferrer` calls the `on_fulfilled` callback with the `value` as argument

As goes the saying: "Callback. If it's not solving all your problems, you simply
aren't using enough of it".

Here's an implementation for `Deferrer`:

```python
class Deferrer:
    function promise():
        return new Promise(self.resolver)

    function resolve(value):
        for on_fulfill in self._on_fulfilled:
            on_fulfill(value)

    function resolver(on_fulfilled):
        self._on_fulfilled.append(on_fulfilled)
```

And for `Promise`:

```python
class Promise:
    function constructor(resolver):
        self._resolver = resolver

    function then(on_fulfilled):
        self._resolver(on_fulfilled)

        return new Promise(resolver)
```

And finally here's a basic usage example:

```python
function hello_world(name):
    print 'Hello ' + name + '!'

function welcome_world(name):
    print 'Welcome ' + name + '!'

deferrer = new Deferrer()
promise = new deferrer.promise()
promise.then(hello_world).then(welcome_world)

deferrer.resolve('Igor') # prints `Hello Igor!` and `Welcome Igor!`
```

With this, we contain the complexity to two classes, the rest of the application
becomes easier to read: instead of nesting callbacks we can chain them.

`Promise` and `Deferrer` both look neat. But what's the link with our scheduled
`EventLoop`? Turns out the link is Filesystem.

## Filesystem U/O

When it comes to Filesystem, we're actually dealing with "U/O" (uh oh) rather
than I/O: they've been ranked as the slowest in the [latency comparison](https://gist.github.com/jboner/2841832#file-latency-txt),
but unlike sockets they are [blocking](http://blog.libtorrent.org/2012/10/asynchronous-disk-io/).

Thankfully we've got a solution for that: wrapping "blocking" filesystem operations
in a class that will simulate a "non-blocking" behavior:

1. ask for regular arguments (e.g. `filename`), and an additional `on_fulfilled` callback
2. execute the "blocking" operation in a thread pool, which acts as a `Deferrer` and returns a `Promise`
3. set the `Promise` callback to add `on_fulfilled` in the `EventLoop`, scheduled immediately

Here's an implementation example of such a wrapper:

```
class NonBlockingFilesystem:
    function constructor(event_loop, filesystem, thread_pool):
        self._event_loop = event_loop
        self._filesystem = filesystem
        self._thread_pool = thread_pool

    function open(file, on_opened):
        promise = self._thread_pool.map(self._filesystem.open, file)
        promise.then(lambda file_descriptor: self._on_file_opened(file_descriptor, on_opened))

    function _on_file_opened(file_descriptor, on_opened):
        self._event_loop.scheduler.append(1, on_opened, file_descriptor)

    function read(file_descriptor, on_read):
        promise = self._thread_pool.map(self._filesystem.read, file_descriptor)
        promise.then(lambda content: self._on_file_read(content, on_read))

    function _on_file_read(content, on_read):
        self._event_loop.scheduler.append(1, on_read, content)
```

By deferring actual filesystem operations to threads, our HTTP server can accept
more connections and handle more clients until the call is ready.The thread pool
is usually set up with 4 threads.

As goes the saying: "Threading. If it's not solving all your problems, you simply
aren't using enough of it... **NOT!**".

For once, limits are good. If we put too many threads in the pool, we’ll soon
reach another limit: the number of filesystem operations allowed by the kernel.
If we increase this limit, we’ll soon reach another limit: the number of filesystem
operations physically allowed by the hardware
([some people tried it, they ended up with burned disks](https://blog.wyrihaximus.net/2015/03/reactphp-filesystem/#a-word-of-caution)).

> **Note**: Our server and application are still single-threaded. The use of a
> `ThreadPool` is done in a decoupled way, isolating us from multi-threaded issues.

## Conclusion

By "non-blocking I/O", Node.js means that it's using an Event Loop to make use
of the network latency to handle multiple clients in parallel.

It's been built with [libuv](http://libuv.org/), a low-level C library which
embeds in its Event Loop many types of Schedulers and a Thread Pool: it allows
it to simulate "non-blocking" behavior by wrapping "blocking" calls
(e.g. Filesystem).

Instead of implementing our server in a "sequential" way, like Apache2 does, we
can instead implement it with "polling events" in mind: nginx is using this
"Event-Driven Architecture" and it allows it [to outperform Apache](https://www.nginx.com/blog/nginx-vs-apache-our-view/).

Systems built in this way often use Promises, as they help us perceive our
"asynchronous" code as "synchronous".

If you're interested to read more on the topic, here are some links:

* [PHP - build your own server](https://speakerdeck.com/igorw/build-your-own-webserver-with-php)
* [ReactPHP](https://speakerdeck.com/igorw/react-phpnw)
* [ReactPHP - components](https://blog.wyrihaximus.net/2015/01/reactphp-introduction/)
* [ReactPHP - reactive PHP events](https://medium.com/async-php/reactive-php-events-d0cd866e9285)
* [PHP - co-operative PHP multitasking](https://medium.com/async-php/co-operative-php-multitasking-ce4ef52858a0)
* [Node.js - When is the Thread Pool used?](http://stackoverflow.com/questions/22644328/when-is-the-thread-pool-used/22644735#22644735)
* [Node.js - Thread Pool usage](https://www.future-processing.pl/blog/on-problems-with-threads-in-node-js/)
* [C - the C10K problem](http://www.kegel.com/c10k.html)
* [C - Handle multiple socket connections with fd_set and select on Linux](http://www.binarytides.com/multiple-socket-connections-fdset-select-linux/)
* [C - Introduction to non-blocking I/O](http://www.kegel.com/dkftpbench/nonblocking.html)
* [C - libev documentation](http://pod.tst.eu/http://cvs.schmorp.de/libev/ev.pod)
* [C - libuv documentation](http://docs.libuv.org/en/v1.x/)
* [C - libuv online book](https://nikhilm.github.io/uvbook/introduction.html)

> **Note**: In the PHP landscape, there are many libraries that allow us to build
> Event Driven applications:
>
> * [ReactPHP](http://reactphp.org/)
> * [IcicleIO](http://icicle.io/)
> * [Amphp](http://amphp.org/)
>
> There's even a [PHP Async Interop Group](https://github.com/async-interop/)
> that started researching, to create PHP Standard Recommandation (PSR) for
> Event Loops, Promise, etc.
