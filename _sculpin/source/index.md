---
layout: page
title: Articles
use:
    - posts
---
{% for post in data.posts %}
    <article>
        <h3>
            <a href="{{ site.url }}{{ post.url }}">{{ post.title|capitalize }}</a>
            <span class="sub-title">{{ post.date | date('d/m/Y') }}</span>
        </h3>
        <nav>
            {% for tag in post.meta.tags %}
            <a class="button {{ tag == 'deprecated' ? 'button-deprecated' }}" href="{{ site.url }}/tags/{{ tag|url_encode(true) }}">{{ tag }}</a>
            {% endfor %}
        </nav>
    </article>
{% endfor %}
