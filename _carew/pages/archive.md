---
title: Archive
navigations: main
---

{% for article in carew.posts|reverse %}
<article>
    <h3>
        <a href="{{ render_document_path(article) }}">{{ article.title|capitalize }}</a>
        <span class="sub-title">{{ article.metadatas.date|date('d/m/Y') }}</span>
    </h3>
    <nav>
        {% for tag in article.tags %}
        <a class="button" href="{{ path('tags/'~tag) }}">{{ tag|title }}</a>
        {% endfor %}
    </nav>
</article>
{% endfor %}
