---
title: Example Usage
---

Realtime config lives in both `./config/environment.rb` and `./config/application.rb`:

<div class="filename">
  ./config/environment.rb
</div>

```ruby
Pakyow.configure do
  config.realtime.option = value
end
```

<div class="filename">
  ./config/application.rb
</div>

```ruby
Pakyow.app do
  configure do
    config.realtime.option = value
  end
end
```
