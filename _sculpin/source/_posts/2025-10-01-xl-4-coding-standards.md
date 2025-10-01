---
layout: post
title: "eXtreme Legacy 4: Coding Standards"
tags:
    - php-cs-fixer
    - extreme-legacy
---

> 🤘 The Coding Standards Inquisitor rises from the sulphurous pits of Legacy Chaos,
> brandishing the iron scriptures of Style Guides,
> purging the realm of inconsistent formatting with flames of automated linting! 🔥

In this series, we're dealing with BisouLand, an eXtreme Legacy application
(2005 LAMP spaghetti code base). So far, we have:

1. [🐋 got it to run in a local container](/2025/09/10/xl-1-dockerizing-2005-lamp-app.html)
2. [💨 written Smoke Tests](/2025/09/17/xl-2-smoke-tests.html)
3. [🎯 written End to End Tests](/2025/09/24/xl-3-end-to-end-tests.html)

This means we can run it locally (http://localhost:8080/),
and have some level of automated tests.

But the code is ugly!

So we're going to establish beautiful Coding Standards,
which will be today's fourth article focus,
and enforce them automatically using PHP CS Fixer.

* [Level 0: setup](#level-0%3A-setup)
* [Level 1: PSR-1](#level-1%3A-psr-1)
* [Level 2: PSR-2](#level-2%3A-psr-2)
* [Level 3: PSR-12](#level-3%3A-psr-12)
* [Level 4: PER-CS 2.0](#level-4%3A-per-cs-2.0)
* [Level 5: Symfony](#level-5%3A-symfony)
* [Conclusion](#conclusion)

## Level 0: setup

We will not start with the highest quality standard,
as this would make it too difficult to track the changes.

Instead we'll:

* start with an empty configuration, run the tool, check the changes
* then add the smallest set of CS rule we can think of, run again and check
* iterate by adding more and more rules

Ideally, teams should discuss and agree on a select list of rules to follow,
but [the list of possible rules is too overwhelming](https://cs.symfony.com/doc/rules/index.html).

So instead of picking rules one by one,
we can rely on [rule sets](https://cs.symfony.com/doc/ruleSets/index.html).

My humble opinion is that the [Symfony CS](https://cs.symfony.com/doc/ruleSets/Symfony.html)
are the best, but that'd be too many rules to add in one go.

If we check the Symfony rule set doc, at the top we can see `@PER-CS3x0`.

Rules that start with `@` are actually rulesets,
so Symfony depends on other smaller rulesets,
and those smaller rulesets also depend on other smaller rulesets.

It's a tedious task,
but we can navigate the documentation website,
construct the tree of rule sets used,
and then start with the smaller one:

1. [PSR-1: Basic Coding Standard](https://www.php-fig.org/psr/psr-1/)
2. [PSR-2: Coding Style Guide - deprecated](https://www.php-fig.org/psr/psr-2/)
3. [PSR-12: Extended Coding Style](https://www.php-fig.org/psr/psr-12/)
4. [PER-CS 2.0: Coding Style](https://www.php-fig.org/per/coding-style/)
   (turns out there's a PER-CS 3.0 since July 2025!)

For each rule set, we then check if anything is breaking,
and if so we exclude the specific rule.

Let's start with an empty configuration in `apps/qa/.php-cs-fixer.php.dist`:

```php
<?php

use PhpCsFixer\Runner\Parallel\ParallelConfigFactory;

$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__.'/../monolith/web')
    ->exclude('ban')
    ->exclude('images')
    ->exclude('includes')
    ->exclude('polices')
    ->exclude('smileys')
;

return (new PhpCsFixer\Config())
    ->setRules([
    ])
    ->setRiskyAllowed(true)
    ->setParallelConfig(ParallelConfigFactory::detect())
    ->setUsingCache(true)
    ->setFinder($finder)
;
```

Running it will not report any problems:

```console
> make cs-check // equivalent to: ./vendor/bin/php-cs-fixer check --verbose
PHP CS Fixer 3.85.1 Alexander by Fabien Potencier, Dariusz Ruminski and contributors.
PHP runtime: 8.4.12
Running analysis on 15 cores with 10 files per process.
Parallel runner is an experimental feature and may be unstable, use it at your own risk. Feedback highly appreciated!
Loaded config default from "/apps/qa/.php-cs-fixer.dist.php".
Using cache file ".php-cs-fixer.cache".
 43/43 [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓] 100%


Found 0 of 43 files that can be fixed in 0.105 seconds, 18.00 MB memory used
```

## Level 1: PSR-1

Let's add the [PSR-1 ruleset](https://cs.symfony.com/doc/ruleSets/PSR1.html):

```php
<?php

use PhpCsFixer\Runner\Parallel\ParallelConfigFactory;

$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__.'/../monolith/web')
    ->exclude('ban')
    ->exclude('images')
    ->exclude('includes')
    ->exclude('polices')
    ->exclude('smileys')
;

return (new PhpCsFixer\Config())
    ->setRules([
        '@PSR1' => true,
    ])
    ->setRiskyAllowed(true)
    ->setParallelConfig(ParallelConfigFactory::detect())
    ->setUsingCache(true)
    ->setFinder($finder)
;
```

This will make sure we use:

* [full opening tag](https://cs.symfony.com/doc/rules/php_tag/full_opening_tag.html)
  (not `<?` but `<?php`)
* [encoding](https://cs.symfony.com/doc/rules/basic/encoding.html)
  (not BOM, UTF-8)

Let's run the checks:

```console
> make cs-check
PHP CS Fixer 3.85.1 Alexander by Fabien Potencier, Dariusz Ruminski and contributors.
PHP runtime: 8.4.12
Running analysis on 15 cores with 10 files per process.
Parallel runner is an experimental feature and may be unstable, use it at your own risk. Feedback highly appreciated!
Loaded config default from "/apps/qa/.php-cs-fixer.dist.php".
Using cache file ".php-cs-fixer.cache".
 43/43 [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓] 100%

   1) ../monolith/web/news/chemin.php (full_opening_tag)

Found 1 of 43 files that can be fixed in 0.103 seconds, 18.00 MB memory used
```

There's one file that uses `<?`, to automatically fix it we run:

```console
> make cs-fix // equivalent to: ./vendor/bin/php-cs-fixer fix --verbose
PHP CS Fixer 3.85.1 Alexander by Fabien Potencier, Dariusz Ruminski and contributors.
PHP runtime: 8.4.12
Running analysis on 15 cores with 10 files per process.
Parallel runner is an experimental feature and may be unstable, use it at your own risk. Feedback highly appreciated!
Loaded config default from "/apps/qa/.php-cs-fixer.dist.php".
Using cache file ".php-cs-fixer.cache".
 43/43 [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓] 100%

   1) ../monolith/web/news/chemin.php (full_opening_tag)

Fixed 1 of 43 files in 0.107 seconds, 18.00 MB memory used
```

And that's PSR-1 done and dusted.

## Level 2: PSR-2

Time for the [PSR-2 ruleset](https://cs.symfony.com/doc/ruleSets/PSR2.html):

```php
<?php

use PhpCsFixer\Runner\Parallel\ParallelConfigFactory;

$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__.'/../monolith/web')
    ->exclude('ban')
    ->exclude('images')
    ->exclude('includes')
    ->exclude('polices')
    ->exclude('smileys')
;

return (new PhpCsFixer\Config())
    ->setRules([
        '@PSR2' => true,
    ])
    ->setRiskyAllowed(true)
    ->setParallelConfig(ParallelConfigFactory::detect())
    ->setUsingCache(true)
    ->setFinder($finder)
;
```

It adds about 30 new rules,
mainly regarding brace placement and indentation formatting.

Let's run a check:

```console
> make cs-check
Loaded config default from "/apps/qa/.php-cs-fixer.dist.php".
Using cache file ".php-cs-fixer.cache".
 43/43 [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓] 100%

   1) ../monolith/web/calcul.php (no_closing_tag, no_trailing_whitespace, single_blank_line_at_eof)
   2) ../monolith/web/redirect.php (indentation_type, single_space_around_construct, method_argument_space, no_closing_tag, braces_position, statement_indentation, single_blank_line_at_eof)
   3) ../monolith/web/checkConnect.php (indentation_type, elseif, single_space_around_construct, no_closing_tag, no_trailing_whitespace, braces_position, statement_indentation,single_blank_line_at_eof)
   4) ../monolith/web/phpincludes/fctIndex.php (indentation_type, single_space_around_construct, method_argument_space, spaces_inside_parentheses, control_structure_braces, no_closing_tag, no_trailing_whitespace, braces_position, statement_indentation, single_blank_line_at_eof)
   5) ../monolith/web/phpincludes/topten.php (indentation_type, single_space_around_construct, no_trailing_whitespace, braces_position, statement_indentation)
   6) ../monolith/web/phpincludes/pages.php (indentation_type, no_closing_tag, statement_indentation, single_blank_line_at_eof)
   7) ../monolith/web/config/parameters.php (single_blank_line_at_eof)
   8) ../monolith/web/deconnexion.php (indentation_type, single_space_around_construct, no_closing_tag, braces_position, single_blank_line_at_eof)
   9) ../monolith/web/news/rediger_news.php (indentation_type, single_space_around_construct, no_trailing_whitespace, braces_position, statement_indentation)
  10) ../monolith/web/news/chemin.php (no_closing_tag, single_blank_line_at_eof)
  11) ../monolith/web/news/liste_news.php (indentation_type, single_space_around_construct, lowercase_keywords, braces_position, statement_indentation)
  12) ../monolith/web/phpincludes/evo.php (indentation_type, single_space_around_construct, method_argument_space, no_closing_tag, no_trailing_whitespace, braces_position, statement_indentation, single_blank_line_at_eof)
  13) ../monolith/web/phpincludes/stats.php (indentation_type, method_argument_space, statement_indentation)
  14) ../monolith/web/phpincludes/infos.php (indentation_type, single_space_around_construct, braces_position, statement_indentation)
  15) ../monolith/web/phpincludes/yeux.php (indentation_type, single_space_around_construct, method_argument_space, no_trailing_whitespace, braces_position, statement_indentation)
  16) ../monolith/web/phpincludes/inscription.php (indentation_type, single_space_around_construct, method_argument_space, spaces_inside_parentheses, braces_position, statement_indentation)
  17) ../monolith/web/phpincludes/faq.php (indentation_type, braces_position, statement_indentation)
  18) ../monolith/web/phpincludes/construction.php (indentation_type, single_space_around_construct, method_argument_space, no_spaces_after_function_name, braces_position, statement_indentation)
  19) ../monolith/web/phpincludes/recherche.php (indentation_type, single_space_around_construct, no_trailing_whitespace, braces_position)
  20) ../monolith/web/phpincludes/bd.php (braces_position, statement_indentation)
  21) ../monolith/web/phpincludes/accueil.php (indentation_type, no_trailing_whitespace, braces_position, statement_indentation)
  22) ../monolith/web/phpincludes/lire.php (indentation_type, single_space_around_construct, braces_position, statement_indentation)
  23) ../monolith/web/phpincludes/membres.php (indentation_type, single_space_around_construct, method_argument_space, no_trailing_whitespace, braces_position, statement_indentation)
  24) ../monolith/web/phpincludes/nuage.php (indentation_type, single_space_around_construct, method_argument_space, no_trailing_whitespace, braces_position, statement_indentation)
  25) ../monolith/web/phpincludes/attaque.php (indentation_type, single_space_around_construct, method_argument_space, no_closing_tag, no_trailing_whitespace, no_trailing_whitespace_in_comment, no_multiple_statements_per_line, braces_position, statement_indentation, single_blank_line_at_eof)
  26) ../monolith/web/phpincludes/confirmation.php (indentation_type, single_space_around_construct, method_argument_space, spaces_inside_parentheses, no_closing_tag, no_trailing_whitespace, braces_position, statement_indentation, single_blank_line_at_eof)
  27) ../monolith/web/phpincludes/changepass.php (indentation_type, single_space_around_construct, method_argument_space, no_spaces_after_function_name, spaces_inside_parenthes, no_trailing_whitespace, braces_position, statement_indentation)
  28) ../monolith/web/phpincludes/techno.php (indentation_type, single_space_around_construct, method_argument_space, no_spaces_after_function_name, braces_position, statement_indentation)
  29) ../monolith/web/phpincludes/newpass.php (indentation_type, single_space_around_construct, method_argument_space, no_spaces_after_function_name, spaces_inside_parentheses,no_trailing_whitespace, braces_position, statement_indentation)
  30) ../monolith/web/makeBan.php (indentation_type, single_space_around_construct, method_argument_space, no_spaces_after_function_name, spaces_inside_parentheses, no_closing_tag, braces_position, statement_indentation, single_blank_line_at_eof)
  31) ../monolith/web/index.php (indentation_type, single_space_around_construct, method_argument_space, control_structure_braces, no_trailing_whitespace, no_trailing_whitespace_in_comment, braces_position, statement_indentation)
  32) ../monolith/web/phpincludes/livreor.php (indentation_type, single_space_around_construct, no_trailing_whitespace, braces_position, statement_indentation)
  33) ../monolith/web/phpincludes/connexion.php (indentation_type, single_space_around_construct, braces_position, statement_indentation)
  34) ../monolith/web/phpincludes/boite.php (indentation_type, single_space_around_construct, method_argument_space, control_structure_braces, lowercase_keywords, no_trailing_whitespace, braces_position, statement_indentation)
  35) ../monolith/web/phpincludes/connected.php (indentation_type, single_space_around_construct, braces_position, statement_indentation)
  36) ../monolith/web/phpincludes/envoi.php (indentation_type, single_space_around_construct, method_argument_space, braces_position, statement_indentation)
  37) ../monolith/web/phpincludes/action.php (indentation_type, single_space_around_construct, method_argument_space, braces_position, statement_indentation)

Found 37 of 43 files that can be fixed in 0.207 seconds, 18.00 MB memory used

Files that were not fixed due to errors reported during linting after fixing:
   1) /apps/qa/../monolith/web/phpincludes/cerveau.php
   2) /apps/qa/../monolith/web/phpincludes/bisous.php
```

We have lots of changes,
but what I'd like to focus more on is the two errors at the end.

To find out what specific rules are concerned,
we can replaced `PSR2` with [all the individual rules it includes](https://cs.symfony.com/doc/ruleSets/PSR2.html):

```php
<?php

use PhpCsFixer\Runner\Parallel\ParallelConfigFactory;

$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__.'/../monolith/web')
    ->exclude('ban')
    ->exclude('images')
    ->exclude('includes')
    ->exclude('polices')
    ->exclude('smileys')
;

return (new PhpCsFixer\Config())
    ->setRules([
        // '@PSR2' => true,
        '@PSR1' => true,

        'blank_line_after_namespace' => true,
        'braces_position' => true,
        'class_definition' => true,
        'constant_case' => true,
        'control_structure_braces' => true,
        'control_structure_continuation_position' => true,
        'elseif' => true,
        'function_declaration' => ['closure_fn_spacing' => 'one'],
        'indentation_type' => true,
        'line_ending' => true,
        'lowercase_keywords' => true,
        'method_argument_space' => ['after_heredoc' => false, 'attribute_placement' => 'ignore', 'on_multiline' => 'ensure_fully_multiline'],
        'modifier_keywords' ['elements' => ['method', 'property']],
        'no_break_comment' => true,
        'no_closing_tag' => true,
        'no_multiple_statements_per_line' => true,
        'no_space_around_double_colon' => true,
        'no_spaces_after_function_name' => true,
        'no_trailing_whitespace' => true,
        'no_trailing_whitespace_in_comment' => true,
        'single_blank_line_at_eof' => true,
        'single_class_element_per_statement' => ['elements' => ['property']],
        'single_import_per_statement' => true,
        'single_line_after_imports' => true,
        'single_space_around_construct' => ['constructs_followed_by_a_single_space' => ['abstract', 'as', 'case', 'catch', 'class', 'do', 'else', 'elseif', 'final', 'for', 'foreach', 'function', 'if', 'interface', 'namespace', 'private', 'protected', 'public', 'static', 'switch', 'trait', 'try', 'use_lambda', 'while'], 'constructs_preceded_by_a_single_space' => ['as', 'else', 'elseif', 'use_lambda']],
        'spaces_inside_parentheses' => true,
        'statement_indentation' => true,
        'switch_case_semicolon_to_colon' => true,
        'switch_case_space' => true,
    ])
    ->setRiskyAllowed(true)
    ->setParallelConfig(ParallelConfigFactory::detect())
    ->setUsingCache(true)
    ->setFinder($finder)
;
```

Then we eliminate one rule, run the check,
and see if the error is still there, then eliminate the next rule, etc.

Doing so, I've identified the following rule as being the offender:

* [statement_indentation](https://cs.symfony.com/doc/rules/whitespace/statement_indentation.html)

Looking at `apps/monolith/web/phpincludes/cerveau.php`,
we can see a mix of HTML and PHP (the following is a condensed example):

```php
  <h1>Cerveau</h1>
  <?php
  if ($_SESSION['logged'] == true)
  {
  $production = calculerGenAmour(0,3600,$nbE[0][0],$nbE[1][0],$nbE[1][1],$nbE[1][2]);
  ?>
  Score : <strong><?php echo formaterNombre($score); ?></strong> Point<?php echo pluriel($score);?><br />
  <?php
        if ($donnees_info = mysql_fetch_assoc($sql_info))
        {
                $pseudoCible = $donnees_info2['pseudo'];
  ?>
  Tu vas tenter d'embrasser <strong><?php echo $pseudoCible; ?></strong>
  <?php
        }
  }
  ?>
```

This is [a known issue](https://github.com/PHP-CS-Fixer/PHP-CS-Fixer/issues/3702#issuecomment-396717120),
and currently PHP CS Fixer doesn't support these kind of files,
so all we can do is restore `PSR2` and then disable that one specific rule:

```php
<?php

use PhpCsFixer\Runner\Parallel\ParallelConfigFactory;

$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__.'/../monolith/web')
    ->exclude('ban')
    ->exclude('images')
    ->exclude('includes')
    ->exclude('polices')
    ->exclude('smileys')
;

return (new PhpCsFixer\Config())
    ->setRules([
        // —— CS Rule Sets —————————————————————————————————————————————————————
        '@PSR2' => true,

        // —— Overriden rules ——————————————————————————————————————————————————

        // [PSR2] Disabled as the fixes break the following files:
        // 1) ../monolith/web/phpincludes/bisous.php
        // 2) ../monolith/web/phpincludes/cerveau.php
        'statement_indentation' => false,
    ])
    ->setRiskyAllowed(true)
    ->setParallelConfig(ParallelConfigFactory::detect())
    ->setUsingCache(true)
    ->setFinder($finder)
;
```

Now we can fix the files running `make cs-fix`.

## Level 3: PSR-12

Let's now upgrade to [PSR-12 ruleset](https://cs.symfony.com/doc/ruleSets/PSR12.html):

```php
<?php

use PhpCsFixer\Runner\Parallel\ParallelConfigFactory;

$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__.'/../monolith/web')
    ->exclude('ban')
    ->exclude('images')
    ->exclude('includes')
    ->exclude('polices')
    ->exclude('smileys')
;

return (new PhpCsFixer\Config())
    ->setRules([
        // —— CS Rule Sets —————————————————————————————————————————————————————
        '@PSR12' => true,

        // —— Overriden rules ——————————————————————————————————————————————————

        // [PSR2] Disabled as the fixes break the following files:
        // 1) ../monolith/web/phpincludes/bisous.php
        // 2) ../monolith/web/phpincludes/cerveau.php
        'statement_indentation' => false,
    ])
    ->setRiskyAllowed(true)
    ->setParallelConfig(ParallelConfigFactory::detect())
    ->setUsingCache(true)
    ->setFinder($finder)
;
```

PSR-12 extends PSR-2 with rules for modern PHP syntax,
specifically how to format newer language features like:

* type declarations
* arrow functions
* anonymous classes
* trait usage

As well as other PHP 7+ constructs that didn't exist when PSR-2 was written
(in 2012, when PHP 5.4 got released).

Let's run the checks:

```console
> make cs-check
PHP CS Fixer 3.85.1 Alexander by Fabien Potencier, Dariusz Ruminski and contributors.
PHP runtime: 8.4.12
Running analysis on 15 cores with 10 files per process.
Parallel runner is an experimental feature and may be unstable, use it at your own risk. Feedback highly appreciated!
Loaded config default from "/apps/qa/.php-cs-fixer.dist.php".
Using cache file ".php-cs-fixer.cache".
 43/43 [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓] 100%

   1) ../monolith/web/calcul.php (binary_operator_spaces)
   2) ../monolith/web/redirect.php (blank_line_after_opening_tag, binary_operator_spaces, no_whitespace_in_blank_line)
   3) ../monolith/web/checkConnect.php (binary_operator_spaces, no_whitespace_in_blank_line)
   4) ../monolith/web/phpincludes/fctIndex.php (blank_line_after_opening_tag, binary_operator_spaces, no_whitespace_in_blank_line)
   5) ../monolith/web/phpincludes/topten.php (binary_operator_spaces, no_whitespace_in_blank_line)
   6) ../monolith/web/phpincludes/pages.php (blank_line_after_opening_tag)
   7) ../monolith/web/deconnexion.php (blank_line_after_opening_tag, binary_operator_spaces)
   8) ../monolith/web/news/rediger_news.php (no_whitespace_in_blank_line)
   9) ../monolith/web/news/chemin.php (blank_line_after_opening_tag)
  10) ../monolith/web/phpincludes/evo.php (binary_operator_spaces, no_whitespace_in_blank_line)
  11) ../monolith/web/phpincludes/stats.php (binary_operator_spaces, no_whitespace_in_blank_line)
  12) ../monolith/web/phpincludes/infos.php (binary_operator_spaces)
  13) ../monolith/web/phpincludes/cerveau.php (binary_operator_spaces, no_whitespace_in_blank_line)
  14) ../monolith/web/phpincludes/yeux.php (binary_operator_spaces, no_whitespace_in_blank_line)
  15) ../monolith/web/phpincludes/inscription.php (binary_operator_spaces, no_whitespace_in_blank_line)
  16) ../monolith/web/phpincludes/faq.php (binary_operator_spaces, no_whitespace_in_blank_line)
  17) ../monolith/web/phpincludes/construction.php (binary_operator_spaces)
  18) ../monolith/web/phpincludes/recherche.php (binary_operator_spaces)
  19) ../monolith/web/makeBan.php (binary_operator_spaces, no_whitespace_in_blank_line)
  20) ../monolith/web/index.php (binary_operator_spaces, no_whitespace_in_blank_line)
  21) ../monolith/web/phpincludes/livreor.php (binary_operator_spaces, no_whitespace_in_blank_line)
  22) ../monolith/web/phpincludes/bisous.php (binary_operator_spaces, no_whitespace_in_blank_line)
  23) ../monolith/web/phpincludes/boite.php (indentation_type, binary_operator_spaces, no_whitespace_in_blank_line)
  24) ../monolith/web/phpincludes/connected.php (indentation_type, binary_operator_spaces, no_whitespace_in_blank_line)
  25) ../monolith/web/phpincludes/envoi.php (binary_operator_spaces, no_whitespace_in_blank_line)
  26) ../monolith/web/phpincludes/action.php (binary_operator_spaces, no_whitespace_in_blank_line)
  27) ../monolith/web/phpincludes/accueil.php (binary_operator_spaces, no_whitespace_in_blank_line)
  28) ../monolith/web/phpincludes/lire.php (binary_operator_spaces, no_whitespace_in_blank_line)
  29) ../monolith/web/phpincludes/membres.php (binary_operator_spaces)
  30) ../monolith/web/phpincludes/nuage.php (binary_operator_spaces, no_whitespace_in_blank_line)
  31) ../monolith/web/phpincludes/attaque.php (blank_line_after_opening_tag, binary_operator_spaces, no_whitespace_in_blank_line)
  32) ../monolith/web/phpincludes/confirmation.php (binary_operator_spaces, no_whitespace_in_blank_line)
  33) ../monolith/web/phpincludes/changepass.php (binary_operator_spaces, no_whitespace_in_blank_line)
  34) ../monolith/web/phpincludes/techno.php (binary_operator_spaces)
  35) ../monolith/web/phpincludes/newpass.php (binary_operator_spaces, no_whitespace_in_blank_line)

Found 35 of 43 files that can be fixed in 0.207 seconds, 18.00 MB memory used
```

So far so good, let's apply the changes: `make cs-fix`.

But we are not finished here, it's time to introduce **risky** rules:
these are rules that once applied can potentially change the logic and behaviour of your code.

For example the rule [no_unreachable_default_argument_value](https://cs.symfony.com/doc/rules/function_notation/no_unreachable_default_argument_value.html),
will remove default values for arguments,
that come before other arguments without default values.

Here's the new configuration:

```php
<?php

use PhpCsFixer\Runner\Parallel\ParallelConfigFactory;

$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__.'/../monolith/web')
    ->exclude('ban')
    ->exclude('images')
    ->exclude('includes')
    ->exclude('polices')
    ->exclude('smileys')
;

return (new PhpCsFixer\Config())
    ->setRules([
        // —— CS Rule Sets —————————————————————————————————————————————————————
        '@PSR12' => true,
        '@PSR12:risky' => true,

        // —— Overriden rules ——————————————————————————————————————————————————

        // [PSR2] Disabled as the fixes break the following files:
        // 1) ../monolith/web/phpincludes/bisous.php
        // 2) ../monolith/web/phpincludes/cerveau.php
        'statement_indentation' => false,
    ])
    ->setRiskyAllowed(true)
    ->setParallelConfig(ParallelConfigFactory::detect())
    ->setUsingCache(true)
    ->setFinder($finder)
;
```

Running `make cs-check` will show that all is fine,
so we apply the change through `make cs-fix`,
and then we have a look at the changes made,
and test around to make sure nothing is broken.

## Level 4: PER CS 2.0

Next is the [PER CS 2.0 ruleset](https://cs.symfony.com/doc/ruleSets/PERCS2x0.html):

```php
<?php

use PhpCsFixer\Runner\Parallel\ParallelConfigFactory;

$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__.'/../monolith/web')
    ->exclude('ban')
    ->exclude('images')
    ->exclude('includes')
    ->exclude('polices')
    ->exclude('smileys')
;

return (new PhpCsFixer\Config())
    ->setRules([
        // —— CS Rule Sets —————————————————————————————————————————————————————
        '@PER-CS2x0' => true,
        '@PER-CS2x0:risky' => true,

        // —— Overriden rules ——————————————————————————————————————————————————

        // [PSR2] Disabled as the fixes break the following files:
        // 1) ../monolith/web/phpincludes/bisous.php
        // 2) ../monolith/web/phpincludes/cerveau.php
        'statement_indentation' => false,
    ])
    ->setRiskyAllowed(true)
    ->setParallelConfig(ParallelConfigFactory::detect())
    ->setUsingCache(true)
    ->setFinder($finder)
;
```

As the PHP language evolves it gets new features,
which then requires the coding standards PSRs to be updated.

However the PSRs process where not suitable for updates,
so PER (PHP Evolving Recommendation) was created.

PER CS 1.0, released in 2022, is intentionally strictly equivalent to PSR-12.

In 2023, PER CS 2.0 was released, to cover PHP 8 new features, such as:

* Type declarations for properties
* Constructor property promotion
* Match expressions
* Named arguments
* Attributes
* Readonly properties and classes
* Enum declarations

Because it is targeted at new PHP versions,
some of its rule won't be compatible with our version of PHP (5.6):

* [trailing_comma_in_multiline](https://cs.symfony.com/doc/rules/control_structure/trailing_comma_in_multiline.html)

In PHP 5.6, trailing commas are only supported with arrays,
so we need to change our configuration slightly:

```php
<?php

use PhpCsFixer\Runner\Parallel\ParallelConfigFactory;

$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__.'/../monolith/web')
    ->exclude('ban')
    ->exclude('images')
    ->exclude('includes')
    ->exclude('polices')
    ->exclude('smileys')
;

return (new PhpCsFixer\Config())
    ->setRules([
        // —— CS Rule Sets —————————————————————————————————————————————————————
        '@PER-CS2x0' => true,
        '@PER-CS2x0:risky' => true,

        // —— Overriden rules ——————————————————————————————————————————————————

        // [PSR2] Disabled as the fixes break the following files:
        // 1) ../monolith/web/phpincludes/bisous.php
        // 2) ../monolith/web/phpincludes/cerveau.php
        'statement_indentation' => false,

        // [PER-CS2.0] Partially disabled due to PHP version constraints.
        'trailing_comma_in_multiline' => [
            'after_heredoc' => true,
            'elements' => [
                // 'arguments', For PHP 7.3+
                // 'array_destructuring', For PHP 7.1+
                'arrays',
                // 'match', For PHP 8.0+
                // 'parameters', For PHP 8.0+
            ],
        ],
    ])
    ->setRiskyAllowed(true)
    ->setParallelConfig(ParallelConfigFactory::detect())
    ->setUsingCache(true)
    ->setFinder($finder)
;
```

If we run the checks:

```console
> make cs-check
PHP CS Fixer 3.88.2 Folding Bike by Fabien Potencier, Dariusz Ruminski and contributors.
PHP runtime: 8.4.12
Running analysis on 15 cores with 10 files per process.
Parallel runner is an experimental feature and may be unstable, use it at your own risk. Feedback highly appreciated!
Loaded config default from "/apps/qa/.php-cs-fixer.dist.php".
Using cache file ".php-cs-fixer.cache".
 43/43 [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓] 100%

   1) ../monolith/web/calcul.php (concat_space, binary_operator_spaces)
   2) ../monolith/web/redirect.php (blank_line_after_opening_tag, concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
   3) ../monolith/web/checkConnect.php (concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
   4) ../monolith/web/phpincludes/fctIndex.php (array_syntax, array_indentation, blank_line_after_opening_tag, concat_space, trailing_comma_in_multiline, binary_operator_spaces,no_whitespace_in_blank_line)
   5) ../monolith/web/phpincludes/topten.php (concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
   6) ../monolith/web/phpincludes/pages.php (array_syntax, blank_line_after_opening_tag, trailing_comma_in_multiline)
   7) ../monolith/web/deconnexion.php (blank_line_after_opening_tag, concat_space, binary_operator_spaces)
   8) ../monolith/web/news/rediger_news.php (no_whitespace_in_blank_line)
   9) ../monolith/web/news/chemin.php (blank_line_after_opening_tag)
  10) ../monolith/web/news/liste_news.php (concat_space)
  11) ../monolith/web/phpincludes/evo.php (concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  12) ../monolith/web/phpincludes/stats.php (concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  13) ../monolith/web/phpincludes/infos.php (array_syntax, concat_space, trailing_comma_in_multiline, binary_operator_spaces)
  14) ../monolith/web/phpincludes/cerveau.php (concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  15) ../monolith/web/phpincludes/yeux.php (concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  16) ../monolith/web/phpincludes/inscription.php (concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  17) ../monolith/web/phpincludes/faq.php (array_syntax, concat_space, trailing_comma_in_multiline, binary_operator_spaces, no_whitespace_in_blank_line)
  18) ../monolith/web/phpincludes/construction.php (concat_space, binary_operator_spaces)
  19) ../monolith/web/phpincludes/recherche.php (concat_space, binary_operator_spaces)
  20) ../monolith/web/phpincludes/bd.php (concat_space)
  21) ../monolith/web/makeBan.php (concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  22) ../monolith/web/index.php (array_syntax, concat_space, trailing_comma_in_multiline, binary_operator_spaces, no_whitespace_in_blank_line)
  23) ../monolith/web/phpincludes/livreor.php (concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  24) ../monolith/web/phpincludes/bisous.php (array_syntax, concat_space, trailing_comma_in_multiline, binary_operator_spaces, no_whitespace_in_blank_line)
  25) ../monolith/web/phpincludes/boite.php (indentation_type, concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  26) ../monolith/web/phpincludes/connected.php (indentation_type, concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  27) ../monolith/web/phpincludes/envoi.php (concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  28) ../monolith/web/phpincludes/action.php (concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  29) ../monolith/web/phpincludes/accueil.php (array_syntax, array_indentation, binary_operator_spaces, no_whitespace_in_blank_line)
  30) ../monolith/web/phpincludes/lire.php (concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  31) ../monolith/web/phpincludes/membres.php (concat_space, binary_operator_spaces)
  32) ../monolith/web/phpincludes/nuage.php (concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  33) ../monolith/web/phpincludes/attaque.php (blank_line_after_opening_tag, concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  34) ../monolith/web/phpincludes/confirmation.php (array_syntax, concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  35) ../monolith/web/phpincludes/changepass.php (concat_space, binary_operator_spaces, no_whitespace_in_blank_line)
  36) ../monolith/web/phpincludes/techno.php (concat_space, binary_operator_spaces)
  37) ../monolith/web/phpincludes/newpass.php (concat_space, binary_operator_spaces, no_whitespace_in_blank_line)

Found 37 of 43 files that can be fixed in 0.210 seconds, 16.00 MB memory used
```

Once again, no issues there, so we can apply the fixes: `make-cs fix`.

## Level 5: Symfony

Time for the final boss, the Coding Standards used in the Symfony project.

See [Symfony ruleset here](https://cs.symfony.com/doc/ruleSets/Symfony.html),
and [Symfony:risky ruleset there](https://cs.symfony.com/doc/ruleSets/SymfonyRisky.html).

Those are by no means meant to be used in Symfony projects (or any projects),
it's just what the Symfony developers use internally to build the framework.

But these 41 rules provide:

* Stricter PHPDoc requirements
* Import (`use` statements) organisation and formatting
* More opinionated whitespace and formatting rules
* Type handling - Specific rules about how types are ordered and formatted

The 34 risky rules also add performance optimisations
(e.g. native function invocation with leading backslash to by pass autoloading lookup).

So let's adopt them here:

```php
<?php

use PhpCsFixer\Runner\Parallel\ParallelConfigFactory;

$finder = (new PhpCsFixer\Finder())
    ->in(__DIR__.'/../monolith/web')
    ->exclude('ban')
    ->exclude('images')
    ->exclude('includes')
    ->exclude('polices')
    ->exclude('smileys')
;

return (new PhpCsFixer\Config())
    ->setRules([
        // —— CS Rule Sets —————————————————————————————————————————————————————
        '@Symfony' => true,
        '@Symfony:risky' => true,

        // —— Overriden rules ——————————————————————————————————————————————————

        // [PSR2] Disabled as the fixes break the following files:
        // 1) ../monolith/web/phpincludes/bisous.php
        // 2) ../monolith/web/phpincludes/cerveau.php
        'statement_indentation' => false,

        // [PER-CS2.0] Partially disabled due to PHP version constraints.
        'trailing_comma_in_multiline' => [
            'after_heredoc' => true,
            'elements' => [
                // 'arguments', For PHP 7.3+
                // 'array_destructuring', For PHP 7.1+
                'arrays',
                // 'match', For PHP 8.0+
                // 'parameters', For PHP 8.0+
            ],
        ],
    ])
    ->setRiskyAllowed(true)
    ->setParallelConfig(ParallelConfigFactory::detect())
    ->setUsingCache(true)
    ->setFinder($finder)
;
```

Let's run the checks:

```console
> make cs-check
PHP CS Fixer 3.88.2 Folding Bike by Fabien Potencier, Dariusz Ruminski and contributors.
PHP runtime: 8.4.12
Running analysis on 15 cores with 10 files per process.
Parallel runner is an experimental feature and may be unstable, use it at your own risk. Feedback highly appreciated!
Loaded config default from "/apps/qa/.php-cs-fixer.dist.php".
Using cache file ".php-cs-fixer.cache".
 43/43 [▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓▓] 100%

   1) ../monolith/web/calcul.php (concat_space, no_extra_blank_lines)
   2) ../monolith/web/redirect.php (single_quote, single_line_comment_spacing, concat_space, yoda_style, no_extra_blank_lines)
   3) ../monolith/web/checkConnect.php (increment_style, single_quote, single_line_comment_spacing, concat_space, yoda_style, no_extra_blank_lines)
   4) ../monolith/web/phpincludes/fctIndex.php (single_space_around_construct, no_unneeded_control_parentheses, single_quote, single_line_comment_spacing, concat_space, yoda_style, no_extra_blank_lines, blank_line_before_statement)
   5) ../monolith/web/phpincludes/topten.php (single_space_around_construct, no_unneeded_control_parentheses, increment_style, single_line_comment_spacing, concat_space, yoda_style, space_after_semicolon, no_extra_blank_lines)
   6) ../monolith/web/phpincludes/pages.php (single_quote, single_line_comment_spacing)
   7) ../monolith/web/deconnexion.php (single_quote, single_line_comment_spacing, concat_space, yoda_style, no_extra_blank_lines)
   8) ../monolith/web/news/rediger_news.php (concat_space, no_extra_blank_lines)
   9) ../monolith/web/news/chemin.php (blank_line_after_opening_tag)
  10) ../monolith/web/news/liste_news.php (single_line_comment_spacing, concat_space, yoda_style, logical_operators, no_extra_blank_lines)
  11) ../monolith/web/reductionNuages.php (single_line_comment_spacing)
  12) ../monolith/web/phpincludes/evo.php (increment_style, single_quote, single_line_comment_spacing, concat_space, yoda_style, no_extra_blank_lines, blank_line_before_statement)
  13) ../monolith/web/phpincludes/stats.php (single_space_around_construct, single_quote, semicolon_after_instruction, concat_space, space_after_semicolon)
  14) ../monolith/web/phpincludes/infos.php (increment_style, single_line_comment_spacing, concat_space, yoda_style, space_after_semicolon)
  15) ../monolith/web/phpincludes/cerveau.php (single_space_around_construct, no_unneeded_control_parentheses, single_quote, single_line_comment_spacing, concat_space, yoda_style, space_after_semicolon, no_extra_blank_lines)
  16) ../monolith/web/phpincludes/yeux.php (no_unneeded_control_parentheses, single_quote, single_line_comment_spacing, concat_space, yoda_style, space_after_semicolon, no_extra_blank_lines)
  17) ../monolith/web/phpincludes/inscription.php (single_quote, single_line_comment_spacing, concat_space, yoda_style, space_after_semicolon, no_extra_blank_lines)
  18) ../monolith/web/phpincludes/faq.php (single_quote, single_line_comment_spacing, concat_space, no_extra_blank_lines)
  19) ../monolith/web/phpincludes/construction.php (single_space_around_construct, no_unneeded_control_parentheses, increment_style, single_line_comment_spacing, concat_space, yoda_style, space_after_semicolon, no_extra_blank_lines)
  20) ../monolith/web/phpincludes/recherche.php (single_quote, concat_space, yoda_style)
  21) ../monolith/web/phpincludes/bd.php (concat_space)
  22) ../monolith/web/phpincludes/accueil.php (single_quote, whitespace_after_comma_in_array, yoda_style, space_after_semicolon, no_extra_blank_lines)
  23) ../monolith/web/phpincludes/lire.php (single_space_around_construct, single_quote, concat_space, yoda_style, space_after_semicolon, no_extra_blank_lines)
  24) ../monolith/web/phpincludes/membres.php (modernize_types_casting, no_unneeded_control_parentheses, increment_style, single_quote, concat_space, no_singleline_whitespace_before_semicolons, yoda_style, no_extra_blank_lines, binary_operator_spaces)
  25) ../monolith/web/phpincludes/nuage.php (single_space_around_construct, increment_style, single_quote, single_line_comment_spacing, concat_space, yoda_style, space_after_semicolon, no_extra_blank_lines)
  26) ../monolith/web/phpincludes/attaque.php (no_empty_statement, no_unneeded_control_parentheses, single_quote, single_line_comment_spacing, concat_space, yoda_style, no_extra_blank_lines)
  27) ../monolith/web/phpincludes/confirmation.php (no_unneeded_control_parentheses, increment_style, single_quote, single_line_comment_spacing, concat_space, yoda_style, space_after_semicolon, no_extra_blank_lines)
  28) ../monolith/web/phpincludes/changepass.php (single_line_comment_spacing, concat_space, yoda_style, space_after_semicolon)
  29) ../monolith/web/phpincludes/techno.php (single_space_around_construct, no_unneeded_control_parentheses, increment_style, single_line_comment_spacing, concat_space, yoda_style, space_after_semicolon, no_extra_blank_lines)
  30) ../monolith/web/phpincludes/newpass.php (single_line_comment_spacing, concat_space, yoda_style, space_after_semicolon, no_extra_blank_lines)
  31) ../monolith/web/makeBan.php (increment_style, single_quote, single_line_comment_spacing, concat_space, space_after_semicolon)
  32) ../monolith/web/index.php (single_space_around_construct, increment_style, single_quote, no_spaces_after_function_name, single_line_comment_spacing, concat_space, include,no_singleline_whitespace_before_semicolons, yoda_style, space_after_semicolon, no_extra_blank_lines)
  33) ../monolith/web/phpincludes/livreor.php (modernize_types_casting, no_unneeded_control_parentheses, increment_style, single_quote, semicolon_after_instruction, single_line_comment_spacing, native_constant_invocation, concat_space, no_singleline_whitespace_before_semicolons, yoda_style, no_extra_blank_lines, binary_operator_spaces)
  34) ../monolith/web/phpincludes/bisous.php (single_space_around_construct, no_unneeded_control_parentheses, increment_style, single_line_comment_spacing, concat_space, yoda_style, space_after_semicolon, no_extra_blank_lines)
  35) ../monolith/web/phpincludes/connexion.php (yoda_style, no_extra_blank_lines)
  36) ../monolith/web/phpincludes/boite.php (indentation_type, single_space_around_construct, increment_style, single_quote, single_line_comment_spacing, concat_space, yoda_style, space_after_semicolon, no_extra_blank_lines)
  37) ../monolith/web/phpincludes/connected.php (indentation_type, single_quote, single_line_comment_spacing, concat_space, yoda_style, no_extra_blank_lines)
  38) ../monolith/web/phpincludes/envoi.php (single_quote, single_line_comment_spacing, concat_space, yoda_style, space_after_semicolon, no_extra_blank_lines)
  39) ../monolith/web/phpincludes/action.php (no_unneeded_braces, single_quote, single_line_comment_spacing, concat_space, yoda_style, space_after_semicolon, no_extra_blank_lines, no_whitespace_in_blank_line)

Found 39 of 43 files that can be fixed in 0.212 seconds, 16.00 MB memory used
```

All safe it'd seem, let's apply those then: `make cs-fix`

## Conclusion

By progressively applying PHP CS Fixer rule sets,
we've transformed BisouLand's chaotic 2005 code into something that follows modern standards.

The key insight here is **incrementalism**,
we didn't jump straight to the strictest rule set,
but instead built up gradually:

1. PSR-1: Basic formatting (opening tags, encoding)
2. PSR-2: Braces and indentation
3. PSR-12: Modern PHP syntax support
4. PER-CS 2.0: PHP 8 features (adjusted for PHP 5.6 compatibility)
5. Symfony: Stricter PHPDoc, imports, and performance optimisations

Along the way we:

* **Identified problematic rules** (`statement_indentation` breaks mixed HTML/PHP files)
* **Adapted for PHP version constraints** (trailing commas only for arrays in PHP 5.6)
* **Applied changes incrementally** (check, fix, test, repeat)

The final configuration gives us automated formatting that makes the code more
readable and maintainable, without breaking functionality.

Now, before we move on, here's a super secret PHP CS Fixer tip:
you can run `php-cs-fixer describe <rule/ruleset>`,
which serves as a local documentation:

```console
> docker compose exec app php vendor/bin/php-cs-fixer describe trailing_comma_in_multiline
PHP CS Fixer 3.88.2 Folding Bike by Fabien Potencier, Dariusz Ruminski and contributors.
PHP runtime: 8.4.12
Description of the `trailing_comma_in_multiline` rule.

Arguments lists, array destructuring lists, arrays that are multi-line, `match`-lines and parameters lists must have a trailing comma.

Fixer is configurable using following options:
* after_heredoc (bool): whether a trailing comma should also be placed after heredoc end; defaults to false
* elements (a subset of ['arguments', 'array_destructuring', 'arrays', 'match', 'parameters']): where to fix multiline trailing comma (PHP >= 8.0 for `parameters` and `match`); defaults to ['arrays']

Fixing examples:
 * Example #1. Fixing with the default configuration.
   ---------- begin diff ----------
   --- Original
   +++ New
   @@ -1,5 +1,5 @@
    <?php
    array(
        1,
   -    2
   +    2,
    );
   
   ----------- end diff -----------

 * Example #2. Fixing with configuration: ['after_heredoc' => true].
   ---------- begin diff ----------
   --- Original
   +++ New
   @@ -1,7 +1,7 @@
    <?php
        $x = [
            'foo',
            <<<EOD
                bar
   -            EOD
   +            EOD,
        ];
   
   ----------- end diff -----------

 * Example #3. Fixing with configuration: ['elements' => ['arguments']].
   ---------- begin diff ----------
   --- Original
   +++ New
   @@ -1,5 +1,5 @@
    <?php
    foo(
        1,
   -    2
   +    2,
    );
   
   ----------- end diff -----------

 * Example #4. Fixing with configuration: ['elements' => ['parameters']].
   ---------- begin diff ----------
   --- Original
   +++ New
   @@ -1,7 +1,7 @@
    <?php
    function foo(
        $x,
   -    $y
   +    $y,
    )
    {
    }
   
   ----------- end diff -----------

The fixer is part of the following rule sets:
* @PER *(deprecated)* with config: ['after_heredoc' => true, 'elements' => ['arguments', 'array_destructuring', 'arrays', 'match', 'parameters']]
* @PER-CS with config: ['after_heredoc' => true, 'elements' => ['arguments', 'array_destructuring', 'arrays', 'match', 'parameters']]
* @PER-CS2.0 *(deprecated)* with config: ['after_heredoc' => true, 'elements' => ['arguments', 'array_destructuring', 'arrays', 'match', 'parameters']]
* @PER-CS2x0 with config: ['after_heredoc' => true, 'elements' => ['arguments', 'array_destructuring', 'arrays', 'match', 'parameters']]
* @PER-CS3.0 *(deprecated)* with config: ['after_heredoc' => true, 'elements' => ['arguments', 'array_destructuring', 'arrays', 'match', 'parameters']]
* @PER-CS3x0 with config: ['after_heredoc' => true, 'elements' => ['arguments', 'array_destructuring', 'arrays', 'match', 'parameters']]
* @PHP73Migration *(deprecated)* with config: ['after_heredoc' => true]
* @PHP74Migration *(deprecated)* with config: ['after_heredoc' => true]
* @PHP7x3Migration with config: ['after_heredoc' => true]
* @PHP7x4Migration with config: ['after_heredoc' => true]
* @PHP80Migration *(deprecated)* with config: ['after_heredoc' => true]
* @PHP81Migration *(deprecated)* with config: ['after_heredoc' => true]
* @PHP82Migration *(deprecated)* with config: ['after_heredoc' => true]
* @PHP83Migration *(deprecated)* with config: ['after_heredoc' => true]
* @PHP84Migration *(deprecated)* with config: ['after_heredoc' => true]
* @PHP85Migration *(deprecated)* with config: ['after_heredoc' => true]
* @PHP8x0Migration with config: ['after_heredoc' => true]
* @PHP8x1Migration with config: ['after_heredoc' => true]
* @PHP8x2Migration with config: ['after_heredoc' => true]
* @PHP8x3Migration with config: ['after_heredoc' => true]
* @PHP8x4Migration with config: ['after_heredoc' => true]
* @PHP8x5Migration with config: ['after_heredoc' => true]
* @PhpCsFixer with config: ['after_heredoc' => true, 'elements' => ['array_destructuring', 'arrays']]
* @Symfony with config: ['after_heredoc' => true, 'elements' => ['array_destructuring', 'arrays', 'match', 'parameters']]
```

> ⁉️ _Hold on, what about those **SQL injection vulnerabilities**?_
