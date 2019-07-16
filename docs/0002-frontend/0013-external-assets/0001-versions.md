---
title: Working with package version
---

When an external package version is left unspecified, as  in the previous example, Pakyow will download the latest available version. To specify a specific version, simply define it when registering the external package:

<div class="filename">
  config/application.rb
</div>

```ruby
Pakyow.app do
  configure do
    external_script :d3, "5.5.0"
  end
end
```

> [callout] The version can be any semvar value supported by NPM. [Read more &rarr;](https://docs.npmjs.com/misc/semver)
