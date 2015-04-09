---
layout: post
title: Symfony / Web Services - part 3.3: Consuming, remote calls
tags:
    - Symfony
    - phpspec
    - Symfony / Web Services series
---

This is the seventh article of the series on managing Web Services in a
[Symfony](https://symfony.com) environment. Have a look at the six first ones:

* {{ link('posts/2015-01-14-sf-ws-part-1-introduction.md', '1. Introduction') }}
* {{ link('posts/2015-01-21-sf-ws-part-2-1-creation-bootstrap.md', '2.1 Creation bootstrap') }}
* {{ link('posts/2015-01-28-sf-ws-part-2-2-creation-pragmatic.md', '2.2 Creation, the pragmatic way') }}
* {{ link('posts/2015-03-04-sf-ws-part-2-3-creation-refactoring.md', '2.3 Creation, refactoring') }}
* {{ link('posts/2015-03-11-sf-ws-part-3-1-consuming-request-handler.md', '3.1 Consuming, RequestHandler') }}
* {{ link('posts/2015-03-18-sf-ws-part-3-2-consuming-guzzle.md', '3.2 Consuming, Guzzle') }}

You can check the code in the [following repository](https://github.com/gnugat-examples/sf-cs).

In the previous article, we've created a Guzzle RequestHandler: we are now able
to make remote calls using a third party library, but without the cost of coupling
ourselves to it. If Guzzle 6 is released we'll have to change only one class, instead
of everywhere in our application.

In this article, we'll create the actual remote calls.

## Credential configuration

The web service we want to call requires us to authenticate. Those credentials
shouldn't be hardcoded, we'll create new parameters for them (same goes for the URL):

```
# File: app/config/parameters.yml.dist
    ws_url: http://example.com
    ws_username: username
    ws_password: ~
```

We can then set those values in the actual parameter file:

```
# File: app/config/parameters.yml
    ws_url: "http://ws.local/app_dev.php"
    ws_username: spanish_inquisition
    ws_password: "NobodyExpectsIt!"
```

Note that because our password contains a character which is reserved in YAML (`!`),
we need to put the value between double quotes (same goes for `%` and `@`).

Let's commit this:

    git add -A
    git commit -m 'Added credentials configuration'

## Profile Gateway

We can create a [Gateway](http://martinfowler.com/eaaCatalog/gateway.html)
specialized in calling the profile web service:

    ./bin/phpspec describe 'AppBundle\Profile\ProfileGateway'

Usually we categorize our Symfony applications by Pattern: we'd create a `Gateway`
directory with all the Gateway service. However this can become quite cubersome
when the application grows, services are usually linked to a model meaning that
we'd have to jump from the `Model` (or `Entity`) directory to the `Gateway` one,
then go to the `Factory` directory, etc...

Here we've chosen an alternative: group services by model. All `Profile` services
can be found in the same directory.

Let's write the Gateway's specification:

```php
<?php
// File: spec/AppBundle/Profile/ProfileGatewaySpec.php

namespace spec\AppBundle\Profile;

use AppBundle\RequestHandler\RequestHandler;
use AppBundle\RequestHandler\Response;
use PhpSpec\ObjectBehavior;
use Prophecy\Argument;

class ProfileGatewaySpec extends ObjectBehavior
{
    const URL = 'http://example.com';
    const USERNAME = 'spanish inquisition';
    const PASSWORD = 'nobody expects it';

    const ID = 42;
    const NAME = 'Arthur';

    function let(RequestHandler $requestHandler)
    {
        $this->beConstructedWith($requestHandler, self::URL, self::USERNAME, self::PASSWORD);
    }

    function it_creates_profiles(RequestHandler $requestHandler, Response $response)
    {
        $profile = array(
            'id' => self::ID,
            'name' => self::NAME,
        );

        $request = Argument::type('AppBundle\RequestHandler\Request');
        $requestHandler->handle($request)->willReturn($response);
        $response->getBody()->willReturn($profile);

        $this->create(self::NAME)->shouldBe($profile);
    }
}
```

We can now generate the code's skeleton:

    ./bin/phpspec run

It constructs a `Request` object, gives it to `RequestHandler` and then returns the
`Response`'s body:

```php
<?php
// File: src/AppBundle/Profile/ProfileGateway.php

namespace AppBundle\Profile;

use AppBundle\RequestHandler\Request;
use AppBundle\RequestHandler\RequestHandler;

class ProfileGateway
{
    private $requestHandler;
    private $url;
    private $username;
    private $password;

    public function __construct(RequestHandler $requestHandler, $url, $username, $password)
    {
        $this->requestHandler = $requestHandler;
        $this->username = $username;
        $this->password = $password;
    }

    public function create($name)
    {
        $request = new Request('POST', $this->url.'/api/v1/profiles');
        $request->setHeader('Authorization', 'Basic '.base64_encode($this->username.':'.$this->password));
        $request->setHeader('Content-Type', 'application/json');
        $request->setBody(json_encode(array('name' => $name)));

        $response = $this->requestHandler->handle($request);

        return $response->getBody();
    }
}
```

> **Note**: Managing URLs can become quite tricky when the number of routes grows.
> Sometimes we'll want HTTPS, sometimes HTTP. Sometimes we'll want the first version
> of the API, sometimes the pre production one. And what should we do when we'll
> need query parameters?
>
> Usually I don't bother with those until the need is actually there, then I create
> a `UrlGenerator` which works a bit like Symfony's one and relies on a configuration array.

Let's check our tests:

    ./bin/phpspec run

All green!

    git add -A
    git commit -m 'Created ProfileGateway'

## Create Profile Command

Our application happens to be a Command Line Interface (CLI). We want to write a
command to create profiles, and as usual we'll begin with a test:

```php
<?php
// File: tests/Command/CreateProfileCommandTest.php

namespace AppBundle\Tests\Command;

use PHPUnit_Framework_TestCase;
use Symfony\Bundle\FrameworkBundle\Console\Application;
use Symfony\Component\Console\Output\NullOutput;
use Symfony\Component\Console\Input\ArrayInput;

class CreateProfileCommandTest extends PHPUnit_Framework_TestCase
{
    private $app;
    private $output;

    protected function setUp()
    {
        $kernel = new \AppKernel('test', false);
        $this->app = new Application($kernel);
        $this->app->setAutoExit(false);
        $this->output = new NullOutput();
    }

    public function testItRunsSuccessfully()
    {
        $input = new ArrayInput(array(
            'commandName' => 'app:profile:create',
            'name' => 'Igor',
        ));

        $exitCode = $this->app->run($input, $this->output);

        $this->assertSame(0, $exitCode);
    }
}
```

Let's make this test pass:

```php
<?php
// File: src/AppBundle/Command/CreateProfileCommand.php

namespace AppBundle\Command;

use Symfony\Bundle\FrameworkBundle\Command\ContainerAwareCommand;
use Symfony\Component\Console\Input\InputArgument;
use Symfony\Component\Console\Input\InputOption;
use Symfony\Component\Console\Input\InputInterface;
use Symfony\Component\Console\Output\OutputInterface;

class CreateProfileCommand extends ContainerAwareCommand
{
    protected function configure()
    {
        $this->setName('app:profile:create');
        $this->setDescription('Create a new profile');

        $this->addArgument('name', InputArgument::REQUIRED);
    }

    protected function execute(InputInterface $input, OutputInterface $output)
    {
        $profileGateway = $this->getContainer()->get('app.profile_gateway');

        $profile = $profileGateway->create($input->getArgument('name'));

        $output->writeln(sprintf('Profile #%s "%s" created', $profile['id'], $profile['name']));
    }
}
```

We'll need to define `ProfileGateway` as a service:

```
# File: app/config/services.yml
imports:
    - { resource: services/request_handler.yml }

services:
    app.profile_gateway:
        class: AppBundle\Profile\ProfileGateway
        arguments:
            - "@app.request_handler"
            - "%ws_url%"
            - "%ws_username%"
            - "%ws_password%"
```

By having a look `ProfileGateway` we can spot a mistake, the initialization or URL
is missing from the constructor:

```php
<?php
// File: src/AppBundle/Profile/ProfileGateway.php

    public function __construct(RequestHandler $requestHandler, $url, $username, $password)
    {
        $this->requestHandler = $requestHandler;
        $this->username = $username;
        $this->password = $password;
        $this->url = $url;
    }
```

Another mistake lies in `JsonResponseListener`, each Guzzle header is an array:

```php
<?php
// File: src/AppBundle/RequestHandler/Listener/JsonResponseListener.php

        $contentType = $response->getHeader('Content-Type');
        if (false === strpos($contentType[0], 'application/json')) {
            return;
        }
```

With these fixes, the test should pass:

    phpunit -c app

> **Note**: if we get a `You have requested a non-existent service "app.profile_gateway"`
> error, we might need to clear the cache for test environment: `php app/console cache:clear --env=test`.

> **Note**: if we get a Guzzle exception, we need to check that the previous application installed
> ("ws.local"), and that its database is created:
>
> ```
> cd ../ws
> php app/console doctrine:database:create
> php app/console doctrine:schema:create
> cd ../cs
> ```

We can now save our work:

    git add -A
    git commit -m 'Created CreateProfileCommand'

## Conclusion

We have now an application that consumes a web service. We have decoupled it from
third party libraries using RequestHandler and isolated the endpoint logic in a
Gateway class.

There's a lot to say about the test we wrote: it makes a network call which is slow, unreliable
and it isn't immutable. If we try to run again our test, it will fail!
To fix this we have many possibilities:

* mock the endpoints, it will make the tests faster and immutable but if the endpoints change our tests will still pass
* cleanup the created profile by aking another network call, it will make the test even slower

At this point it depends on how confident we are in the web services and what we want to test.

We should also write more test on edge cases: what happens with the wrong credentials?
What happens if the endpoints cannot be reached (request timeout, connection timeout, etc)?
What happens when we try to create a profile which already exists?

As it happens, this is also the conclusion of this series on managing Web Services in a
Symfony environment. There's a lot more to say for example about caching remote resources
in a local database, about self discovering APIs and about micro services, but I feel
those should each have their own series of article :) .
