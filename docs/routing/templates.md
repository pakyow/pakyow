---
name: Route Templates
desc: Defining route templates for reusability.
---

Route templates make it possible to create a DSL for aspects of your routes. The built-in [RESTful route handling](/docs/routing/restful) in Pakyow is implemented as a template. It's easiest to understand in practice, so here's the built-in RESTful template for your reference:

```ruby
template :restful do
  resource_id = ":#{@group}_id"

  nested_path { |path| File.join(path, resource_id) }
  view_path = direct_path.gsub(/:[^\/]+/, '').split('/').reject { |p| p.empty? }.join('/')

  fn :reset_view_path do
    presenter.path = File.join(view_path, 'show') if @presenter
  end

  get :list, '/'
  get :new,  '/new'
  get :show, "/#{resource_id}", before: [:reset_view_path]

  post :create, '/'

  get :edit, "/#{resource_id}/edit"
  patch :update, "/#{resource_id}"
  put :replace, "/#{resource_id}"
  delete :remove, "/#{resource_id}"

  group :collection
  namespace :member, resource_id
end
```

This template can then be expanded any number of times in an application's routes:

```ruby
Pakyow::App.routes do
  restful :resource_name, '/resource_path' do
    list do
      # ...
    end

    # ...
  end
end
```

Templates offer a few wins over the long-hand approach:

  - Routing intricacies are hidden in the template definition, leaving the implementor to focus on the logic.
  - Common patterns can be abstracted, leading to a significant reduction in code duplication.
  - Route changes can be made in one place and be automatically applied to each expansion.

## Template Hooks

[Hooks](/docs/routing/hooks) can be defined in the template definition or expansion. The difference is that defining a hook in the definition applies the hook to every expansion, while defining a hook on a single expansion applies it to that one expansion. They can be defined at different levels in each case.

For definitions, hooks can be defined on the entire definition or only for a particular route in the definition.

```ruby
template :my_template, before: [:foo] do
  get :one, before: [:bar]
  get :two
end

my_template do
  one do
    # hooks: foo, bar
  end

  two do
    # hooks: foo
  end
end
```

Expansions work in a similar way. Hooks can be defined on the entire expansion or only for a particular route in the definition.

```ruby
my_template, before: [:foo] do
  one, before: [bar] do
    # ...
  end

  two do
    # ...
  end
end
```
