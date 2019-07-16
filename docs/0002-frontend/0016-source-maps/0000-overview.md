---
title: Source Maps
---

Source maps make it easier to see the original source code for assets that have been compiled together. Most modern browsers automatically fetch source maps when you open up the developer tools. When you inspect an element, styles are shown in context of the original assets in your project. Scripts behave in a similar way in that any errors that pop up will be displayed with filenames and line numbers mapping back to your project.

Pakyow automatically builds and serves source maps for your stylesheets and scripts. Source maps are defined in separate files served alongside your assets. The asset and its source map is named identically, except that the source map ends with a `.map` extension. A reference to the source map is added to the compiled asset so that the browser knows where to find the map.

## Source maps in production

Pakyow enables source maps in production by default. We believe that one of the best things about the web is "view source". Modern tools have made it easier to write code, but harder for people to look at the stylesheets and scripts of a website themselves.

We want to embrace the open nature of the web, so Pakyow defaults to view source friendly.

There's not much of a downside to source maps in production. Source maps are only downloaded if developer tools are open, so most users will never download the source map. Enabling source maps has no effect on your app's performance and won't cause much (if any) increase in bandwidth.

## Disabling source maps

You can disable source maps by setting the `assets.source_maps` config option to `false`.

* [Read more about the `assets.source_maps` option &rarr;](doc:configuration/assets/source_maps)
