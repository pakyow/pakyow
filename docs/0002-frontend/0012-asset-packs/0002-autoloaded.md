---
title: Auto-Loaded packs
---

Sometimes it's useful to load a pack throughout an entire application without having to include it in every view template. You can do this by adding the pack to the `assets.packs.autoload` config option in `config/application.rb`:

<div class="filename">
  config/application.rb
</div>
```ruby
Pakyow.app do
  configure do
    config.assets.packs.autoload << :example
  end
end
```

* [Learn more about configuration &rarr;](doc:configuration)
