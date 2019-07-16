---
title: Defining forms
---

In most cases, a form submits values for particular type of data defined in your application. To define a form, add a binding to a `form` tag with the data type the form is submitting values for:

```html
<form binding="message">
  ...
</form>
```

Pakyow automatically sets the `action` and `method` attributes on the form based on what context the form is used in. For new objects, the form is setup to create the object. For existing objects, the form is instead setup to update the object.

Here's what the above form would look like after Pakyow sets it up for creating a message:

```ruby
<form action="/messages" method="post">
  ...
</form>
```

You can also manually define the endpoint for the form, which is discussed in the frontend endpoint guide.

* [Read about defining form endpoints &rarr;](doc:frontend/endpoints/forms)
