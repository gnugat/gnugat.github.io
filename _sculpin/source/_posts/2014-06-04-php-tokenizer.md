---
layout: post
title: PHP Tokenizer
tags:
    - php
---

The [PHP Tokenizer documentation](http://www.php.net/manual/en/book.tokenizer.php)
looks a bit empty, and you have to try it out by yourself to understand how it
works.

While I don't mind the "learn by practice" approach (that's actually my
favorite way of learning), it's inconvenient as you might have to re-discover
things when using it again two month later.

To fix this, I'll try to provide a small reference guide in this article.

## PHP tokens

A token is just a unique identifier allowing you to define what you're
manipulating: PHP keywords, function names, whitespace and comments are all be
represented as tokens.

If you want to programmatically read a PHP file, analyze its source code and
possibly manipulate it and save the changes, then tokens will make your life
easier.

Here's some actual examples of what tokens are used for:

* analyzing PHP code to detect coding standard violations:
  [PHP_CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer)
* programmatic edition of PHP: [PHP Parser](https://github.com/nikic/PHP-Parser)
* live backport of PHP features (e.g. 5.6 to 5.2):
  [Galapagos](https://github.com/igorw/galapagos#galapagos)

## Basic API

Tokenizer provides you with `token_get_all($source)` which takes a string
containing PHP source code and makes an array of tokens and informations out of
it.

Here's an example:

```php
<?php
$code =<<<'EOF'
<?php

/**
 * @param string $content
 */
function strlen($content)
{
    for ($length = 0; isset($content[$length]); $length++);

    return $length;
}
EOF;

$tokens = token_get_all($code);
```

Should produce:

```
$tokens = array(
    // Either a string or an array with 3 elements:
    // 0: code, 1: value, 2: line number

    // Line 1
    array(T_OPEN_TAG, "<?php\n", 1),
    // Line 2
    array(T_WHITESPACE, "\n", 2),
    // Lines 3, 4 and 5
    array(T_DOC_COMMENT, "/**\n * @param string $content\n */", 3), // On many lines
    array(T_WHITESPACE, "\n", 5),
    // Line 6
    array(T_FUNCTION, "function", 6),
    array(T_WHITESPACE, " ", 6), // Empty lines and spaces are the same: whitespace
    array(T_STRING, "strlen", 6),
    "(", // yep, no token nor line number...
    array(T_VARIABLE, "$content", 6),
    ")",
    array(T_WHITESPACE, "\n", 6),
    "{",
    // Line 7
    array(T_WHITESPACE, "\n", 7),
    // Line 8
    array(T_FOR, "for", 8),
    array(T_WHITESPACE, " ", 8),
    "(",
    array(T_VARIABLE, "$length", 8),
    array(T_WHITESPACE, " ", 8),
    "=",
    array(T_WHITESPACE, " ", 8),
    array(T_NUM, "0", 8),
    ";",
    array(T_WHITESPACE, " ", 8),
    array(T_ISSET, "isset", 8),
    "(",
    array(T_VARIABLE, "$content", 8),
    "[",
    array(T_VARIABLE, "$length", 8),
    "]",
    ")",
    ";",
    array(T_WHITESPACE, " ", 8),
    array(T_VARIABLE, "$length", 8),
    array(T_INC, "++", 8),
    ")",
    ";",
    array(T_WHITESPACE, "\n\n", 8), // Double new line in one token
    // Line 10
    array(T_RETURN, "return", 10),
    array(T_WHITESPACE, " ", 10),
    array(T_VARIABLE, "$length", 10),
    ";",
    array(T_WHITESPACE, "\n", 10),
    "}",
);
```

As you can see some things might seem odd, but once you know it you can start
manipulating the tokens. You should rely only on constants because their value
might vary between versions (e.g. `T_OPEN_TAG` is `376` in 5.6 and `374` in
5.5).

If you want to display a readable representation of the token's constant values,
use `token_name($token)`.

## Further resources

Here's some resources you might find interresting:

* [Tokenizer documentation](http://www.php.net/manual/en/book.tokenizer.php)
* [token_name documentation](http://www.php.net/manual/en/function.token-name.php)
* [token_get_all documentation](http://www.php.net/manual/en/function.token-get-all.php)
* [list of PHP tokens](http://www.php.net/manual/en/tokens.php)
* [PHP grammar rules](https://github.com/php/php-src/blob/master/Zend/zend_language_parser.y)
* [How to get the entire function from a file? on Stack Overflow](http://stackoverflow.com/a/2751170/3437428)
* [Compiling an AST back to source code, on Stack Overflow](http://stackoverflow.com/questions/5832412/compiling-an-ast-back-to-source-code)
* [PHP Parser](https://github.com/nikic/PHP-Parser)
* [Galapagos](https://github.com/igorw/galapagos#galapagos)
* [PHP_CodeSniffer](https://github.com/squizlabs/PHP_CodeSniffer)
* [Redaktilo](https://github.com/gnugat/redaktilo)
* [working with PHP tokens by Thierry Graff](http://www.tig12.net/spip/Working-with-PHP-tokens.html)
