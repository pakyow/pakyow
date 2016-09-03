---
name: Realtime Comments
desc: Creating the chat-based comment system.
---

Now that we have statistics that keep themselves up to date, let's add the
back-end for our comments. We want this to feel more like a live chat, so we'll
make use Pakyow UI again.

## Data Layer

First, we need a comment mutable to fetch and alter our comments state. Create a
file named `app/lib/mutables/comments_mutable.rb` and add the following code:

```ruby
Pakyow::App.mutable :comment do
  query :for_default_post do
    redis.lrange(:comments, 0, -1).each_with_index.map { |content, id|
      {
        id: id + 1,
        content: content
      }
    }
  end

  action :create do |params|
    redis.lpush(:comments, params[:content])
  end
end
```

The `for_default_post` query finds all comments and creates an array of hashes
from the raw data. Under it, the `create` action creates a new comment in Redis.

## View Logic

Next, we need to define the mutator required for view rendering. Create a
`app/lib/mutators/comments_mutator.rb` file and add the following code:

```ruby
Pakyow::App.mutators :comment do
  mutator :list do |view, data|
    view.apply(data)
  end
end
```

This is almost exactly like our `stats` mutator, except we're calling the
`apply` view transformation method rather than calling `bind`. The `apply`
method transforms the view to match the data being applied and then binds the
values in.

When we apply an empty collection of comments, `apply` will simply render the
default version of the scope. If the collection contains one or more comments,
it will create a copy of the comment scope for each comment. The result is that
the view will always contain the same number of elements as the collection being
applied, while providing some convenience around handling empty collections.

## Routing

Now that we have our mutable and mutator, it's time to wire it up. Open
`app/lib/routes.rb` and add the following code at the end of the default route:

```ruby
# render the comment list
view.partial(:'comment-list').scope(:comment).mutate(:list,
  with: data(:comment).for_default_post
).subscribe

# setup the form for a new object
view.partial(:'comment-form').scope(:comment).bind({})
```

First we render our comment list with our comments data and then subscribe it to
future state changes. Next we bind an empty object to the comment form, so that
Pakyow will setup the form for creating a new comment. This might seem odd, but
will make more sense in a moment.

Next, let's define the restful route for comment creation. Add the following
code after the default route:

```ruby
restful :comment, '/comments' do
  action :create do
    # create the comment
    data(:comment).create(params[:comment])

    # go back
    redirect :default
  end
end
```

Following the REST convention, this route will be called when a `POST` request
is sent to `/comments`. Now there's only one more step remaining. We need to
tell Pakyow to tie the comment scope to the restful resource. Open
`app/lib/bindings.rb` and replace the contents with the following code:

```ruby
Pakyow::App.bindings do
  scope :comment do
    restful :comment
  end
end
```

Now everything is hooked up. When binding an empty object to the comment form,
Pakyow will set it up for creating a comment through our restful resource.

## Avoiding the Form Submission Refresh

Open [localhost:3000](http://localhost:3000) in two browser sessions and you'll
see that comments created in one window automatically show up in the other
window. This is great, but it's still a bit clunky for the user creating the
comment since the form submission causes a full page refresh.

Fortunately the Pakyow client library, Ring, gives us a way to avoid this. Open
`app/views/_comment-form.html` and add the following `data-ui` attribute to the
form node:

```html
<form data-scope="comment" class="margin-t" data-ui="mutable">
```

This attaches a ui component named `mutable` to the form node. The mutable
component ships with Ring, and interprets a user's interaction with the
interface as a change in state.

Let's also load the component that's bundled with the project. Open
`app/views/_templates/default.html` and add the following markup between the
opening and closing `<head>` tags:

```html
<script src="/scripts/ring/components/mutable.js"></script>
```

Now, when the form is submitted, mutable jumps in and hijacks the interaction,
submitting the form over the open WebSocket rather than normal HTTP. Because
Pakyow UI exposes our routes over the WebSocket, the restful create route is
called, which creates our new comment. Once created, the new comment is pushed
down to any connected client, *including* the client that created the comment.

## Realtime Wrapup

We've successfully built a prototype, added a back-end to it, and made
everything work in realtime. and we didn't move any code to the client or write
any JavaScript to make it happen!

There are two fundamental Pakyow concepts at work here: the [View Transformation
Prototcol](/docs/concepts/view-transformation-protocol) and [Simple State
Propagation](/docs/concepts/simple-state-propagation). These concepts work
together to provide auto-updating views in a new way.

**Progressive Enhancement**

The idea that content should always be accessible is expressed throughout the
Pakyow design philosophy. In fact, if you completely disable JavaScript the app
we just built will still continue to work! Views will no longer auto-update, but
the content remains accessible and the UI continues to function.

For the first time, Pakyow makes it possible to build modern, realtime apps that
degrade well when JavaScript fails to execute or is unavailable. You can be sure
that your content is always accessible, both by bots and by users.
