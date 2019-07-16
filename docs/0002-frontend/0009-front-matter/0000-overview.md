---
title: Front-Matter
---

Pakyow view templates support a technique called front matter to set configuration values that change the behavior of the view being rendered. To use front matter, simply add code that looks like the following example to the top of any view template:

```html
---
key: value
---
```

You can place any valid [YAML configuration](https://yaml.org/refcard.html) within the `---` bookends. Pakyow will parse the front matter from the template and expose the values to backend code.
