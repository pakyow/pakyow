module ViewComposerHelpers
  def compose_helper(opts, &block)
    ViewComposer.from_path(@store, nil, opts, &block)
  end

  def compose_at(path, opts = {}, &block)
    ViewComposer.from_path(@store, path, opts, &block)
  end

  def compose_with_context(context, opts = {}, &block)
    ViewComposer.from_context(@store, context.request.path, opts, &block)
  end

  def view_for(template_name, page_path, partials = {})
    template = @store.template(template_name)
    page = Page.load(@store.expand_path(page_path))

    partials = Hash[partials.map { |name, path|
      [name, Partial.load(@store.expand_path(path))]
    }]

    return template.build(page).includes(partials)
  end
end
