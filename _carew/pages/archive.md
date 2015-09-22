---
title: Archive
navigations: main
---

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
            <a class="button" href="{{ path('tags/'~tag) }}">{{ tag|title }}</a>
        </li>
        {% endfor %}
    </ul>
</article>
{% endfor %}
