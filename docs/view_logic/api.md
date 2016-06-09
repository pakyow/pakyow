---
name: View API
desc: The Pakyow view API.
---

Below is an overview of Pakyow's View API, providing a way to compose,
manipulate, and render views in your backend code.

## Data Binding

Pakyow defines several useful methods for binding data to a view.

### for

The `for` method yields each view and matching datum. This is driven by the
view, meaning datums are yielded until no more views are available. In the
single view case, only one view/datum pair is yielded.

```ruby
view.for(data) do |view, datum|
  ...
end
```

### match

The `match` method returns a `ViewCollection` that has been transformed to match
the data.

```ruby
view.match(data)
```

### repeat

The `repeat` method calls `match`, then yields each view/datum pair.

```ruby
view.repeat(data) do |view, datum|
  ...
end
```

This is the same as chaining `match` and `for`:

```ruby
view.match(data).for(data) do |view, datum|
  ...
end
```

### bind

The `bind` method binds data across props contained in the scoped view, without applying any transformation to the view. An example can be found above.

If a block is passed, each view/datum pair is yielded to it (where the view is fully bound with the data).

### apply

The `apply` method transforms the view to match the data being applied, then binds the data to the transformed view. An example can be found in the next section.

If a block is passed, each view/datum pair is yielded to it (where the view is fully bound with the data). See "Binding to Nested Scopes" for an example of where this is useful.

## Composing Views

View compilation is easily managed from the backend. The view path can be changed:

```ruby
presenter.path = 'some/path'
```

The view can also be set explicitly:

```ruby
presenter.view = a_view_object
```

Complex views can also be composed and set. This is done through the `ViewComposer` object. The way composer works is you specify the path you want to compose at, then override any part of the view (e.g. a template, page, or partial).

```ruby
presenter.view = presenter.compose_at('some/path', template: 'some_other_template')
```

## Traversing Nodes

Pakyow makes it possible to traverse significant nodes in a view. A significant node is one that has been labeled as a `scope` or `prop`.

```ruby
view.scope(:some_scope)
view.prop(:some_prop)
```

In addition, parts of a view can be accessed using the following helper methods:

```ruby
template
page
partial(:some_partial)
container(:some_container)
```

## Modifying Views

Views can be modified from back-end code in a number of ways, including:

```ruby
# remove the view
view.remove

# clear the contents
view.clear

# get the text content
view.text

# set the text content
view.text = ...

# get the html content
view.html

# set the html content
view.html = ...

# append a view or content
view.append(...)

# prepend a view or content
view.prepend(...)

# insert a view or content after the view
view.after(...)

# insert a view or content before the view
view.before(...)

# replace the view with a view or content
view.replace(...)
```

Pakyow also provides a way of dealing with view contexts:

```ruby
view.scope(:post).with do
  prop(:title).remove

  # do more to the context here
end
```

These contexts are available to the following methods:

- with
- for
- repeat
- bind
- apply

Read more [here](/docs/view-logic/traversing).

## Attributes

There are three types of attributes in Pakyow:

- string (e.g. href)
- enumerable (e.g. class)
- boolean (e.g. selected)

Pakyow handles each in a smart way. Attributes can be access or modified using the hash key syntax:

```ruby
view.attrs[:href] = '/foo'
view.attrs[:class] << 'class_to_add'
view.attrs[:selected] = true
```

Attributes can be massed assigned by setting attrs to a hash:

```ruby
view.attrs = { href: '/foo', class: ['some_class'] }
```

Values can be modified rather than overridden by passing a lamda as a value:

```ruby
view.attrs[:class] = lambda { |klass| klass << 'foo' if some_condition }
```

Attribute values can also be ensured or denied, meaning Pakyow will make sure the given value is or is not present for the attribute:

```ruby
view.attrs[:class].ensure(:foo)
view.attrs[:class].deny(:bar)
```
