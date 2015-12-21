[gem]: https://rubygems.org/gems/pakyow
[travis]: https://travis-ci.org/pakyow/pakyow
[gemnasium]: https://gemnasium.com/pakyow/pakyow
[inchpages]: http://inch-ci.org/github/pakyow/pakyow
[codeclimate]: https://codeclimate.com/github/pakyow/pakyow

# Pakyow Framework [![Gitter chat](https://badges.gitter.im/pakyow/chat.svg)](https://gitter.im/pakyow/chat)

Pakyow is a framework for building modern websites and web apps. Views update in
realtime to stay in sync with backend state. This is done using a traditional,
backend-driven architecture, which means business logic is written once and
stays on the server (write no JavaScript).

Pakyow is also designed with progressive enhancement in mind. Because views are
rendered on the server, they remain accessible to users who happen to be using
unsupported browsers. The realtime layer is simply disabled, while all content
continues to remain accessible.

There are three core concepts you should be familiar with:

**View-First Development**

View-First Development is a process that enables the presentation layer of a
website or web app to be built completely separate from the backend code. Read
more:

- http://pakyow.org/docs/presentation

**Simple State Propagation**

Simple State Propagation is the mechanism through which Pakyow propagates
changes in state from one client to another. It prioritizes user trust and makes
it easier to reason about your program. Read more:

- http://pakyow.org/docs/concepts/simple-state-propagation

**View Transformation Protocol**

The View Transformation Protocol is a way to represent view rendering as a set
of instructions that can later be applied to the view template. Pakyow
implements this protocol on the backend for initial rendering and in
[Ring](https://github.com/pakyow/ring) for client-side rendering. Read more:

- http://pakyow.org/docs/concepts/view-transformation-protocol

---

[![Gem Version](https://badge.fury.io/rb/pakyow.svg)][gem]
[![Build Status](https://travis-ci.org/pakyow/pakyow.svg?branch=master)][travis]
[![Dependency Status](https://gemnasium.com/pakyow/pakyow.svg)][gemnasium]
[![Inline docs](http://inch-ci.org/github/pakyow/pakyow.svg?branch=master&style=flat)][inchpages]
[![Test Coverage](https://codeclimate.com/github/pakyow/pakyow/badges/coverage.svg)][codeclimate]

---

# Getting Started

1. Install Pakyow:

    `gem install pakyow`

2. Create a new Pakyow project from the command line:

    `pakyow new webapp`

3. Move to the new directory and start the server:

    `cd webapp; pakyow server`

4. You'll find your project running at [http://localhost:3000](http://localhost:3000)!

# Next Steps

The following resources might be handy:

- [Website](http://pakyow.org)
- [Docs](http://pakyow.org/docs)
- [Code](http://github.com/pakyow/pakyow)

Want to keep up with the latest development? Follow along:

- [Blog](http://pakyow.org/blog)
- [Forums](http://forums.pakyow.org)
- [Gitter](https://gitter.im/pakyow/chat)
- [Twitter](http://twitter.com/pakyow)

# License

Pakyow is released free and open-source under the [MIT
License](http://opensource.org/licenses/MIT).
