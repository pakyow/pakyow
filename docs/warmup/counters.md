---
name: Traffic Counters
desc: Creating the traffic counters.
---

The first feature we'll add to our back-end is the traffic counters. We want
each counter to reflect its appropriate statistic, and we also want any changes
in the statistics data to auto-update for anyone who's currently looking at it
in a web browser.

## Data Layer

We need a way of persisting and fetching the statistics. In Pakyow, we can do
this with what's called a mutable. Mutables sit between an app's business logic
and data model to provide Pakyow with a consistent interface to the data.

Create a file named `app/lib/mutables/stats_mutable.rb` and add the following
code:

```ruby
Pakyow::App.after :init do
  redis.set(:active, 0)
end

Pakyow::App.mutable :stats do
  query :for_default_post do
    {
      total: redis.get(:total),
      active: redis.get(:active)
    }
  end

  action :view_default_post do
    redis.incr(:total)
  end

  action :viewer_joined do
    redis.incr(:active)
  end

  action :viewer_left do
    redis.decr(:active)
  end
end
```

The first three lines setup the initial value for active viewers when the
application first starts up. Next, the mutable is defined with a query and three
actions.

When called, the `for_default_post` query will return a hash containing the
total and active counts. It does this through the Redis connection we setup in
the previous section.

We've also defined three actions that, when called, tell Pakyow that the
underlying state of our application has changed. The first action simply
increments the total count, while the second and third actions increment and
decrement the count of active viewers.

## Join / Leave Events

Next, we need to call the appropriate action when someone joins or leaves the
app. To do this, we'll hook into the join / leave events provided by Pakyow
Realtime. Create a `app/lib/events.rb` file and add the following code:

```ruby
Pakyow::Realtime::Websocket.on :join do
  data(:stats).viewer_joined
end

Pakyow::Realtime::Websocket.on :leave do
  data(:stats).viewer_left
end
```

Our `stats` mutable is available via the `data(:stats)` helper. We can use this
to call the `viewer_joined` and `viewer_left` actions when Pakyow Realtime fires
a join or leave event.

## View Logic

Now that we have some data to display, let's write the view rendering code for
our counters. In Pakyow, view rendering happens outside of the view template in
objects called mutators. Create a `app/lib/mutators/stats_mutator.rb` file and
add the following code:

```ruby
Pakyow::App.mutators :stats do
  mutator :post do |view, data|
    view.bind(data)
  end
end
```

This mutator will render our statistics for us. The view and data to render are
passed to it, and it simply binds the data to the view. Binding is covered in
[more detail here](/docs/view-logic), but for our purposes we can think of it as
putting data values into the right place in the view.

## Routing

Next, we need to wire everything up in our routes. Open `app/lib/routes.rb` and
replace the current `default` route with the following code:

```ruby
default do
  # increment the counter
  data(:stats).view_default_post

  # render the stats
  view.scope(:stats).mutate(:post,
    with: data(:stats).for_default_post
  )
end
```

Pakyow will call this route when a request comes in for the default `/` path.
The `index.html` view will be used automatically and will be made available
through the `view` helper method.

The first thing the default route does is increment the total count by calling
the `view_default_post` action on our mutable. Then we render the statistics by
finding the `stats` scope on the view and invoking the `post` mutator we defined
in the previous step. This mutator is invoked with our default statistics query
defined in the mutator.

## Make It Realtime

If you open up [localhost:3000](http://localhost:3000) in a web browser you'll
see that our counters increment and render like we expect. However, if you open
up two browser sessions you'll notice that the statistics don't change when
another user joins or leaves the page. A page refresh is required to see the
latest data.

We can leverage Pakyow UI to make this auto-update for us. All we have to do is
tell Pakyow to subscribe the rendered view to future changes in state, and
Pakyow will take care of the rest.

Open the routes file back up and add a call to `subscribe` to the mutation. It
should now look like this:

```ruby
# render the stats
view.scope(:stats).mutate(:post,
  with: data(:stats).for_default_post
).subscribe
```

Now, refresh your browser and open a second session. The counters now update
automatically to reflect the latest statistics! And as a developer all we had to
was tell Pakyow to do it. We didn't have to write any of the realtime code or
drop down into JavaScript to make it happen.

## How Realtime Works

Pakyow Realtime is a library that brings WebSocket and Channel support to Pakyow
projects. It also provides a way to call back-end routes over the open WebSocket
just as if it were HTTP. 

Pakyow UI builds on Pakyow Realtime to make views auto-update to reflect the
latest state of the data. When a change occurs that would cause a subscribed
view to be rendered differently, Pakyow builds up a set of transformation
instructions and pushes them to each client over the open WebSocket.

Once the instructions are received, a lightweight JavaScript library,
[Ring](https://github.com/pakyow/ring), processes and applies the instructions
to the view. No re-rendering occurs as only the changes and applied. This keeps
the UI fast and responsive for the user.

You can read more about [Pakyow Realtime](/docs/realtime) and [Pakyow
UI](/docs/live-views). But let's keep moving.
