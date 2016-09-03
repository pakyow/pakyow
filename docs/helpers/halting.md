---
name: Halting & Rerouting
desc: Stopping and rerouting a request.
---

The execution of a route block, a controller, a hook, or a handler can be stopped immediately by calling the `halt` helper:

```ruby
halt
```

The execution of a route block, a controller, a hook, or a handler can be stopped immediately and control transferred to another route by using the `reroute` helper:

```ruby
reroute '/foo'
```

Or even better, if you define your route with a name (such as :foo) the URI will be generated [automatically](/docs/routing/uri-generation):

```ruby
reroute :foo
```
