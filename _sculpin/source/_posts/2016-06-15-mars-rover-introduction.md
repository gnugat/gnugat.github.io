---
layout: post
title: Mars Rover, Introduction
tags:
    - mars rover
---

Welcome to this Mars Rover series where we're going to practice the followings:

* Monolithic Repositories (MonoRepo)
* Command / Query Responsibility Segregation (CQRS)
* Event Sourcing (ES)
* Test Driven Development (TDD)

In this introductory article, we're simply going to describe our Mars Rover
specifications.

> **Note**: This programming exercise originally comes from
> [Dallas Hack Club](http://dallashackclub.com/rover), which is now
> unfortunately down.
>
> This Mars Rover [kata](https://en.wikipedia.org/wiki/Kata_(programming))
> has been adapted for the needs of this series.

## Specifications

The purpose of this series is to create the software of a Mars Rover, according
to the following specifications.

Mars Rovers need first to be landed at a given position. A position is composed
of coordinates (`x` and `y`, which are both integers) and an orientation
(a string being one of `north`, `east`, `west` or `south`).

It is then possible to drive them, using instructions such as `move_forward`
(keeps orientation, but moves along the `x` or `y` axis) or
`turn_left` / `turn_right` (keeps the same coordinates, but changes the
orientation).

From time to time, they'll be requested to give their current location
(again, `x` and `y` coordinates and the orientation).

For example, a rover can be landed at `23`, `42`, `north` and then can be
instructed to move forward twice, then to turn left, then to move forward once.
When requested to, it should provide this location: `22`, `44`, `west`.

## What's next

In the next article we'll see what MonoRepo is, by setting up our project
(using PHP 7, git and [Composer](https://getcomposer.org)) and creating
sub-packages.

