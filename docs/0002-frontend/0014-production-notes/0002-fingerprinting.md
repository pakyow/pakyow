---
title: Fingerprinting assets
---

Assets are fingerprinted when built in production. Fingerprints allow assets to be cached by browsers indefinitely by attaching a fingerprint, or unique identifier based on the asset content, to the name of the asset. When the content of an asset changes the fingerprint changes along with it, causing the browser to replace the cached version with the updated asset.

Each fingerprint is a unique identifier generated from the contents of an asset's source files. Let's look at an example based on this stylesheet:

<div class="filename">
  frontend/assets/stylesheets/example.css
</div>

```css
p {
  color: red;
}
```

Here's the unique fingerprint that Pakyow will generate for the stylesheet:

```
3613c173b8f70052c8d86d555dfad0ea
```

This identifier is added to each asset reference in the view templates. Assume the stylesheet is loaded into a view template like this:

```html
<link rel="stylesheet" type="text/css" href="/stylesheets/example.css">
```

In production, the asset href will be updated to include the fingerprint:

```html
<link rel="stylesheet" type="text/css" href="/assets/stylesheets/example__3613c173b8f70052c8d86d555dfad0ea.css">
```

Pakyow will instruct the browser to cache the stylesheet so that it doesn't need to be fetched on subsequent requests. When the stylesheet changes it will receive a new fingerprint and the browser will download the updated version of the stylesheet.


## Disable fingerprinting

To disable fingerprinting, just set the `assets.fingerprint` configuration option for the production environment:

<div class="filename">
  config/application.rb
</div>

```ruby
Pakyow.app do
  configure :production do
    config.assets.fingerprint = false
  end
end
```
