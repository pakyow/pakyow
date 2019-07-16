---
title: Configuring With Blocks
---

Configuration occurs in one or more `configure` blocks, like this one in `./config/application.rb`:

```ruby
Pakyow.app do
  configure do
    config.option = :value
  end
end
```

Configuration blocks are called during the initialization process. Each block accepts an optional parameter that defines what *environment* the configuration block should be called in. This allows you to use one set of values in development, another in production, and so on. When the environment is unspecified, the configuration block applies to *all* environments.

```ruby
Pakyow.app do
  configure do
    config.option = :global_value
  end

  configure :development do
    config.option = :development_value
  end

  configure :production do
    config.option = :production_value
  end
end
```

Default configuration exists for each of the following environments: `development`, `test`, and `production`.
