---
name: Forms
desc: How to use forms in Pakyow.
guide: true
---

Pakyow makes working with forms super easy. When defining a form, always scope the form and add props to fields:

```html
<form data-scope="post">
  <input type="text" data-prop="name">
</form>
```

From the backend, binding data to the scope will automatically define `name` attributes, making the submitted data available in the `params` helper:

```ruby
view.scope(:post).bind({})
```

Resulting view:

```html
<form data-scope="post">
  <input type="text" data-prop="name" name="post[name]">
</form>
```

The `value` attribute will also be set automatically if one is available in the data being bound.

If a field already has a `name` or `value`, Pakyow will not overwrite it.

## Action / Method

In the case of Restful routes, Pakyow will automatically set the form action and method based on the state of the object. For this to work, you will need to add the following code to the [bindings](/docs/view-logic/bindings) for the form's scope:

```ruby
Pakyow::App.bindings do
  restful :post
end
```

The argument to `restful` should reference the name of the [RESTful route group](/docs/routing/restful).

Now, when binding data to the form the action and method will be set for you and the form will submit to the right path.

## Select Options

Options can be defined in the bindings, like this:

```ruby
Pakyow::App.bindings do
  options :type do
    [[:one, 'option 1'], [:two, 'option 2']]
  end
end

view.scope(:post).bind({ type: :two })
```

Resulting view:

```html
<form data-scope="post">
  <select data-prop="type" name="post[type]">
    <option value="one">option 1</option>
    <option value="two" selected>option 2</option>
  </select>
</form>
```

You can also set the first option to empty:

```ruby
Pakyow::App.bindings do
  options :type, empty: true do
    [[:one, 'option 1'], [:two, 'option 2']]
  end
end

view.scope(:post).bind({ type: :two })
```

Resulting view:

```html
<form data-scope="post">
  <select data-prop="type" name="post[type]">
    <option></option>
    <option value="one">option 1</option>
    <option value="two" selected>option 2</option>
  </select>
</form>
```
