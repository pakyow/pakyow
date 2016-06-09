---
name: Data Bindings
desc: Amending data during the binding process.
---

Bindings can be thought of as functions that route data to the view. They can be used for setting view attributes, formatting data, etc.

You should define bindings for a particular scope / prop in `app/lib/bindings.rb`. As an example, let's define a binding that randomly sets the text color for the `title` prop of a `post` scope:

```ruby
scope :post do
  binding :title do
    {
      style: {
        color: %w(red blue green).sample
      },

      content: bindable[:body]
    }
  end
end
```

This binding is called any time data is bound to `title` prop for a `post` scope, like this:

```ruby
data = {
  title: 'First Post'
}

view.scope(:post).bind(data)
```

Here's the result:

```html
<div data-scope="post">
  <h1 data-prop="title" style="color:blue">
    First post
  </h1>
</div>
```

Of course, the color will be randomly assigned each time bind is called.

## View Access

A binder can also obtain access to the view object that is being bound to.

```ruby
binding :foo do
  {
    view: lambda { |view|
      view.prepend('some html')
    }
  }
end
```

## Modifying Values

A binder can modify an existing value by setting the value to a lambda:

```ruby
binding :foo do
 { class: lambda { |klass| klass << 'class_name' } }
end
```

## Binding Sets

Just like routes, bindings can be grouped into named sets:

```ruby
Pakyow::App.bindings :my_set do
  # bindings defined here
end
```
