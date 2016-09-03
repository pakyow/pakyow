---
name: Failure Handling
desc: Handle failures in a Pakyow app.
guide: true
---

Pakyow Fail is a plugin that adds automatic failure handling to a Pakyow app.

It defines default views for 404 and 500 error pages. You can easily override these default views by creating `404.html` and `500.html` pages in the root view directory of your app.

Failure handlers are also made available, which can do any number of things when a failure happens. More information about handlers is available in the [readme](https://github.com/metabahn/pakyow-fail#handlers).

## Installation

Add `pakyow-fail` to your `Gemfile`:

```ruby
gem "pakyow-fail"
```

Next, add the following code to your routes file:

```ruby
include Fail::Routes
```

That's it!
