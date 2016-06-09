---
name: View Processors
desc: Using processors to support multiple template languages.
---

Processors allow view components to be processed prior to being handed to
`Presenter`. The most common use for processors is to allow views to be written
in languages other than HTML (e.g. Markdown or Slim). Since `Presenter` always
expects HTML, a processor is given the contents of the view, processes it, and
returns HTML. Below is an example that uses RDiscount to process views written
in Markdown:

```ruby
processor :md, :markdown do |content|
  RDiscount.new(content).to_html
end
```

This processor will process any view with a `md` or `markdown` extension. An app
using this processor can define views in both Markdown and HTML. Presenter will
work as if all views were written in HTML to begin with.

```
views/
  index.md
```

Processors are defined in `app/setup.rb`.

Three processors have been created as gems that you can include into your app:

- [HAML](http://github.com/pakyow/pakyow-haml)
- [Markdown](http://github.com/pakyow/pakyow-markdown)
- [Slim](http://github.com/pakyow/pakyow-slim)
