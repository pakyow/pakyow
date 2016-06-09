---
name: Testing
desc: Writing tests for routing, views, and realtime.
---

Testing is an important part of any software development process, including
building a Pakyow project. To support our testing efforts, Pakyow ships with
`pakyow-test`, a library containing support code and helpers that make it easier
to write tests against a codebase.

Pakyow also provides the ability to easily write tests for the presentation
layer of a project, something that is typically very difficult in web-based
frameworks. These presentation tests make it possible to know exactly what views
are being presented, along with the specific data being presented by each view.

> [RSpec](https://github.com/rspec/rspec) is the testing library we recommend for
use in Pakyow projects. It's also what all of the internal Pakyow framework
tests are written in. For detailed instructions on setting things up or using a
different testing library, [click
here](https://github.com/pakyow/pakyow/tree/master/pakyow-test).

When you generate a new project, it's already setup for testing using RSpec. In
fact, there are already two passing tests that were written for us! Run `bundle
exec rspec` at the root of the project.

```
Pakyow::App
  when navigating to the default route
    says hello
    succeeds

Finished in 0.0051 seconds (files took 0.60646 seconds to load)
2 examples, 0 failures

Randomized with seed 9653
```

Take a look at the two specs in `spec/integration/app_spec.rb`.

## Organizing Tests

There are two folders in the `spec` folder of a generated project: integration
and unit. Tests that exercise large parts of the application, like routing,
belong in the `spec/integration` folder. True unit tests, or tests that tend to
isolate and test a small unit of code, go in the `spec/unit` folder.

> A good rule of thumb: if your test uses the simulator (described below), it
belongs in the `spec/integration` folder.

## App Simulation

Most of the test helpers in pakyow-test are part of `TestHelp::Simulation`. It
processes mock requests, just like a running app would, and keeps track of
everything that happens so that tests can be written against the results.

Here's an example simulation:

```ruby
get '/' do |sim|
  expect(sim.status).to eq(200)
end
```

We'll take a look at more simulation examples in the following sections.
