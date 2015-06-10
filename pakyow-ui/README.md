# PakyowUI

Modern, live-updating UIs for Pakyow apps, without moving to the client.

## Rationale

We wanted a way to build modern apps in a traditional backend-driven manner
while still reaping the benefits of modern, live updating UIs. The existing
approaches to building these modern UIs replace backend-driven architecture
rather than extending it.

Instead of replacing traditional architecture, PakyowUI provides a layer on top
of it. This allows Pakyow apps to remain accessible and fully usable in
scenarios where real-time isn't supported (e.g. in the absence of WebSockets,
JavaScript, etc).

In doing so, PakyowUI stays true to the fundamental nature of the web. It aims
to be the real-time web expressed as progressive enhancement. It allows for any
aspect of a website or web app to be updated in real-time, without any
additional work by the developer.

## Overview

At a high level, PakyowUI keeps rendered views (meaning views that are currently
presented in a browser) in sync with the current state of the data. This works
by keeping track of what views are currently rendered by a client, along with
the data used to render those views.

When the data changes, a set of transformation instructions are sent to the
proper client(s) where they are applied to reflect the new app state. The app
*does not* push re-rendered views back down to the client.

Say we have a rendered view that presents a user's name:

```html
<div data-scope="user" data-id="1">
  <h3 data-prop="name">
    Bob Dylan
  </h3>
</div>
```

When the name changes, PakyowUI builds up an instruction like this:

```ruby
[[:bind, { name: 'Thelonius Monk' }]]
```

This instruction is routed to the clients rendering User 1, where it's applied.

Predictably, the updated view reflects the new state:

```html
<div data-scope="user" data-id="1">
  <h3 data-prop="name">
    Thelonius Monk
  </h3>
</div>
```

By expressing view transformations as data, they can be applied to any view by
any interpreter; be it on the server or the client.

PakyowUI builds on the real-time library, so all of the communication between
client and server occurs over a WebSocket. If WebSockets aren't supported by the
client (or for some reason aren't working) the app will continue to work, just
without live updates. You get this for free without developing with progressive
enhancement in mind.

---

To accomplish this, view rendering must be expressed as a function of some
specific data.  The rendering itself is expressed independently of how to fetch
the data necessary to perform the render, giving PakyowUI the ability to
automatically perform the rendering again at some point in the future.

This will make more sense after the next two sections.

## Data - Mutables

PakyowUI introduces a concept called **mutables**. A mutable wraps a data model
and defines two things:

1. Actions that can occur on the model that cause state mutations.
2. Queries that define how particular data is to be fetched.

Here's how a mutable is defined:

```ruby
class User < Sequel::Model; end

Pakyow::App.mutable :user do
  model User

  action :create do |object|
    User.create(object)
  end

  query :all do
    User.all
  end

  query :find do |id|
    User[id]
  end
end
```

From a route, we can use the mutable to query for data:

```ruby
# get all the users
data(:user).all

# get a specific user
data(:user).find(1)
```

We can also change data through the mutable:

```ruby
data(:user).create(params[:user])
```

Mutables are the first step in making the route declarative (what) rather than
imperative (how). All of the *how* is wrapped up in the mutable itself, letting
us express only *what* should happen from the route. This is important.

## View - Mutators

The second concept introduced by PakyowUI is **mutators**. A mutator describes
*how* to render a particular view with some particular data.

Here's a mutator for rendering a list of users:

```ruby
Pakyow::Mutators :user do
  mutator :list do |view, users|
    view.apply(users)
  end
end
```

From a route, you could invoke the mutator on a view like this:

```ruby
view.scope(:user).mutate(:list, with: data(:user).all)
```

Notice that we're mutating with the data from our mutable user. Pakyow will
fetch the data using the `all` query and pass it to the `list` mutation where
the view is rendered.

At this point we've effectively turned view rendering into a declarative thing
from the route's point of view. We only have to describe what happens and Pakyow
takes care of the rest.

This becomes interesting when you want to subscribe the rendered view to
automatically render future changes in state. You can do this by calling
`subscribe`:

```ruby
view.scope(:user).mutate(:list, with: data(:user).all).subscribe
```

The view is rendered exactly like it was before, but now it's also subscribed to
any future state change that affects the rendered view. Let's mutate our state:

```ruby
data(:user).create(params[:user])
```

Pakyow knows that we've mutated our user state; it also knows what clients are
currently rendering user state that would be affected by this mutation. It
automatically builds up a set of instructions on how to update the rendered
state and pushes it down to those clients over a WebSocket.

Our rendered views can now keep themselves up to date with the current state of
the application; and we don't have to do anything but render the views! We don't
have to move any part of our app to the client. Our app retains a backend-driven
architecture while still behaving like a modern, live updating app.

## Client Library

PakyowUI ships with a client library called Pakyow.js, effectively bringing
Pakyow's view transformation API to the client. In addition to applying view
transformations, Pakyow.js also ships with several components, including:

- Mutation Detection: Watches user-interaction with the rendered view and can
		interpret which interactions cause a mutation in state (e.g. submitting a
		form). Once detected, the mutation is sent to the server by calling the REST
		endpoint through the open WebSocket. The mutation is then validated by the
		server, persisted (if necessary), and broadcast to all other clients.

You can use Pakyow.js to build custom front-end components that emit their own
mutations or otherwise communicate with the server through the built-in APIs.

The Pakyow.js project will be made available soon. For now, the latest build is
available [here](https://github.com/pakyow/pakyow/blob/master/pakyow-ui/pakyow.min.js).

## Channels

Pakyow keeps track of what clients receive what mutations with channels. Here's
how a channel is structured:

  scope:{name};mutation{name}::{qualifiers}

In the example from the Mutators section, the subscribed channel name is:

  scope:user;mutation:list

This means that any client who rendered any user data with the `list` mutation
will receive future updates in user state. Read the next section to understand
how to better control this.

## Qualifiers

You might be curious about how to exercise fine-grained control over clients and
the mutations they receive. PakyowUI handles this with *qualifiers*.

For example, if you only wanted a particular user to be subscribed:

```ruby
view.scope(:user).mutate(:list, with: data(:user).all).subscribe({
  user_id: current_user.id
})
```

The `user_id` qualifier is added to the channel name, so when mutations occur in
the future the result will only be pushed down to that particular client. Here's
the subscribed channel name:

  scope:user;mutation:present::user_id:1

You can also qualify mutators. Here's how you would express that you want a
particular user's mutations to be sent only to clients that render that state:

```ruby
Pakyow::Mutators :user do
  mutator :present, qualify: [:id] do |view, user|
    view.bind(user)
  end
end

view.scope(:user).mutate(:present, with: data(:user).find(1)).subscribe
```

The value for the qualifier will be pulled from the user's id and added to the
channel name. Now only client's who currently render the user with id of 1 will
receive future state changes about that user. Here's the subscribed channel
name:

  scope:user;mutation:present::id:1
