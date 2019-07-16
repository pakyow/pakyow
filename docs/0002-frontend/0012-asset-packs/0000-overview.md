---
title: Asset Packs
---

Asset packs consists of a named stylesheet and/or script that can be included by a view template. It's the perfect place to put things that will be used across your application, but don't follow your view template structure close enough to make use of composition.

Asset packs live in the `frontend/assets/packs` folder. Each pack has a unique name and an associated stylesheet and/or script. For example, to create a pack named "example" that includes some styles, add a file like this to the packs folder:

<div class="filename">
  frontend/assets/packs/example.css
</div>

```css
p {
  color: red;
}
```
