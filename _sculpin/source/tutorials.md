---
layout: page
title: "Build Your Website, From Scratch"
use:
    - tutorials
---

Ever wondered how to create your own website, with your own hands?

That's exactly what we're going to learn here, with step-by-step tutorials,
each building on the previous one.

This is aimed at complete beginners and since practice makes better,
we'll build Selfionicle: a website to collect selfies with your [Bionicle](https://en.wikipedia.org/wiki/Bionicle) sets!

> *Note*:
>
> Bionicle was a LEGO theme featuring biomechanical heroes and villains.
> The goal of our website: take a selfie with every set you own, and collect them all!

<ul>
    {% for tutorial in data.tutorials %}
    <li><a href="{{ site.url }}{{ tutorial.url }}">{{ tutorial.title }}</a></li>
    {% endfor %}
</ul>
