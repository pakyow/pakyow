---
title: Minifying assets
---

Pakyow automatically minifies stylesheets and scripts in production. This can reduces the file sizes significantly, improving the performance of your application for end users.

Scripts are minified with [Uglifier](https://github.com/lautis/uglifier), while stylesheets are always minified with the Scss preprocessor (even if your stylesheets are written in plain css).

## Disable minification

Minification can be disabled by setting the `assets.minify` configuration option for the production environment:

<div class="filename">
  config/application.rb
</div>

```ruby
Pakyow.app do
  configure :production do
    config.assets.minify = false
  end
end
```
