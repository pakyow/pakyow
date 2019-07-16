---
title: Endpoints
---

Endpoints are responsible for exposing the dynamic data that is ultimately presented in view templates. Data is pulled directly from data sources, which were discussed in the previous guide. Reflection defines backend endpoints for your application based on the data bindings it finds in your frontend.

Let's look at an example of how an endpoint is defined. Here's a view template that defines a `message` data binding that presents a single value for `content`:

<div class="filename">
  frontend/pages/index.html
</div>

```html
<article binding="message">
  <p binding="content">
    message content goes here
  </p>
</article>
```

Reflection defines a backend endpoint for this view template, which looks like this:

```
Endpoint Name  HTTP Method  Request Path  Who Defined the Endpoint
-------------  -----------  ------------  ------------------------
:root          GET          /             pakyow/reflection
```

When a request is made to `GET /`, the reflected endpoint will expose the correct data. You can see exactly what reflection is doing by looking at the logs. Here's what you would see for the above endpoint:

```
185.00μs http.9b0296e9 | GET / (for 127.0.0.1 at 2019-07-16 18:43:44 +0000)
  1.39ms http.9b0296e9 | [reflection] exposing dataset for `message': #<Pakyow::Data::Proxy:70221658905980 @source=#<Sequel::SQLite::Dataset: "SELECT * FROM `messages` ORDER BY `created_at` DESC">>
  9.53ms http.9b0296e9 | 200 (OK)
```

Endpoints are created in a controller on the backend. Controllers define routes that call backend behavior for http requests that match a specific method and path. In this case, here's what the controller would look like:

```ruby
controller do
  get :root, "/" do
    # Reflected behavior is performed here.
  end
end
```

If we were to write the controller ourselves, here's what it would look like with the behavior filled in:

```ruby
controller do
  get :root, "/" do
    expose "message", data.messages.all

    render "/"
  end
end
```

Reflection keeps us from having to write code like this ourselves. Not only that, the reflection automatically updates its behavior to match changes in the view template. You can add more bindings to the template and data will be exposed for them without having to make any changes yourself. Reflection makes your backend reactive to changes in frontend view templates, rather than hardcoded to work with particular set of bindings. This reduces the amount of coordination you would otherwise need to handle yourself, shortening the feedback loop between changes in the process.
