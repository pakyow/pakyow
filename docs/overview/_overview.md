---
name: Why Pakyow?
desc: 
---

Pakyow is a framework for building modern apps that embrace the web.

Users of the modern web prefer interactive experiences over static content.
Currently, you can follow either a hybrid or full client-side approach to create
such an experience.

In a hybrid app, business logic exists both on the server and the client. The
server handles initial rendering and global state changes, while the client
manages its own local state and renders updates without needing a full page
reload.

Hybrid apps are complex and hard to build.

Client-side apps are simpler to build but are at odds with the architecture of
the web. In his essay, [The World Wide Web: A very short personal
history](https://www.w3.org/People/Berners-Lee/ShortHistory.html), Tim
Berners-Lee states:

> The dream behind the Web is of a common information space in which we
communicate by sharing information. Its universality is essential: the fact that
a hypertext link can point to anything, be it personal, local or global, be it
draft or highly polished.

In today's web, a url often points at *nothing*. Rather than responding with the
requested document, the server instead responds with JavaScript that (hopefully)
renders the requested document. **This model breaks the web.**

Pakyow is architected to embrace the web and still provide modern features that
create an interactive user experience. Conceptually, it falls somewhere between
a traditional framework (e.g. Ruby on Rails) and a modern, client-side framework
(e.g.  Ember.js).

With Pakyow, app code is written in Ruby and initial rendering occurs on the
server. Once a page is rendered in the browser, Pakyow automatically keeps it in sync with the
latest app state. It does this without moving any code to the client.

Pakyow is a natural step forward from a traditional framework. It's simply a
layer on top of the server-driven architecture that has powered the web for
decades. We say it's the realtime web implemented as a progressive enhancement.
