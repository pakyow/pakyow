---
title: Supported Formats
---

Pakyow ships with support for plain-html view templates. However, support for other template formats can be added to your project through third-party gems. Once installed, Pakyow will process view templates of other types into html prior to view rendering.

Below is a list of processors that we're aware of. To install one, add the appropriate gem to the `Gemfile` in your project.

* Markdown: Add the `pakyow-markdown` gem to your project. It installs support for [Markdown templates](https://daringfireball.net/projects/markdown/syntax), including syntax highlighting for code blocks. Formats view templates with a `.md`, `.mdown` or `.markdown` extension.

* Slim: Add the `pakyow-slim` gem to your project. It installs support for view templates written in the [Slim template language](http://slim-lang.com). Formats view templates with a `.slim` extension.

* Haml: Add the `pakyow-haml` gem to your project. It installs support for view templates written in the [Haml template language](http://haml.info). Formats view templates with a `.haml` extension.
