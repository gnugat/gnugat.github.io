---
layout: post
title: "eXtreme Legacy 3: End to End Tests"
tags:
    - phpunit
    - extreme-legacy
---

> 🤘 The Beta Destroyer breaks free from the crypts of Manual Testing,
> forging unbreakable chains of End to End test scenarios,
> binding every component in the unholy covenant of automations! 🔥

In this series, we're dealing with BisouLand, an eXtreme Legacy application
(2005 LAMP spaghetti code base). So far, we have:

1. [🐋 got it to run in a local container](/2025/09/10/xl-1-dockerizing-2005-lamp-app.html)
2. [💨 written Smoke Tests](/2025/09/17/xl-2-smoke-tests.html)

This means we can run it locally (http://localhost:8080/),
and have some level of automated tests.

But currently the tests are failing!

So, we'll inspect the issue, identify it,
write End to End tests which will be today's third article focus,
and finally we'll fix the bug.

<img
    alt="The plan: we find the bug. We fix the bug. Now there are two bugs. Now there are three bugs"
    src="/images/xl-3-the-plan.jpg"
    width="100%" />

* [Identifying the issue](#identifying-the-issue)
* [Writing the test](#writing-the-test)
* [Test data cleanup](#test-data-cleanup)
* [Custom Assertion](#custom-assertion)
* [Fixing the bug](#fixing-the-bug)
* [Conclusion](#conclusion)

## Identifying the issue

Let's run the tests to see the failure messages:

```console
make test arg='--testdox --filter PlayerPages'
PHPUnit 12.3.2 by Sebastian Bergmann and contributors.

Runtime:       PHP 8.4.12
Configuration: /apps/qa/phpunit.xml.dist

FFFFFFFFFFFF............                                          24 / 24 (100%)

Time: 00:00.081, Memory: 18.00 MB

Player Pages (Bl\Qa\Tests\Smoke\PlayerPages)
 ✘ it loads account page (`/connected.html`) for logged in players
   ┐
   ├ Failed asserting that Page loads for logged in players
   │
   │ /apps/qa/tests/Smoke/Assertion/Assert.php:41
   │ /apps/qa/tests/Smoke/PlayerPagesTest.php:45
   ┴
[...]
FAILURES!
Tests: 24, Assertions: 24, Failures: 12.
```

The player cannot log in... Let's try manually,
first we need to sign-up a new player:

<img alt="BisouLand signup attempt screenshot" src="/images/xl-3-signup-attempt-screenshot.png" width="100%" />

It worked:

<img alt="BisouLand signup errot screenshot" src="/images/xl-3-signup-success-screenshot.png" width="100%" />

Now let's log in:

<img alt="BisouLand signup attempt screenshot" src="/images/xl-3-login-attempt-screenshot.png" width="100%" />

But it fails! The error says the username doesn't exist:

<img alt="BisouLand signup errot screenshot" src="/images/xl-3-login-failure-screenshot.png" width="100%" />

Inspecting the database shows that the player data wasn't inserted.

The Smoke Tests didn't catch directly the login error,
because it's an error printed inside the HTML,
and our tests only check for status code `200`.

So this highlights the limits of Smoke Tests
(though we have to recognise that they did indirectly catch the issue,
with players being unable to login).

The code handling signing up is located in `./apps/monolith/web/phpincludes/inscription.php`,
and hold on to your socks because it looks like this:

```php
<?php
if (false == $_SESSION['logged']) {
    $send = 0;
    $pseudo = '';
    $mdp = '';
    if (isset($_POST['inscription'])) {
        // Mesure de securite.
        $pseudo = htmlentities(addslashes($_POST['Ipseudo']));
        $mdp = htmlentities(addslashes($_POST['Imdp']));
        $mdp2 = htmlentities(addslashes($_POST['Imdp2']));
        // Prevoir empecher de prendre un pseudo deje existant
        // Si les variables contenant le pseudo, le mot de passe existent et contiennent quelque chose.
        if (isset($_POST['Ipseudo'], $_POST['Imdp'], $_POST['Imdp2']) && !empty($_POST['Ipseudo']) && !empty($_POST['Imdp']) && !empty($_POST['Imdp2'])) {
            if ($mdp == $mdp2) {
                // Si le pseudo est superieur e 3 caracteres et inferieur e 35 caracteres.
                $taille = strlen(trim($_POST['Ipseudo']));
                if ($taille >= 4 && $taille <= 15) {
                    /* //Mesure de securite.
                    $pseudo = htmlentities(addslashes($_POST['pseudo']));
                    $mdp = htmlentities(addslashes($_POST['mdp']));*/

                    // La requete qui compte le nombre de pseudos
                    $sql = mysql_query("SELECT COUNT(*) AS nb_pseudo FROM membres WHERE pseudo='".$pseudo."'");

                    // Verifie si le pseudo n'est pas deje pris.
                    if (0 == mysql_result($sql, 0, 'nb_pseudo') && 'BisouLand' != $pseudo) {
                        // Verifie que le pseudo est correct.
                        if (preg_match("!^\w+$!", $pseudo)) {
                            if (preg_match("!^\w+$!", $mdp)) {
                                // Si le mot de passe est superieur e 4 caracteres.
                                $taille = strlen(trim($_POST['Imdp']));
                                if ($taille >= 5 && $taille <= 15) {
                                    // On execute la requete qui enregistre un nouveau membre.

                                    // Hashage du mot de passe avec md5().
                                    $hmdp = md5($mdp);

                                    mysql_query("INSERT INTO membres (id, pseudo, mdp, confirmation, lastconnect) VALUES ('', '".$pseudo."', '".$hmdp."', '1', ".time().')');

                                    echo 'Ton inscription est confirmée ! Tu peux maintenant te connecter.<br />';
                                    $send = 1;
                                } else {
                                    echo 'Erreur : le mot de passe est soit trop court, soit trop long !';
                                }
                            } else {
                                echo 'Erreur : le mot de passe n\'est pas valide !';
                            }
                        } else {
                            echo 'Erreur : le pseudo n\'est pas valide !';
                        }
                    } else {
                        echo 'Erreur : pseudo deje pris !';
                    }
                } else {
                    echo 'Erreur : le pseudo est soit trop court, soit trop long !';
                }
            } else {
                echo 'Erreur : Tu n\'as pas rentre deux fois le meme mot de passe !';
            }
        } else {
            echo 'Erreur : Pense e remplir tous les champs !';
        }
    }
    if (0 == $send) {
        ?>
<form method="post" class="formul" action="inscription.html">
	<label>Pseudo :<br /><span class="petit">(Entre 4 et 15 caracteres)</span><br /><input type="text" name="Ipseudo" tabindex="10" size="15" maxlength="15" value="<?php echo stripslashes($pseudo); ?>"/></label><br />
	<label>Mot de passe : <br /><span class="petit">(Entre 5 et 15 caracteres)</span><br /><input type="password" name="Imdp" tabindex="20" size="15" maxlength="15" value=""/></label><br />
	<label>Reecris le mot de passe : <br /><input type="password" name="Imdp2" tabindex="30" size="15" maxlength="15" value=""/></label><br />
    <input type="submit" name="inscription" value="S'inscrire" />
</form>
<?php
    }
} else {
    echo 'Pfiou t\'es dja connected toi !!';
}
?>
```

Now, that's eXtreme Legacy!!!

Let's focus on the problematic line,
which is supposed to save the player's data in the database
(I've reformatted it a bit for readability):

```php
mysql_query(
    'INSERT INTO membres (id, pseudo, mdp, confirmation, timestamp, lastconnect, amour)'
    ." VALUES ('', '{$pseudo}', '{$hmdp}', '1', ".time().', '.time().", '300')"
);
```

There are many problems here (deprecated function, SQL injection vulnerability,
use of cryptologically broken md5 for password hashing etc),
but what jumps to my attention is the use of `''` for the ID value.

After some research it turns out this code worked fine in older MySQL versions,
because MySQL would silently convert the empty string to `0`,
and since the id field is an `AUTO_INCREMENT` integer,
MySQL would then treat that `0` as a signal to generate the next sequence value.

However MySQL 5.7 (which is the version we picked!), released in October 2015,
introduced a significant change: `STRICT_TRANS_TABLES` became enabled by default.
This means MySQL now rejects data type error like this one.

So to fix the issue we can change the MySQL version,
but the end goal is to upgrade the versions to the most recent, not to downgrade,
so let's instead just fix the code.

But first, we need to write a test: Test Driven Development, or no tests at all! 🤘

## Writing the test

There are two kinds of tests that I hate: Smoke Tests, and End to End Tests.

End to End tests usually are about navigating the application, which is slow,
and checking for the content of the response, which is brittle.

However in this scenario, there are no alternative to test the features:
there are no HTTP framework, or handler / controller / services classes used
to allow us to write Functional / Integration / System tests.

To test our sign-up, all we can do is:

* issue a POST request to simulate the form being submitted
* check in the database if the expected record has been persisted

So let's just do that:

```php
<?php

declare(strict_types=1);

namespace Bl\Qa\Tests\EndToEnd;

use Bl\Qa\Tests\EndToEnd\Assertion\Assert;
use Bl\Qa\Tests\Infrastructure\Scenario\SignUpNewPlayer;
use Bl\Qa\Tests\Infrastructure\TestKernelSingleton;
use PHPUnit\Framework\Attributes\CoversNothing;
use PHPUnit\Framework\Attributes\DataProvider;
use PHPUnit\Framework\Attributes\Large;
use PHPUnit\Framework\Attributes\TestDox;
use PHPUnit\Framework\TestCase;

#[CoversNothing]
#[Large]
final class SignUpTest extends TestCase
{
    public function test_it_allows_visitors_to_become_players(): void
    {
        $httpClient = TestKernelSingleton::get()->httpClient();

        $player = SignUpNewPlayer::run(
            'BisouTest',
            'password',
            'password',
        );

        Assert::signedUpCount($player->username, 1);
    }

    #[DataProvider('invalidCredentialsProvider')]
    #[TestDox('It prevents invalid credentials: $description')]
    public function test_it_prevents_invalid_credentials(string $username, string $password, string $description): void
    {
        SignUpNewPlayer::run(
            $username,
            $password,
            $password,
        );

        Assert::signedUpCount($username, 0);
    }

    /**
     * [string $username, string $password, string $description][].
     *
     * @return array<array{string, string, string}>
     */
    public static function invalidCredentialsProvider(): array
    {
        return [
            ['usr', 'password', 'username too short (< 4 characters)'],
            ['test_sign_up02__', 'password', 'username too long (> 15 characters)'],
            ['test_sign_up03!', 'password', 'username contains special characters (non alpha-numerical, not an underscore (`_`))'],
            ['test_sign_up05', 'pass', 'password too short (< 5 characters)'],
            ['test_sign_up06', 'passwordthatistoolong', 'password too long (> 15 characters)'],
            ['test_sign_up07', 'password!', 'password contains special characters (non alpha-numerical, not an underscore (`_`))'],
            ['BisouLand', 'password', 'system account, for notifications'],
        ];
    }

    #[TestDox('It prevents usernames that are already used')]
    public function test_it_prevents_usernames_that_are_already_used(): void
    {
        $httpClient = TestKernelSingleton::get()->httpClient();

        $username = 'BisouTest_';
        $password = 'password';
        $passwordConfirmation = $password;

        // First registration should succeed
        SignUpNewPlayer::run(
            $username,
            $password,
            $passwordConfirmation,
        );
        // Second registration should fail
        SignUpNewPlayer::run(
            $username,
            $password,
            $passwordConfirmation,
        );

        Assert::signedUpCount($username, 1);
    }

    public function test_it_prevents_passwords_that_do_not_match_confirmation(): void
    {
        $httpClient = TestKernelSingleton::get()->httpClient();

        $username = 'BisouTest';
        $password = 'password';
        $passwordConfirmation = 'different';

        SignUpNewPlayer::run(
            $username,
            $password,
            $passwordConfirmation
        );

        Assert::signedUpCount($username, 0);
    }
}
```

If I've read the long and nested if statements correctly,
this should cover all the different sign-up scenarios,
including username and password checking.

For now let's just run the "happy scenario" test to make sure it fails:

```console
make test arg='--testdox --filter test_it_allows_visitors_to_become_players'
PHPUnit 12.3.2 by Sebastian Bergmann and contributors.

Runtime:       PHP 8.4.12
Configuration: /apps/qa/phpunit.xml.dist

F                                                                   1 / 1 (100%)

Time: 00:00.032, Memory: 18.00 MB

Sign Up (Bl\Qa\Tests\EndToEnd\SignUp)
 ✘ It allows visitors to become players
   ┐
   ├ Failed asserting that Signed Up Count 0 is 1
   │
   │ /apps/qa/tests/EndToEnd/Assertion/Assert.php:114
   │ /apps/qa/tests/EndToEnd/SignUpTest.php:30
   ┴

FAILURES!
Tests: 1, Assertions: 1, Failures: 1.
```

Brilliant! Before we fix it, I'll dive a bit more in the test details.

## Test data cleanup

I was surprised to find out that the username `BisouLand` was forbidden,
turns out it is used to send system notifications
(though I note that the checks are case sensitive only).

This is actually what inspired me to use `BisouTest` as a special test username,
if you remember correctly in the `SignUpNewPlayer` scenario,
which we've reused from the Smoke Tests as we would have done the exact same logic,
we have the following:

```php
        if ('BisouTest' === $username) {
            $username = substr('BisouTest_'.uniqid(), 0, 15);
        }
```

This makes sure that there will be no username duplicates.

One thing I didn't mention in my previous article was that I've setup a way
to cleanup the test data with the `DeleteAllTestPlayers` scenario:

```php
<?php

declare(strict_types=1);

namespace Bl\Qa\Tests\Infrastructure\Scenario;

use Bl\Qa\Tests\Infrastructure\TestKernelSingleton;

final readonly class DeleteAllTestPlayers
{
    public static function run(): void
    {
        $pdo = TestKernelSingleton::get()->pdo();

        $pdo->query("DELETE FROM membres WHERE pseudo LIKE 'BisouTest%'");
    }
}
```

This is called by a PHPUnit subscriber for the `TestRunner\Finished` event:

```php
<?php

declare(strict_types=1);

namespace Bl\Qa\Tests\Infrastructure\Subscriber;

use Bl\Qa\Tests\Infrastructure\Scenario\DeleteAllTestPlayers;
use PHPUnit\Event\TestRunner\Finished;
use PHPUnit\Event\TestRunner\FinishedSubscriber;

final readonly class TestCleanupSubscriber implements FinishedSubscriber
{
    public function notify(Finished $event): void
    {
        DeleteAllTestPlayers::run();
    }
}
```

This will be called once the testsuite is finished executing,
but only if we register the subscriber in a PHPUnit Extension:

```php
<?php

declare(strict_types=1);

namespace Bl\Qa\Tests\Infrastructure\Subscriber;

use PHPUnit\Runner\Extension\Extension;
use PHPUnit\Runner\Extension\Facade;
use PHPUnit\Runner\Extension\ParameterCollection;
use PHPUnit\TextUI\Configuration\Configuration;

final readonly class TestCleanupExtension implements Extension
{
    public function bootstrap(Configuration $configuration, Facade $facade, ParameterCollection $parameters): void
    {
        $facade->registerSubscriber(new TestCleanupSubscriber());
    }
}
```

The extension also has to be registered in the `phpunit.xml` config:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!-- https://phpunit.readthedocs.io/en/latest/configuration.html -->
<phpunit xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
         xsi:noNamespaceSchemaLocation="vendor/phpunit/phpunit/phpunit.xsd"
         bootstrap="vendor/autoload.php"
         cacheDirectory=".phpunit.cache"
         executionOrder="depends,defects"
         shortenArraysForExportThreshold="10"
         requireCoverageMetadata="true"
         beStrictAboutCoverageMetadata="true"
         beStrictAboutOutputDuringTests="true"
         displayDetailsOnPhpunitDeprecations="true"
         colors="true"
         failOnPhpunitDeprecation="true"
         failOnRisky="true"
         failOnWarning="true">
    <php>
        <ini name="display_errors" value="1" />
        <ini name="error_reporting" value="-1" />
        <env name="APP_ENV" value="test" force="true" />
        <env name="SHELL_VERBOSITY" value="-1" />
    </php>
    <testsuites>
        <testsuite name="smoke">
            <directory>tests/Smoke</directory>
        </testsuite>
        <testsuite name="end-to-end">
            <directory>tests/EndToEnd</directory>
        </testsuite>
    </testsuites>

    <extensions>
        <bootstrap class="Bl\Qa\Tests\Infrastructure\Subscriber\TestCleanupExtension"/>
    </extensions>

    <source ignoreIndirectDeprecations="true" restrictNotices="true" restrictWarnings="true">
        <include>
            <directory>../monolith/web</directory>
        </include>
    </source>
</phpunit>
```

## Custom Assertion

I've created a `signedUpCount` custom assertion,
which will count in the database the number of records persisted for a given
username:

```php
<?php

declare(strict_types=1);

namespace Bl\Qa\Tests\EndToEnd\Assertion;

use Bl\Qa\Tests\Infrastructure\TestKernelSingleton;
use PHPUnit\Framework\Assert as PHPUnitAssert;

final readonly class Assert
{
    public static function signedUpCount(string $username, int $expectedCount): void
    {
        $pdo = TestKernelSingleton::get()->pdo();

        $stmt = $pdo->prepare('SELECT COUNT(*) FROM membres WHERE pseudo = :username');
        $stmt->execute([
            'username' => $username,
        ]);
        $actualCount = (int) $stmt->fetchColumn();

        PHPUnitAssert::assertSame(
            $expectedCount,
            $actualCount,
            "Failed asserting that Signed Up Count {$actualCount} is {$expectedCount}",
        );
    }
}
```

I think there's an argument to have had made two assertions
(eg `signedUpSuccessful` count = 1, and `signedUpFailed` count = 0),
but for now I'm happy with this.

## Fixing the bug

We're going to fix that bug by removing the ID field from the query:

```php
mysql_query(
    'INSERT INTO membres (pseudo, mdp, confirmation, timestamp, lastconnect, amour)'
    ." VALUES ('{$pseudo}', '{$hmdp}', '1', ".time().', '.time().", '300')"
);
```

Let's see if the bug is fixed by running the one test:

```console
make test arg='--testdox --filter test_it_allows_visitors_to_become_players'
PHPUnit 12.3.2 by Sebastian Bergmann and contributors.

Runtime:       PHP 8.4.12
Configuration: /apps/qa/phpunit.xml.dist

.                                                                   1 / 1 (100%)

Time: 00:00.018, Memory: 18.00 MB

Sign Up (Bl\Qa\Tests\EndToEnd\SignUp)
 ✔ It allows visitors to become players

OK (1 test, 1 assertion)
```

So far so good, let's confirm by running all the tests:

```console
make test
PHPUnit 12.3.2 by Sebastian Bergmann and contributors.

Runtime:       PHP 8.4.12
Configuration: /apps/qa/phpunit.xml.dist

.................................................                 49 / 49 (100%)

Time: 00:00.162, Memory: 18.00 MB

OK (49 tests, 49 assertions)
```

Excellent! All fixed!

## Conclusion

I believe there will be many more instances of this,
and given the success of this fix we can assume it's safe to apply to all instances.

But I know these `mysql_query` calls will be removed very soon:

* they are deprecated
* the query used is vulnerable to SQL Injection

The End to End tests we've written also allow us to refactor the code,
instead of a nested list we can for example make use of early returns.

But if I have to refactor that code, I want to do it right,
by first writing unit tests which will make a design model emerge,
and by creating an API so we can also have integration tests.

Once we have these, both the Smoke Tests and End to End tests can be removed.

So I'm going to leave this as is for now.

> ⁉️ _What do you mean, "the code is ugly"??_
