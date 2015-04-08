---
title: Loïc's blog
---

<a class="btn btn-default" href="http://gnugat.github.io/feed/atom.xml" role="button">RSS</a>
<a class="btn btn-default" href="https://github.com/gnugat/gnugat.github.io" role="button">Sources</a>

<div class="homepage">
    {% for article in carew.posts|reverse %}
    <article class="article">
        <h2 class="title">
            <a href="{{ render_document_path(article) }}" class="link">
                {{ article.title|capitalize }}
            </a>
        </h2>
        <ul class="list-inline">
            <li>
                {{ article.metadatas.date|date('d/m/Y') }}
            </li>
            {% for tag in article.tags %}
            <li>
                <a href="{{ path('tags/'~tag) }}"><span class="label label-primary">{{ tag|title }}</span></a>
            </li>
            {% endfor %}
        </ul>
    </article>
    {% endfor %}
</div>
