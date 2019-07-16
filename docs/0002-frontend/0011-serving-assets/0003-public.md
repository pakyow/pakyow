---
title: Creating unmanaged assets
---

From time to time you may need to include an asset in your application that you don't want managed in the asset pipeline. A good example is the `robots.txt` file. Bots expect to find this file at the root level of your website. If you include it in the asset pipeline it will be served at the wrong location (`/assets/robots.txt`). It will also be fingerprinted in production, giving it an unpredictable public path.

You can define an unmanaged asset by add the asset file directly to the `public` folder in your project. Files in the `public` folder will be served alongside other assets, but they won't be fingerprinted or served with cache headers since they aren't part of the managed asset pipeline.
