---
name: Hooks
desc: Hooking into environment events in Pakyow.
---

Pakyow's environment triggers several events during the setup and boot process.
You can react to these events by registering hooks that execute custom code
before, after, or around some event occurring.

Here's a list of hookable events:

- Configure: called when the environment is configured.
- Setup: called after configuration but prior to running.
- Fork: called when the environment is forked into a new process.

And here's how you might hook into an event:

```ruby
Pakyow.before :configure do
  # do something before configuring
end

Pakyow.after :setup do
  # do something after setup
end

Pakyow.around :fork do
  # do something before and after forking
end
```
