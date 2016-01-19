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
            {% set tag_class = '' %}
            {% if tag == 'deprecated' %}
                {% set tag_class = 'button-deprecated' %}
            {% endif %}
            {% if tag == 'reference' %}
                {% set tag_class = 'button-reference' %}
            {% endif %}
            <a class="button {{ tag_class }}" href="{{ site.url }}/tags/{{ tag|url_encode(true) }}">{{ tag }}</a>
            {% endfor %}
        </nav>
    </article>
{% endfor %}
