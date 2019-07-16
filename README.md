# <img src="https://pakyow.com/marketing/logo.svg" height="42" alt="Pakyow">

**Hello, Web.** Pakyow is a web framework that helps you turn your html into a complete web app. We set out to design a better way to build for the web. This is the result&mdash;a full stack of open-source frameworks that offers a simpler, design-first approach. We want to help you do more with what you already know, whether you're just starting out or have been building for the web for years.

Here's how it works:

1. Prototype: Create an in-browser prototype without writing any backend code. Use composable, plain-html view templates to define how your app looks and behaves, then sprinkle data bindings on top to describe the semantic intent behind your interface.

2. Reflect: While you prototype, Pakyow reflects on your views to bootstrap a complete backend to make your interface work—including routes, data models, presenters, and more. The reflection integrates seamlessly with your frontend, giving you a solid foundation to continue building on.

3. Iterate: With the boilerplate taken care of, focus on building what makes your app unique. Any custom code you add runs right alongside the reflection, giving you flexibility where you need it and a secure, standards-based fallback for everything else.

This is what a Pakyow view template looks like:

```html
<form binding="message">
  <input binding="content" type="text">
  <input type="submit">
</form>

<article binding="message">
  <p binding="content">
    content goes here
  </p>
</article>

<p binding="message" version="empty">
  nothing here yet
</p>
```

Pakyow can attach quite a bit of default behavior to an app just based on this template.

* [Get an overview in the 5-minute app guide &rarr;](https://pakyow.com/docs/hello/example)

## Designed for the designers.

Pakyow lets designers play an active part in building the things they design. Interfaces are built right in the web browser using HTML and CSS, and then extended to become a complete application.

## Live views without breaking a sweat.

Pakyow UIs stay in sync with server-side state right out of the box. There's nothing new to learn and no frontend framework to adopt. The UI is rendered on the server like in a traditional stack, but once presented in a browser it automatically reflects new changes without a page refresh.

## Backed by a complete framework.

Pakyow includes everything you need to create a complete web app or website. The core primitives that Pakyow uses internally are available to you as you need them. Pakyow's backend, built on Ruby, is designed to make custom code fun to write and easier to maintain long term.

## Responsibly Open-Source

Pakyow is released free and open-source under the terms of the LGPLv3 license. We offer paid team subscriptions that remove some of the restrictions of the LGPL. Team subscriptions also include access to expert help for you and your team through a private support channel.

Giving Pakyow away for free and charging for the extra bits on top lets us embrace the open-source ethos in a responsible and sustainable way. Pakyow is our full-time job&mdash;we're in this for the long haul.

* [Learn more about subscriptions &rarr;](https://pakyow.com/pricing/)

## Getting Help

Have a question about Pakyow? Connect with other users in the [community](https://pakyow.com/community/). Encountered a bug? Report it on the [issue tracker](https://github.com/pakyow/pakyow/issues/) and we'll hep you out. Find a security concern? **Don't report it publicly. Email security@pakyow.com and we'll work with you to confirm the issue, establish a fix, and release a patch.**

## Technical Overview

Pakyow apps run almost entirely on the server side, with a minimal client-side framework to support things like live view updates and components. Everything on the server is written in [Ruby](https://www.ruby-lang.org/), a beautifully designed programming language optimized for the happiness of beginners and experienced developers alike!

Pakyow is implemented across several independent frameworks, each released as its own gem. This modularity lets us provide a helpful set of default behavior while providing flexibility for advanced users to decide what behavior they want to run in their projects. Pakyow's default set of frameworks can be found in the `pakyow/pakyow` repository:

* Routing: Controllers, Input Verification, and Error Handling
* Presenter: View Composition, Data Presentation
* Assets: Compiling Styles, JavaScript, and Images
* Realtime: Pub/Sub Channels via WebSockets
* UI: Server-Side Integration with Web Browsers
* JS: Client-Side Presentation, UI Components
* Data: Persistence Layer, Query Subscriptions
* Mailer: Sending Email, Delivering Views
* Forms: Rendering Forms, Processing Submissions
* Reflection: Generates View Reflections
* Support: Supporting Code, Utilities

Foundational concepts used across frameworks are defined in the main `pakyow-core` gem, including:

**Environment:** The master process that runs one or more mounted apps. Most of the time you'll be mounting an instance of `Pakyow::App`, however you can mount any object that responds to `call`. Note that the environment is the only global object that exists in the framework.

* [Read more about environment &rarr;](https://github.com/pakyow/pakyow/blob/master/pakyow-core/lib/pakyow/environment.rb)

**Application:** An endpoint mounted at a specific path within the environment. Each application defines various aspects, including controllers, presenters, and data sources. These aspects are used to fulfill requests that the environment directs to the application.

* [Read more about application &rarr;](https://github.com/pakyow/pakyow/blob/master/pakyow-core/lib/pakyow/application.rb)

**Connection:** Contains all of the knowledge about the current request lifecycle, including headers, body, status, etc. It also contains a key/value store for passing request state between frameworks. The environment has a connection object used for every request. When the connection is directed to an application, the application can wrap the environment connection with its own behavior.

* [Read more about connection &rarr;](https://github.com/pakyow/pakyow/blob/master/pakyow-core/lib/pakyow/connection.rb)

---

There's a lot more to the main gem, including process management for development environments, configuration, and integrations. We encourage you to walk through the code yourself--it's a great way to learn!

* [Browse the code &rarr;](https://github.com/pakyow/pakyow/tree/master/lib/pakyow)

You might also be interested in `pakyow/design`, which applies design-first principles to the design of the framework itself. It's a great way to see how all of the features in a Pakyow app work together.

* [Browse pakyow/design &rarr;](https://github.com/pakyow/design)

## Common Patterns

You'll find several implementation patterns throughout the codebase, including:

### Pipelines

Pipelines allow one or more actions to be defined and then called in order. Each action can modify the state and/or halt execution of the pipeline, at which point the final state is returned. This pattern makes it much easier to understand the path a request takes through the system. For example, Pakyow::Controller is implemented using pipelines.

* [Read more about pipelines &rarr;](https://github.com/pakyow/pakyow/blob/master/pakyow-support/lib/pakyow/support/pipelined.rb)

### Behavior Extensions

Throughout the framework you'll find extension modules in a `behavior` directory. When included, each behavior module extends the including object with its defined behavior. This pattern lets us isolate complex behavior and use composition to define how a particular object in the system should behave. For example, `Pakyow::App` includes several behavior extensions, such as [error handling](https://github.com/pakyow/pakyow/blob/master/pakyow-core/lib/pakyow/core/controller/behavior/error_handling.rb).

* [Read more about extensions &rarr;](https://github.com/pakyow/pakyow/blob/master/pakyow-support/lib/pakyow/support/extension.rb)
