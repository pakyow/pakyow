# PakyowUI

Modern, live-updating UIs for Pakyow apps, without moving to the client.

## Rationale

We wanted a way to build modern apps in a traditional backend-driven
manner while still reaping the benefits of modern, live updating
UIs. The existing approaches to building live UIs tend to *replace*
backend-driven architecture rather than *extend* it.

Instead of replacing traditional architecture, PakyowUI adds a layer
on top of it. This allows Pakyow apps to have live UIs out of the box
without any additional work by the developer, while remaining accessible
and fully usable in the absence of WebSockets, JavaScript, etc.

The PakyowUI approach stays true to the fundamental nature of the web.
It aims to be the real-time web expressed as progressive enhancement.
It allows for any aspect of a website or web app to be updated in
real-time, without any additional work by the developer.

## Overview

At a high level, PakyowUI keeps rendered views (meaning views that
are currently rendered by a client in the browser) in sync with the
current state of the data.

During the initial request/response cycle, Pakyow keeps track of what
view is rendered and sent back to the client, along with the underlying
data used to render those views.

When the data changes in the future, a set of transformation
instructions are sent to the client(s) who possess views with that
data. The transformations are then applied to the existing views by a
JavaScript client library so that the view not reflects the current
app state. The app *does not* push re-rendered views back down to the
client, nor does any JavaScript transcompilation occur.

---

Let's look at an example. Say during the initial request/response cycle
Pakyow rendered a view that presents a user's name:

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

This instruction is routed to the client(s) that present a view
containing data for user 1. Once received, the intructions are applied.

Predictably, the updated view reflects the new state:

```html
<div data-scope="user" data-id="1">
  <h3 data-prop="name">
    Thelonius Monk
  </h3>
</div>
```

PakyowUI builds on the [pakyow-realtime
library](https://github.com/pakyow/pakyow/tree/master/pakyow-realtime),
so all of the communication between client and server occurs over a
WebSocket. If WebSockets aren't supported by the client (or for some
reason aren't working) the app will continue to work, just without live
updates. You get this graceful degradation for free without developing
with progressive enhancement in mind.

---

By expressing view transformations as data, they can be applied to
any view by any interpreter; be it on the server or the client. To
accomplish this, view rendering must be expressed separately from
the view and in context of the data being presented by the view. The
rendering itself also is expressed independently of how to fetch
the data necessary to perform the render, giving PakyowUI all the
information it needs to automatically perform the rendering again at
some point in the future.

## Data - Mutables

PakyowUI introduces a concept called **mutables**. A mutable wraps a
data model and defines two things:

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

Mutables are the first step in making the route declarative (what)
rather than imperative (how). All of the *how* is wrapped up in the
mutable itself, letting us express only *what* should happen from the
route. This is important.

## View - Mutators

The second concept introduced by PakyowUI is **mutators**. A mutator
describes *how* to render a particular view with some particular data.

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

Notice that we're mutating with the data from our mutable user. Pakyow
will fetch the data using the `all` query and pass it to the `list`
mutation where the view is rendered.

***NOTE:*** One important caveat here is that the individual data
passed to the mutate method needs to respond to the `to_hash` method,
which should return a hash of all relevant attributes. E.g. For
ActiveRecord models could define `to_hash` like this:

```
class User < ActiveRecord::Base
  def to_hash
    attributes
  end
end
```

At this point we've effectively turned view rendering into a declarative
action from the route's point of view. We only have to describe *what*
we want to happen and Pakyow takes care of the rest.

This becomes useful when you want to subscribe the mutation to future
changes in state. You can do this by calling `subscribe`:

```ruby
view.scope(:user).mutate(:list, with: data(:user).all).subscribe
```

The view is rendered in the intial request/response cycle exactly like
it was before, but now it's also subscribed to any future state change
that affects the rendered view.

Let's mutate our state:

```ruby
data(:user).create(params[:user])
```

Pakyow knows that we've mutated our user state; it also knows what
clients are currently rendering the mutated user state. It automatically
pushes down instructions over a WebSocket describing how the client
should update their view to match the current state.

Our rendered views now keep themselves up to date with the current state
of the application; and we as the developer don't have to do anything
but write the initial rendering code! We don't have to move any part of
our app to the client. Our app retains a backend-driven architecture
while still behaving like a modern app with live updates.

## Client Library

PakyowUI ships with a client library called Pakyow.js, effectively
bringing Pakyow's view transformation API to the client. In addition
to applying view transformations, Pakyow.js also ships with several
components, including:

- Mutation Detection: Watches user-interaction with the rendered view and can
		interpret which interactions cause a mutation in state (e.g. submitting a
		form). Once detected, the mutation is sent to the server by calling the REST
		endpoint through the open WebSocket. The mutation is then validated by the
		server, persisted (if necessary), and broadcast to all other clients.

You can use Pakyow.js to build custom front-end components that emit
their own mutations or otherwise communicate with your app's HTTP routes
over a WebSocket.

The Pakyow.js project is [available here](http://github.com/pakyow/pakyow-js).

## Channels

Pakyow keeps track of what clients should receive what state mutations
with channels. Here's how a channel is structured:

    scope:{name};mutation{name}::{qualifiers}

In the example from the Mutators section, the subscribed channel name is:

    scope:user;mutation:list

This means that any client who rendered any user data with the `list`
mutation will receive future updates in user state. Read the next
section to understand how to better control this.

## Qualifiers

You might be curious about how to exercise fine-grained control over
clients and the mutations they receive. PakyowUI handles this with
*qualifiers*.

For example, you can subscribe a view to only update with the current
user's data:

```ruby
view.scope(:user).mutate(:list, with: 
	data(:user).for_user(current_user)).subscribe({
  user_id: current_user.id
})
```

The `user_id` qualifier is added to the channel name, so when future
mutations occur, the result will only be pushed down to that particular
client. Here's the subscribed channel name:

    scope:user;mutation:present::user_id:1

You can also qualify mutators. Here's how you would express that you
want a particular user's mutations to be sent only to clients that
render that state:

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
