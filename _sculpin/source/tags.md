---
layout: page
title: Tags
use:
    - posts_tags
---

<nav>
    {% for tag,posts in data.posts_tags %}
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
