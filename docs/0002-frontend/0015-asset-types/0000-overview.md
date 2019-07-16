---
title: Asset Types
---

Pakyow will only serve assets of a known type. Most of the common asset types you'll encounter are supported right out of the box, including:

| Category      | Extensions                                           |
|---------------|------------------------------------------------------|
| Audio&nbsp;/&nbsp;Video | `.webm`, `.snd`, `.au`, `.aiff`, `.mp3`, `.mp2`, `.m2a`, `.m3a`, `.ogx`, `.gg`, `.oga`, `.midi`, `.mid`, `.avi`, `.wav`, `.wave`, `.mp4`, `.m4v`, `.acc`, `.m4a`, `.flac` |
| Data          | `.json`, `.xml`, `.yml`, `.yaml`                     |
| Fonts         | `.eot`, `.otf`, `.ttf`, `.woff`, `.woff2`            |
| Images        | `.ico`, `.bmp`, `.gif`, `.webp`, `.png`, `.jpg`, `.jpeg`, `.tiff`, `.tif`, `.svg` |
| Scripts       | `.js`                                                |
| Styles        | `.css`, `.sass`, `.scss`                             |

Support for more types can be added by defining the filename extension on the corresponding key in the `assets.types` configuration option.

* [Read more about the `assets.types` option &rarr;](doc:configuration/assets/types)
