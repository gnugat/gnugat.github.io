---
layout: tutorial
title: "Learn: HTML"
---

A web page is a document written in HTML (HyperText Markup Language),
and displayed in a Browser such as [Firefox](https://en.wikipedia.org/wiki/Firefox)
or [Chrome](https://en.wikipedia.org/wiki/Google_Chrome)
(we don't support [Internet Explorer](https://en.wikipedia.org/wiki/Internet_Explorer) here!).

In this tutorial, we'll learn how to write [HTML5](https://en.wikipedia.org/wiki/HTML5)
(the latest version) to create the first page of our Bionicle Selfie Collection website: Selfionicle.

## Project setup

First let's quickly set up our project, which will have the following folder structure:

```
selfionicle/
└── web/
    └── index.html
```

We do this by creating the directory for our project, and go inside it:

```bash
mkdir -p ~/Projects/selfionicle
cd ~/Projects/selfionicle
```

Then we'll initialise a Git repository, to track our changes
(this will allow us to save versions, and rollback in case of emergency):

```bash
git init
```

Files at the project root (`~/Projects/selfionicle`) are private to the developer.
We'll make `./web/` the public root, only its contents will be served to visitors:

```bash
mkdir web
```

Next we'll create `./web/index.html` as an empty file:

```bash
touch ./web/index.html
```

Finally, let's save our progress before getting started with our first HTML code:

```bash
git add -A
git commit -m "Created selfionicle project"
```

## Building blocks

### Tags

HTML describes and structures data by wrapping it,
inside an **opening** and **closing** pair of angle-bracketed (`<` and `>`) **tags**,
with the closing one distinguished by its leading slash (`/`):

```html
<h1>Selfionicle</h1>
```

> **ℹ️ Note**:
>
> - `<h1>` is the **opening tag**
> - `Selfionicle` is the **content** of the tag
> - `</h1>` is the **closing tag**
>
> _It is worth noting_: a `h1` tag is a top-level heading.

Replace the placeholder in `./web/index.html` with this:

```bash
echo '<h1>Selfionicle</h1>' > ./web/index.html
```

We can now check what it renders by opening it with the browser:

```bash
open ./web/index.html
```

<img alt="Our blank page with `Selfionicle` as the title" src="/images/tutorials/html/000-tags.png" width="100%">

### Elements

The opening tag, its content, and the closing tag together form an **element**:


```html
<h1>Selfionicle</h1>

<p>Collect selfies with every Bionicle set you own.</p>
```

> **ℹ️ Note**:
>
> - `<h1>Selfionicle</h1>` is a top-level heading **element**
> - `<p>Collect selfies with every Bionicle set you own.</p>` is a paragraph **element**
>
> _It is worth noting_: a `p` tag is a paragraph.

Let's add the paragraph to our `./web/index.html` file:

```bash
# Note the double `>>`, we're adding to the file, not replacing its content
echo '' >> ./web/index.html
echo '<p>Collect selfies with every Bionicle set you own.</p>' >> ./web/index.html
```

We can now check what it renders by opening it with the browser:

```bash
open ./web/index.html # alternatively, just refresh the page
```

<img alt="Our page now with both `Selfionicle` title and the paragraph" src="/images/tutorials/html/001-elements.png" width="100%">

#### Block elements

`h1` and `p` are **block elements**: they start on a new line and take up the full width available.
Notice in the screenshot how they stack vertically, each on its own line.

### Void elements

Elements that carry meaning with no content to wrap are called **void elements**,
and are written with a single tag, with no closing counterpart:

```html
<h1>Selfionicle</h1>

<p>Collect selfies with every Bionicle set you own.<br>Find the power!</p>
```

> **ℹ️ Note**:
>
> - `<br>` is a **void element**
>
> _It is worth noting_: a `br` tag is a line break.

Let's update our `./web/index.html` file to add the line break inside the paragraph:

```bash
# We use **sed** to replace the closing tag `</p>` with `<br>Find the power!</p>`
# _Note that GNU sed on Linux isn't compatible with BSD sed on macOS_

# 🐧 on Linux
sed -i 's|</p>|<br>Find the power!</p>|' ./web/index.html

# 🍎 on macOS
sed -i '' 's|</p>|<br>Find the power!</p>|' ./web/index.html
```

We can now check what it renders by opening it with the browser:

```bash
open ./web/index.html # alternatively, just refresh the page
```

<img alt="Our paragraph now split across two lines with a line break" src="/images/tutorials/html/002-void-elements.png" width="100%">

Notice that in the source, `<br>` sits on the same line as the rest of the text,
yet the browser still renders it as a line break.
That's because the browser largely ignores whitespace in HTML:
spaces, tabs, and newlines in the source are collapsed into a single space, or nothing at all.

This means we can use indentation and line breaks freely to make the source easier to read:

```html
<h1>Selfionicle</h1>

<p>
    Collect selfies with every Bionicle set you own.<br>
    Find the power!
</p>
```

Let's rewrite `./web/index.html` like this:

```bash
# Note:
# - `command << 'DELIMITER' ... DELIMITER` is a "heredoc": it passes a multiline string as input to the command
# - `cat > file` rewrites the file with that input
# Useful when rewriting a whole file: cleaner than one echo per line

cat > ./web/index.html << 'TXT'
<h1>Selfionicle</h1>

<p>
    Collect selfies with every Bionicle set you own.<br>
    Find the power!
</p>
TXT
```

The browser renders this identically to the previous version.

### Attributes

Elements can have **attributes**: extra information added to the opening tag, written as `name="value"` pairs:

```html
<h1>Selfionicle</h1>

<p>
    Collect selfies with every <a href="https://brickset.com/sets/theme-Bionicle">Bionicle</a> set you own.<br>
    Find the power!
</p>
```

> **ℹ️ Note**:
>
> - `href` is an **attribute**
> - `https://brickset.com/sets/theme-Bionicle` is its value
>
> _It is worth noting_: a `a` tag is a link, `href` defines its URL and the content is its text.

Let's update `./web/index.html` to turn "Bionicle" into a link:

```bash
# 🐧 on Linux
sed -i 's|Bionicle|<a href="https://brickset.com/sets/theme-Bionicle">Bionicle</a>|' ./web/index.html

# 🍎 on macOS
sed -i '' 's|Bionicle|<a href="https://brickset.com/sets/theme-Bionicle">Bionicle</a>|' ./web/index.html
```

We can now check what it renders by opening it with the browser:

```bash
open ./web/index.html # alternatively, just refresh the page
```

<img alt="Our page now with `Bionicle` as a clickable link" src="/images/tutorials/html/003-attributes.png" width="100%">

### Boolean attributes

Some attributes are **boolean**: their presence alone enables a feature with no value needed:

```html
<h1>Selfionicle</h1>

<p>
    Collect selfies with every <a href="https://en.wikipedia.org/wiki/Bionicle">Bionicle</a> set you own.<br>
    Find the power!
</p>

<details open>
    <summary>About</summary>
    <p>A fan project collecting selfies of every Bionicle set ever made.</p>
</details>
```

> **ℹ️ Note**:
>
> - `open` is a **boolean attribute**
>
> _It is worth noting_: a `details` tag is a collapsible section,
> a `summary` tag is its visible label.

Let's add it to `./web/index.html`:

```bash
# Note the double `>>`, we're adding to the file, not replacing its content
cat >> ./web/index.html << 'TXT'

<details open>
    <summary>About</summary>
    <p>A fan project collecting selfies of every Bionicle set ever made.</p>
</details>
TXT
```

We can now check what it renders by opening it with the browser:

```bash
open ./web/index.html # alternatively, just refresh the page
```

<img alt="Our page now with the `About` details section expanded" src="/images/tutorials/html/004-attributes-boolean.png" width="100%">

Without `open`, the section is collapsed: only the summary label is visible, and the user must click to expand it.
Let's see it by removing `open`:

```bash
# 🐧 on Linux
sed -i 's|<details open>|<details>|' ./web/index.html

# 🍎 on macOS
sed -i '' 's|<details open>|<details>|' ./web/index.html
```

We can now check what it renders by opening it with the browser:

```bash
open ./web/index.html # alternatively, just refresh the page
```

<img alt="Our `About` details section now collapsed, showing only its summary label" src="/images/tutorials/html/005-attributes-boolean-closed.png" width="100%">

#### Inline elements

`a` is an **inline element**: it flows within the surrounding text, taking only as much width as its content.
Notice how "Bionicle" remains part of the sentence, with the surrounding words on the same line.

As a rule, block elements can contain inline elements, but inline elements should not contain block elements.

#### Nesting

Elements can be placed inside other elements: this is called **nesting**.
We already did this when we added the link inside the paragraph:

```html
<h1>Selfionicle</h1>

<p>
    Collect selfies with every <a href="https://brickset.com/sets/theme-Bionicle">Bionicle</a> set you own.<br>
    Find the power!
</p>
```

> **ℹ️ Note**:
>
> - `<p>` is the **parent** element
> - `<a>` is the **child** element, nested inside it

The child's closing tag must come before the parent's closing tag.

Valid, `</a>` closes before `</p>`:

```html
<p><a href="...">link</a></p>
```

Invalid, `</p>` closes before `</a>`:

```html
<p><a href="...">link</p></a>
```

---

That's all the theory. Let's save our progress before moving on:

```bash
git add -A
git commit -m "Learned HTML building blocks"
```

The rest of this tutorial puts it into practice.

## Web Server

When we visit a website, here's what happens:

1. the **Client** (Browser) sends a **Request** to a **Server**
2. the **Server** sends back to the **Client** a **Response**, containing the HTML document
3. the Browser then interprets the HTML document to display the web page

This is all done according to the [HTTP protocol](https://en.wikipedia.org/wiki/HTTP):

<img alt="Sequence diagrame showing Client sending Request to Server which returns Response" src="/images/tutorials/html/006-web-server-http-protocol.png">

To be able to see HTML documents from our local machine,
we don't necessarily need a Server, the Browser can open the following just fine:

```bash
open ./web/index.html
```

But we'll definitely need a Server once we deploy to production, and once we start using PHP,
so let's install one now and build the habit from the start: [FrankenPHP](https://frankenphp.dev/).

> *🔧 Tooling*:
>
> We'll manage tools like FrankenPHP with [Mise](https://mise.jdx.dev/):
> it installs tools per project, not system-wide.

Create a `mise.toml` file at the project root with a `[tools]` section declaring FrankenPHP:

```bash
cat > ./mise.toml << 'TXT'
[tools]
"github:dunglas/frankenphp" = "latest"
TXT
```

Running `mise install` downloads FrankenPHP, but it ships as two platform-specific binaries:
`frankenphp-mac` and `frankenphp-linux`. To use it as just `frankenphp`,
we need a symlink so let's define an `app:install` task that creates it:

```bash
cat >> ./mise.toml << 'TXT'

[tasks."app:install"]
description = "Install project dependencies"
run = """
mise install
if [ "$(uname)" = "Darwin" ]; then
    ln -sf $(mise where github:dunglas/frankenphp)/frankenphp-mac $(mise where github:dunglas/frankenphp)/frankenphp
elif [ "$(uname)" = "Linux" ]; then
    ln -sf $(mise where github:dunglas/frankenphp)/frankenphp-linux $(mise where github:dunglas/frankenphp)/frankenphp
fi
"""
TXT
```

We could start the server by running `frankenphp php-server --root web --listen :8534` directly,
but that's a lot to type and easy to get wrong.
Instead, let's wrap it in an `app:launch` task so there's one canonical command anyone on the project can run:

```bash
cat >> ./mise.toml << 'TXT'

[tasks."app:launch"]
description = "Start the development server"
run = "frankenphp php-server --root web --listen :8534"
TXT
```

> **ℹ️ Note**:
>
> A **port** is a number that identifies a specific service on a machine.
> The default port for HTTP is `80`, but we use `8534` to avoid conflicts
> with any other HTTP servers that might be running on our local machine.
> With `--listen :8534` we tell FrankenPHP to listen on that port,
> so the server is reachable at `http://localhost:8534`.

Here's what the complete `mise.toml` looks like:

```toml
# File: mise.toml
[tools]
"github:dunglas/frankenphp" = "latest"

[tasks."app:install"]
description = "Install project dependencies"
run = """
mise install
if [ "$(uname)" = "Darwin" ]; then
    ln -sf $(mise where github:dunglas/frankenphp)/frankenphp-mac $(mise where github:dunglas/frankenphp)/frankenphp
elif [ "$(uname)" = "Linux" ]; then
    ln -sf $(mise where github:dunglas/frankenphp)/frankenphp-linux $(mise where github:dunglas/frankenphp)/frankenphp
fi
"""

[tasks."app:launch"]
description = "Start the development server"
run = "frankenphp php-server --root web --listen :8534"
```

Then we can run the following command to install FrankenPHP:

```bash
mise run app:install
```

Finally we can start the server like this:

```bash
mise run app:launch
```

Our page can now be viewed in the Browser at the following link:

* [http://localhost:8534/index.html](http://localhost:8534/index.html)

If no filename is specified, the server defaults to serving `index.html`,
which is why we named it like that:

* [http://localhost:8534/](http://localhost:8534/)

> **ℹ️ Note**:
>
> While the server is running it will occupy the terminal,
> so we need to open a new tab or window to continue.
>
> To stop it, go back to it and press `Ctrl + c`.

## Valid HTML

While `index.html` is full of valid HTML elements, correctly opened, closed, and nested,
it is not yet a valid HTML document.

We'll learn the rules as we go, but we also need a tool to catch mistakes we've missed.

> *🔧 Tooling*:
>
> We'll validate HTML with the [Nu Html Checker](https://validator.w3.org/nu/) (`vnu`), the official W3C validator.

Run the following to add it to the `[tools]` section of `mise.toml`:

```bash
mise use 'github:validator/validator'
```

Then add an `app:qa` task to `mise.toml`:

```bash
cat >> ./mise.toml << 'TXT'

[tasks."app:qa"]
description = "Check code quality"
run = "vnu web/*.html"
TXT
```

This will be our single entry point for quality checks: as the project grows, we'll expand it to also validate CSS, PHP, and more.

And run it:

```bash
mise app:qa
```

We get the following errors:

```
"file:…/index.html":1.1-1.4: error: Start tag seen without seeing a doctype first. Expected "<!DOCTYPE html>".
"file:…/index.html":1.1-1.4: error: Element "head" is missing a required instance of child element "title".
"file:…/index.html":1.1-1.4: info warning: Consider adding a "lang" attribute to the "html" start tag to declare the language of this document.
```

This is a tutorial on learning HTML, and by the Great Spirit we will learn it right!

Let's see how to actually write a valid HTML document.

## Skeleton

We're going to build a reusable **skeleton**: the minimum structure every HTML document requires.

Create `./web/skeleton.html`:

```bash
cat > ./web/skeleton.html << 'TXT'
<!-- File: web/skeleton.html -->
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Selfionicle</title>
  </head>
  <body>
    <!-- content goes here -->
  </body>
</html>
TXT
```

Let's explain each part, line by line.

### Comments

Comments are notes left in the code for the developers, to add context:

```html
<!-- This is a comment -->
```

The browser ignores them entirely, they are never displayed on the page.
But they, along the rest of the code,
are visible to anyone who right-clicks the page and selects "View Page Source",
so never put anything confidential in them (e.g. passwords, etc).

> **ℹ️ Note**:
>
> In this tutorial I follow a convention where I put at the top of the code snippet a `File:` comment,
> it provides an easy way to the readers to know where the file is supposed to be,
> but keep in mind that this isn't a convention you'd find in non-tutorial codebase.

### Doctype

```
error: Start tag seen without seeing a doctype first. Expected "<!DOCTYPE html>".
```

To tackle that first error, we need to use as the first tag (comments don't count)
`<!DOCTYPE html>`, which tells the browser to use modern HTML5 rendering rules.

> **ℹ️ Note**:
>
> Older versions of HTML had much longer doctypes, such as:
>
> * HTML 4: `<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">`
> * xHTML: `<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">`
>
> These referenced DTD files that browsers were supposed to fetch and use for validation.
> In practice, no browser ever did. The doctype's only real job was to toggle standards mode,
> and browsers only checked for the presence of *some* doctype to do that.
> HTML5 cut the ceremony: `<!DOCTYPE html>` is the shortest string that triggers standards mode in every browser.

### Html

`<html>` is the true start of our document: every other element is nested inside it.

```
warning: Consider adding a "lang" attribute to the "html" start tag.
```

To fix that warning, we need to add the `lang` attribute to `<html>`:

```html
<html lang="en">
```

It tells the browser what language the page is written in:

* `en` means English
* `fr` means French
* `ja` means Japanese
* and so on...

The full list of values follows the [BCP 47](https://en.wikipedia.org/wiki/IETF_language_tag) standard.

> **ℹ️ Note**:
>
> Screen readers use `lang` to pick the correct voice and pronunciation rules.
> Without it, a screen reader might read an English page with a French accent, or mispronounce words entirely.
> Accessibility matters: some of our visitors will rely on screen readers to browse the web.

#### Code style

There are several common indentation conventions:

* **2 spaces**: standard for HTML and CSS
* **4 spaces**: standard for PHP and SQL
* **tabs**: mandatory for Makefiles

Which to use is a matter of **coding style**,
a convention so hotly debated it has divided developers like Toa and Rahkshi since the time before time.

We go with 2 spaces (the HTML standard) and let a formatter enforce it automatically,
so the skeleton we just wrote and everything we add to it stays consistent.

> *🔧 Tooling*:
>
> We'll format HTML with [Prettier](https://prettier.io/): an opinionated code formatter.

Run the following to add it to the `[tools]` section of `mise.toml`:

```bash
mise use 'npm:prettier'
```

Next add the two tasks to `./mise.toml`:

```bash
cat >> ./mise.toml << 'TXT'

[tasks."cs:check"]
description = "Check coding style"
run = "prettier --check web/*.html"

[tasks."cs:fix"]
description = "Fix coding style"
run = "prettier --write web/*.html"
TXT
```

Finally, update the `app:qa` task to also run the coding style check,
so one command covers both formatting and HTML validation:

```toml
[tasks."app:qa"]
description = "Check code quality"
run = """
mise run cs:check
vnu web/*.html
"""
```

The `mise cs:fix` task will automatically fix formating errors.

Running `mise app:qa` will now catch both formatting issues and invalid HTML.

### Head

`<head>` is the invisible part of the page: it contains **metadata**,
information about the document that the browser reads but never displays.

In our skeleton it holds two children which we'll cover next (`<meta charset>` and `<title>`),
but there it can contain other elements such as `<link>`,
which indicates other remote documents to include, such as CSS files, favicon, etc.

### Meta

Inside `<head>` we define metadata with the `<meta>` void element.

The `charset` attribute declares the character encoding of the document,
setting its value with `"utf-8"` covers virtually every character from every language (including emojis),
miss it and you get `TÄhÅ« ðŸ"¥` instead of `Tāhū 🔥`.

> *📌 Important*:
>
> `<meta charset="...">` must be the very first element inside `<head>`.
> The browser needs to know the encoding before it reads anything else,
> otherwise it might misinterpret the characters in your `<title>` or other tags.

Other `<meta>` notable elements are:

* `<meta name="description" content="A fan project collecting selfies of every Bionicle set ever made.">`:
    a summary of the page, used by search engines in results
* `<meta name="author" content="Takua">`:
    the author of the page
* `<meta name="viewport" content="width=device-width, initial-scale=1">`:
    tells mobile browsers not to zoom out, essential for responsive design


### Title

```
error: Element "head" is missing a required instance of child element "title".
```

To fix that error, we need to add `<title>` element,
which sets the text displayed in the window, browser tab, bookmark and search engine results.

> **ℹ️ Note**:
>
> `<title>` is not the same as a heading on the page. It names the document itself, invisible in the page body.
> We'll add a visible heading with `<h1>` later.

### Body

`<body>` is the element that will contain the actual content of the document.

> **ℹ️ Note**:
>
> There can be only ONE `<body>` element in a HTML document.

That covers the skeleton of every HTML page you will ever write.
Whenever we need a new page, we copy it and fill in the content.

---

Let's use it now. We rewrite `./web/index.html` using the skeleton,
placing the elements we built earlier inside `<body>`:

```bash
cat > ./web/index.html << 'TXT'
<!-- File: web/index.html -->
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Selfionicle</title>
  </head>
  <body>
    <h1>Selfionicle</h1>

    <p>
      Collect selfies with every <a href="https://brickset.com/sets/theme-Bionicle">Bionicle</a> set you own.<br>
      Find the power!
    </p>

    <details>
      <summary>About</summary>
      <p>A fan project collecting selfies of every Bionicle set ever made.</p>
    </details>
  </body>
</html>
TXT
```

Visit [http://localhost:8534/](http://localhost:8534/): the page looks exactly as before,
but it is now a valid HTML document.

Running `mise app:qa` confirms it: no errors.

Let's save our progress:

```bash
git add -A
git commit -m "Built HTML skeleton and applied it to index.html"
```

> **ℹ️ Note**:
>
> You can always refer to the following documentation to learn more:
>
> * [WHATWG spec](https://html.spec.whatwg.org/):
>   the official HTML living standard, authoritative but dense
> * [MDN](https://developer.mozilla.org/en-US/docs/Web/HTML):
>   searchable practical reference, with examples and browser compatibility tables

## Content

Now that `index.html` is a valid document, let's populate it with actual content.

### Headings

We already used `<h1>` for the page title. HTML provides **six levels of headings**, from `<h1>` to `<h6>`:

```html
<h1>Selfionicle</h1>
<h2>Collection</h2>
<h3>2001: The Beginning</h3>
<h4>Toa Mata</h4>
<h5>Toa Tahu</h5>
<h6>Fire Sword</h6>
```

> **ℹ️ Note**:
>
> - `<h1>` is the top-level heading: one per page, it names the document
> - `<h2>` is a section heading
> - `<h3>`–`<h6>` are sub-section headings, each level deeper than the last
>
> _It is worth noting_: never skip levels for visual effect (e.g. jumping from `h2` to `h4`).
> Screen readers use this hierarchy to let users navigate the page by heading,
> so a broken outline breaks navigation.

### Lists

HTML has two kinds of lists. An **unordered list** (`<ul>`) is a bulleted list for items whose order does not matter:

```html
<ul>
  <li>Tahu</li>
  <li>Kopaka</li>
  <li>Gali</li>
</ul>
```

An **ordered list** (`<ol>`) is a numbered list for items whose order matters:

```html
<ol>
  <li>Find your Bionicle set</li>
  <li>Take a selfie with it</li>
  <li>Upload the photo</li>
</ol>
```

> **ℹ️ Note**:
>
> - `<ul>` is an **u**nordered **l**ist, `<ol>` is an **o**rdered **l**ist
> - `<li>` is a **l**ist **i**tem, used inside both
> - The browser numbers `<ol>` items automatically: you don't write the numbers yourself
>
> _It is worth noting_: `<li>` is a block element. Only `<li>` elements should be direct children of `<ul>` or `<ol>`.

### Link

We already met `<a>` in the Attributes section. In the context of page content,
one common pattern is opening external links in a new tab with the `target` attribute:

```html
<a href="https://brickset.com/sets/8534-1/Tahu" target="_blank">Tahu on Brickset</a>
```

> **ℹ️ Note**:
>
> - `target="_blank"` opens the link in a new browser tab
>
> _It is worth noting_: use `target="_blank"` for links that take the user away from your site,
> so they don't lose their place. For links within your own site, omit it.

### Image

Images are **void elements** embedded with `<img>`:

```html
<img src="/images/selfies/tahu.jpg" alt="Selfie with Tahu, Toa of Fire">
```

> **ℹ️ Note**:
>
> - `src` is the path or URL of the image file
> - `alt` is a text description of the image
>
> _It is worth noting_: `alt` is not optional. Screen readers read it aloud in place of the image,
> and it is displayed when the image fails to load. Describe what the image shows, not what it is
> (write `"Selfie with Tahu, Toa of Fire"`, not `"photo"` or `"image"`).

### Table

A **table** organises data into rows and columns:

```html
<table>
  <thead>
    <tr>
      <th>Set</th>
      <th>Year</th>
      <th>Element</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td>Tahu</td>
      <td>2001</td>
      <td>Fire</td>
    </tr>
    <tr>
      <td>Kopaka</td>
      <td>2001</td>
      <td>Ice</td>
    </tr>
  </tbody>
</table>
```

> **ℹ️ Note**:
>
> - `<table>` is the container
> - `<thead>` groups the header rows, `<tbody>` groups the data rows
> - `<tr>` is a **t**able **r**ow
> - `<th>` is a **t**able **h**eader cell (bold and centered by default)
> - `<td>` is a **t**able **d**ata cell
>
> _It is worth noting_: tables are for tabular data, not for layout.
> Before CSS, developers used tables to position columns and sidebars on a page.
> That was a hack: it broke screen readers and made pages hard to maintain.
> Use tables only when the data has a meaningful row-and-column relationship.

---

Let's put all of this to use. First, create the folder for our selfie images and add a few placeholders:

```bash
mkdir -p ./web/images/selfies
touch ./web/images/selfies/tahu.jpg
touch ./web/images/selfies/kopaka.jpg
touch ./web/images/selfies/gali.jpg
```

Then update `./web/index.html`:

```bash
cat > ./web/index.html << 'TXT'
<!-- File: web/index.html -->
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Selfionicle</title>
  </head>
  <body>
    <h1>Selfionicle</h1>

    <p>
      Collect selfies with every <a href="https://brickset.com/sets/theme-Bionicle">Bionicle</a> set you own.<br>
      Find the power!
    </p>

    <h2>Collection</h2>

    <h3>2001: The Beginning</h3>

    <ul>
      <li>
        <a href="https://brickset.com/sets/8534-1/Tahu" target="_blank">
          <img src="/images/selfies/tahu.jpg" alt="Selfie with Tahu, Toa of Fire">
        </a>
      </li>
      <li>
        <a href="https://brickset.com/sets/8536-1/Kopaka" target="_blank">
          <img src="/images/selfies/kopaka.jpg" alt="Selfie with Kopaka, Toa of Ice">
        </a>
      </li>
      <li>
        <a href="https://brickset.com/sets/8533-1/Gali" target="_blank">
          <img src="/images/selfies/gali.jpg" alt="Selfie with Gali, Toa of Water">
        </a>
      </li>
    </ul>

    <h2>Progress</h2>

    <table>
      <thead>
        <tr>
          <th>Set</th>
          <th>Year</th>
          <th>Selfie</th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td>Tahu</td>
          <td>2001</td>
          <td><a href="https://brickset.com/sets/8534-1/Tahu" target="_blank">view</a></td>
        </tr>
        <tr>
          <td>Kopaka</td>
          <td>2001</td>
          <td><a href="https://brickset.com/sets/8536-1/Kopaka" target="_blank">view</a></td>
        </tr>
        <tr>
          <td>Gali</td>
          <td>2001</td>
          <td><a href="https://brickset.com/sets/8533-1/Gali" target="_blank">view</a></td>
        </tr>
      </tbody>
    </table>

    <details>
      <summary>About</summary>
      <p>A fan project collecting selfies of every Bionicle set ever made.</p>
    </details>
  </body>
</html>
TXT
```

Visit [http://localhost:8534/](http://localhost:8534/) to see the updated page,
then confirm it still passes validation:

```bash
mise run app:qa
```

No errors. Let's save our progress:

```bash
git add -A
git commit -m "Added headings, lists, links, images, and tables"
```
