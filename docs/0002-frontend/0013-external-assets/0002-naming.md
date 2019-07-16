---
title: Specifying the package name
---

Sometimes the name of the external package is not the most logical name to use within your application. For example, the Pakyow.js pack lives in a package named `@pakyow/js` but is exposed through the `pakyow` pack.

Pakyow can handle these cases with the `package` argument:

<div class="filename">
  config/application.rb
</div>

```ruby
Pakyow.app do
  configure do
    external_script :pakyow, package: "@pakyow/js"
  end
end
```

Here the given name `pakyow` is used to name the pack available within the application, while `@pakyow/js` is the name of the external package to be fetched from NPM.
