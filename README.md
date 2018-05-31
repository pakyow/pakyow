[gem]: https://rubygems.org/gems/pakyow
[travis]: https://travis-ci.org/pakyow/pakyow

# Pakyow Web Framework [![Gitter chat](https://badges.gitter.im/pakyow/chat.svg)](https://gitter.im/pakyow/chat)

*Build modern web applications that don't break the web.*

Pakyow is a Ruby web framework that lets you create fantastic experiences for your users
without writing any client-side code. Build modern server-driven applications that don't
compromise on speed or usability.

## Realtime UIs

Pakyow automatically keeps your presentation layer in sync with state of the server.
Works out of the box.

## Quick & Easy Prototypes

Create a working prototype of your project with plain HTML. Later, build right on
top of the prototype without throwing it out.

## Build a Friendlier Web

We think that a simpler web leads to a democratic web. Pakyow optimizes for
simplicity, making it easier to start and leading to long-term productivity.

---

[![Gem Version](https://badge.fury.io/rb/pakyow.svg)][gem]
[![Build Status](https://travis-ci.org/pakyow/pakyow.svg?branch=master)][travis]

---

# Getting Started

1. Install Pakyow:

    `gem install pakyow`

2. Create a new Pakyow project from the command line:

    `pakyow new webapp`

3. Move to the new directory and start the server:

    `cd webapp; bundle exec pakyow server`

4. You'll find your project running at [http://localhost:3000](http://localhost:3000)!

# Next Steps

- [Read the overview](https://pakyow.org/docs/overview) to better understand the goals and architecture of Pakyow.
- [Follow the warmup](https://pakyow.org/docs/warmup) to build and deploy your first project.
- [Browse the docs](https://pakyow.org/docs) to learn more about presentation, routing, realtime channels, and more.
- [Check out the code](https://github.com/pakyow/pakyow) on Github.

We'd love to have you involved. Here are a few places to start:

- [Give us a star](https://github.com/pakyow/pakyow)
- [Participate in chat](https://gitter.im/pakyow/chat)
- [Join the forums](http://forums.pakyow.org/)
- [Work on a starter issue](https://github.com/pakyow/pakyow/labels/Starter)
- [Report problems](https://github.com/pakyow/pakyow/issues)
- [Tell your friends](https://twitter.com/share?text=Pakyow,%20build%20modern%20apps%20that%20don%27t%20break%20the%20web&hashtags=pakyow&url=https://pakyow.org)

# License

Pakyow is free and open-source under the [LGPLv3 license](https://choosealicense.com/licenses/lgpl-3.0/).

# Overview

*[Read the docs](https://www.pakyow.org/docs) if you want the full skinny.*

Pakyow is designed to be modular, with each library handling one aspect of the
framework. Here's a list of the libraries that Pakyow ships with by default:

- Core: Introduces the app object. Routes requests to endpoints within an app.
- Presenter: Handles logicless view presentation, including data binding.
- Mailer: Delivers logicless views over email, rather than http.
- Realtime: Adds WebSocket support and realtime channels.
- UI: Automatically keeps rendered views in sync with server-side state.
- Test: Provides helpers that make it easy to test various aspects of an app.
- Support: Provides helpers used throughout the framework.
- Rake: Adds several tasks that are useful alongside an app.

There are many secondary libraries that add additional functionality, including:

- Markdown: Adds support for writing view templates in Markdown.
- Slim: Adds support for writing view templates in Slim.
- Haml: Adds support for writing view templates in Haml.
- Bindr: Introduces the concept of recursive data binding.

It's standard that every Pakyow-related library is prefixed with `pakyow-*`.

---

The primary library (named simply `pakyow`) handles concerns shared across the
Pakyow ecosystem. It glues everything together. Read below for a summary.

## Environment

Makes it possible to run multiple Rack-compatible endpoints (including Pakyow
apps) with the consistency of a single environment.

[Browse the source &raquo;](https://github.com/pakyow/pakyow/blob/environment/lib/pakyow/environment.rb)

## Request Logger

Adds request-level logging, with a human-friendly formatter for development and
a logfmt formatter for production environments.

[Browse the source &raquo;](https://github.com/pakyow/pakyow/blob/environment/lib/pakyow/logger/request_logger.rb)

## Default Middleware

Introduces a default middleware stack for all apps within the environment,
including request path normalization and json body parsing.

[Browse the source &raquo;](https://github.com/pakyow/pakyow/blob/environment/lib/pakyow/environment.rb#L145)

## App Template

Ships with the default template for generated Pakyow apps.

[Browse the source &raquo;](https://github.com/pakyow/pakyow/tree/environment/lib/generators/pakyow/app/templates)

## Command Line Interface (CLI)

Adds a CLI for creating Pakyow apps and running the environment.

[Browse the source &raquo;](https://github.com/pakyow/pakyow/blob/environment/lib/pakyow/cli.r://github.com/pakyow/pakyow/blob/environment/lib/pakyow/cli.rb)

# Official Documentation

The official documentation can be found
[here](https://github.com/pakyow/pakyow/tree/environment/docs). We bundle the
docs with the code so that they evolve together.

# Canonical Example

The canonical example for Pakyow can be found
[here](https://github.com/pakyow/pakyow/tree/environment/example). We try and
keep it current to reflect the entire feature-set across the framework.
