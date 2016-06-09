---
name: Progressive Enhancement
desc: Pakyow embraces the web through progressive enhancement.
---

Progressive enhancement is a bit of a loaded term. Today we tend to think of it
as making things work without JavaScript, but this is a simplistic definition.
At its core, progressive enhancement is about architecting a website or web app
in a way that guarantees it will serve its intended purpose.

Progressive enhancement has also influenced the way that the web has changed
over the years. Every step forward has been in context of existing architecture
and prior decisions.

Following this pattern, Pakyow adds features like auto-updating views as an
enhancement on top of the server-driven architecture that's powered the web for
decades.

Here's a rundown of how it works.

When a request is made, the initial page is rendered on the server, just like it
would be in a framework like Ruby on Rails. Once the page is rendered, a
JavaScript library (Ring.js) boots up and connects back to the server. When a
state change occurs, Pakyow tells each client how to update itself to reflect
the new state of the app.

Anything after the initial page load can fail without having too large of an
impact on the user. While it's true that views will no longer auto-update, the
user can still read the document and/or navigate to another location.

This way of doing auto-updating views is a more natural evolution for the
modern web.

Others have done a fantastic job talking in-depth about progressive enhancement.
If you would like to learn more about it, here's some recommended content:

- [Stumbling on the Escalator](https://www.christianheilmann.com/2012/02/16/stumbling-on-the-escalator/)
- [Understanding Progressive Enhancement](http://alistapart.com/article/understandingprogressiveenhancement)
- [Be Progressive](https://www.youtube.com/watch?v=-yIbKaA3wCo&feature=youtu.be)
