---
name: Route Sets
desc: Organizing routes into sets.
---

As a Pakyow application grows, so do it's routes. Route sets allow sets of routes to be moved into their own source files. Since Pakyow has no concept of controllers, a good best practice is to use route sets as you would a controller by adding all related routes into a single set.

Each set is registered with a unique name, like so:

```ruby
Pakyow.app.routes :my_routes do
  # routes go here
end
```

An application's main route set is called `:main`, and is defined without passing a set name:

```ruby
Pakyow.app.routes do
  # main routes go here
end
```

The first set defined is the first matched, so the order in which route sets are loaded does matter. Main routes are always loaded first and thus have top priority in an application (if two routes match, the one in the main route set wins). Load order for additional route sets is determined by the order of definition.
