---
layout: page
title: Tags
use:
    - posts_tags
---

<nav>
    {% for tag,posts in data.posts_tags %}
    <a class="button {{ tag == 'deprecated' ? 'button-deprecated' }}" href="{{ site.url }}/tags/{{ tag|url_encode(true) }}">{{ tag }}</a>
    {% endfor %}
</nav>
