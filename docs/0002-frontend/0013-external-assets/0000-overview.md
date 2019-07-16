---
title: External Assets
---

Pakyow provides a simple way to manage external JavaScript in your apps, without the bloat of a tool like NPM or Yarn. These tools can be great for complex build pipelines, but Pakyow's simpler approach is a good fit for most applications.

External scripts are defined in your application's `configure` block:

<div class="filename">
  config/application.rb
</div>

```ruby
Pakyow.app do
  configure do
    external_script :d3
  end
end
```

The next time the project is started in development mode, Pakyow will fetch a browser-ready build of the [D3.js](https://www.npmjs.com/package/d3) library, placing it into the `frontend/packs/vendor` folder. D3 can be loaded like any other pack:

```html
---
packs:
- d3
---

...
```

Any package hosted on NPM can be managed in this way, as long as it provides a browser-ready build for distribution. Pakyow currently fetches external scripts from the [unpkg.com](https://unpkg.com/) service.
