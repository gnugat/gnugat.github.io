---
title: Technical and Practices advices
---

Welcome to my blog! My name is Loïc Chardonnet
({{ link('pages/about-me.md', 'learn more about me') }}), and I'll be talking
about technical and practices advices.

Find articles which might interest you using{{ link('tags', ' the tags') }} or
simply by scrolling trough the following list.

{{ render_documents(paginate(carew.posts|reverse)) }}
