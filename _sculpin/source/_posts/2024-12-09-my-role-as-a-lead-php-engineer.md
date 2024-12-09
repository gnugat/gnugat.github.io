---
layout: post
title: My role as a Lead PHP Engineer
tags:
    - lead developer
---

## About me

In September 2014, I left SensioLabs (the creator of the Symfony Framework)
to work as a PHP/Symfony Developer at Foodity, a London start-up that created
a service allowing people to add ingredients from online recipes to the basket
of the retailer of their choice.

After 9 months, I pitched an idea to the CEO: we had a platform that
theoretically allowed us to add _ANY_ product to the basket, not just food
items. We called it Smart Product.

So I was given the opportunity to build a Proof of Concept. Once completed and
launched it proved successful and was promoted "Lead PHP Engineer" in charge
of a small team to develop it further.

And so in June 2015, Foodity pivoted and became Constant Commerce, with Smart
Product being one of its main product.

Later, in August 2018, the start-up pivoted again and became Constant.Co: my
team and I were given the responsibility to design and develop the API for its
new main product: Landing Space.

This article is about my role as a Lead PHP Engineer during that time, and what
my job and responsibilities were about, on a day to day basis.

## Responsibilities

As a lead developer, my responsibilities were:

* Develop the different endpoints using PHP, Symfony and PostgreSQL
* Lead, mentor, and manage a team of backend developers (junior and senior)
* Ensure code quality, maintainability, and best practices through
  code reviews, testing (TDD), and continuous integration processes
* Oversee the design, development and deployment of the backend APIs
* Collaborate with cross-functional teams, including Sales, Product,
  Frontend, Other API teams, QA, Content and DevOps

## Agile Methodology

The company as a whole would work through Cycles: each Cycle is 6 week long,
and contains 3 sprints (2 week sprints).

Prior to the Cycle (ie during the previous cycle), the CEO, Sales and Product
would flesh out a milestone to achieve. Meetings between the CEO, Sales,
Product, Technical Leads and QA would be held to identify the user stories and
their acceptance criteria.

As a Lead Developer, my role in this meeting was to assess the feasibility of
the features described, evaluate how the new requirements would affect the
existing code base (ie is this already implemented, management of the technical
debt, etc) and provide technical guidance.

Architecture meetings between Product, Technical Leads and QA would be held to
write technical specifications.

As a Lead Developer, my role in this meeting was to collaborate with other
teams on how to best integrate the different systems, document the
requirements, identify and resolve performance bottlenecks, security
vulnerabilities, and other technical issues.

When the Cycle starts, so does the first Sprint: a Sprint Planning meeting is
held between Product, the technical teams and QA, where User Stories are picked
from the backlog and given an estimated Complexity Points, and assigned to
developers. Once the Team Capacity is reached, based on previous Velocity, then
the development can start.

## Test Driven Development

I'd start by picking a ticket and moving it to "In Progress".

I'd then write an integration test that fits to one of the User Story's
Acceptance Criteria. Usually the first test is about a "Happy Scenario": what
we expect. following tests would be about "Unhappy Scenario" and trying to
identify edge cases. Then run them to make sure they fails for the right
reasons (ie because the code isn't written yet).

Next I'd write a unit test. Run it to make sure it fails for the right reason.

After that I'd write the code for that test. And run the test suite to make
sure it fulfils the new requirements without breaking the previous ones.

Once the tests pass, I can add new scenarios to my test suite, and start
the process again, until everything is covered, and only then I'd also consider
refactoring the code to ensure the maintainability of the project.

Finally, I can commit my work with a detailed message, push, create a
Pull Request and assign it to someone for Code Review.

The ticket can now be moved to "Code Review".

I take this opportunity to check if there are any open Pull Requests waiting
for me to review them.

## Code Review

First thing I do when reviewing a Pull Request is check the corresponding
ticket to get familiar with the problem that it tries to solve.

I'd then pull the code to my local machine, execute the test suite and
launch the application to navigate it and try the feature first hand.

Next, I have a look at the code, with the objective to answer these three
questions:

- does the code work?
- does the code make sense?
- does the code meet the standards?

The purpose of Code Reviews isn't to nitpick or force what you'd have done
instead, but to help your co-worker:

- spot errors early
- spread the knowledge across the team
- have an opportunity for both of you to learn and improve

There are two kinds of feedback that can be left:

- change request, which need to happen in order for the Pull Request to be
  accepted (something is broken)
- suggestions that can optionally be taken into account, 

Once the feedback from the first round has been taken into account, other
rounds of Code Reviews can be done, but to get the feature deployed as early
as possible it's important to focus these on identifying broken things and
fixing them (rather than making more suggestions for improvements).

Finally, when the Pull Request is accepted, it can be merged and sent to QA.

## Mentoring

As a Lead Developer, one of my responsibility is the mentoring of team members.

One aspect of this was the preparation and delivery of training (Symfony, Git,
Test Driven Development), but I'd also give (and encourage others to give) some
presentations or lightning talks on different topics (libraries, practices,
etc).

But one of my favourite tool was Pair Programming, which proved quite efficient
when on boarding the junior developer. These would be short sessions, rather
than whole days spent together, and we'd follow a strict Driver-Navigator rule
(ie the one with keyboard only writes what they agree to, while the other one
explains the vision) with regular switching at first, and then on task as we
became more synchronised.
