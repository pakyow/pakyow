---
name: Auto-Updating Views
desc: Building views that update themselves.
---

Pakyow UI brings live updating views to applications. Live updating means that a
view presenting data in a browser will update automatically anytime the data
changes. This allows us to *extend* traditional backend-driven architecture
rather than attempting to *replace* it by moving logic to the client.

Say an application has a view that presents a message.

```html
<div data-scope="user" data-id="1">
  <span data-prop="name">
    Bob Dylan
  </span>
</div>
```

This message is currently being viewed by multiple users. At some point, the
`name` for `user:1` changes to `Thelonius Monk`. Every user will see the new
value instantly, without refreshing their page. All of this works out of the box
without writing a single line of JavaScript.

So, how does it work?

Pakyow UI keeps track of every presented view along with the data that each view
presents. When the data changes, a message is pushed to each client containing
instructions for how to update its view to match the new state. Pakyow UI is
built on top of the pakyow-realtime library, so all communication between client
and server occurs over a WebSocket.

Because of how Pakyow separates the structure of a view from the logic of
rendering it, we can send instructions and let the client perform the updates.
The view is not re-rendered on the server and pushed to clients. This carries
with it the benefit of *not removing existing nodes from the DOM*, simplifying
things like event handlers.

## Progressive Enhancement

Unlike most client-side frameworks, applications using Pakyow UI degrade
gracefully in situations where JavaScript and/or WebSockets is unsupported or
unavailable. In these cases, the application will continue to function, just
without live updates. The user experience may suffer, but at least it works.
This is the heart of progressive enhancement.

## Mutables

Pakyow UI introduces a concept called **mutables**. A mutable is responsible for
defining *actions* and *queries* that describe interactions with a data model:

1. Actions occur on the model and cause mutations in application state.
2. Queries describe how particular datasets will  be fetched from the model.

Here's an example mutable for the `User` model in the above use-case:

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

And we can change application state through the mutable as well:

```ruby
data(:user).create(params[:user])
```

Mutables allow routes to access data in a *declarative* manner. We say *what*
data we want in the route and define *how* we get that data in the mutable.

## Mutators

Pakyow UI also introduces **mutators**. As explained above, a mutator describes
*how* to render a particular view with some particular data.

Here's a mutator for rendering a list of users:

```ruby
Pakyow::Mutators :user do
  mutator :list do |view, users|
    view.apply(users)
  end
end
```

From a route, the mutator can be invoked on a view like this:

```ruby
view.scope(:user).mutate(:list, with: data(:user).all)
```

Notice that we're mutating with the data from our mutable user object. Pakyow
will automatically fetch the data using the `all` query and pass it to the
`list` mutation where the view is rendered.

At this point we've effectively turned view rendering into a declarative action
from the route's point of view. We only describe *what* we want to happen and
Pakyow takes care of the details.

This is a nice pattern on its own, but it becomes even more useful when you want
to subscribe a mutation to future state changes. This is done with `subscribe`.

```ruby
view.scope(:user).mutate(:list, with: data(:user).all).subscribe
```

The view is rendered in the intial request/response cycle exactly like it was
before, but now it's also *subscribed to any future change in state that would
affect the rendered view*.

Let's mutate our state by creating a new user:

```ruby
data(:user).create(params[:user])
```

Pakyow knows that we've mutated our user state, so it automatically pushes down
instructions describing how each client should update their view to match the
current state.

Views rendering the user list now keep themselves up to date with the current
state of the application. What's nice is that we as the developer don't have to
do anything but write the initial rendering code! We don't have to move any part
of our app to the client or write any JavaScript. Our app is backend-driven as
before but now behaves like other modern apps.

## Qualifiers

Qualifiers allow for fine-grained control over who receives updates. For
example, a view can be subscribed so that it only updates the data for the
current user:

```ruby
view.scope(:user).mutate(:list).subscribe(user_id: current_user.id)
```

The `user_id` qualifier is added to the channel name, so when future mutations
occur, the result will only be pushed down to that particular client. This means
only the client matching `current_user.id` will receive the updates.

```ruby
ui.mutated(:user, user_id: current_user.id)
```

Mutators can also be qualified. Here's how you would express that you want
mutations to be sent only to clients that render that user:

```ruby
Pakyow::Mutators :user do
  mutator :present, qualify: [:id] do |view, user|
    view.bind(user)
  end
end

view.scope(:user).mutate(:present, with: data(:user).find(1)).subscribe
```

The value for the qualifier is pulled from the id of the user data passed
into the mutator. You can define qualifiers for any data attribute.

## Component Messages

Pakyow UI provides ways to interact with browser components. Any view methods can be called, which will
be performed on the component rendered by the browser.

```ruby
ui.component(:chat).prepend(message_instance)
```

It's also possible to send a message to the component that it knows how to handle.

```ruby
ui.component(:chat).push({ ... })
```

You can see a working example of both of these things in the [example
app](https://github.com/bryanp/pakyow-chat).

## Triggering Mutators

Mutators are triggered automatically when calling a mutable action. In cases
where you want to trigger mutators without this, you can use `mutate`.

```ruby
ui.mutate(:user)
```

## Channel Building

Pakyow UI keeps track of what clients should receive what state mutations using
realtime channels. Here's how a channel is structured:

```
scope:{name};mutation{name}::{qualifiers}
```

In the example from the Mutators section, the subscribed channel name is:

```
scope:user;mutation:list
```

This means that any client who rendered any user data with the `list` mutation
will receive future updates in user state.

## Example UI Application

You can find a maintained Pakyow UI example application
[here](https://github.com/bryanp/pakyow-chat). This example implements a chat
application that allows multiple users to talk together in realtme.
