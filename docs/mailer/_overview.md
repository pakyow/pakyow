---
name: Mailers
desc: Sending email from a Pakyow app.
---

Pakyow has built-in mechanisms for delivering views through email. The easiest way to user mailers is from a route. Here's a basic example:

```ruby
mailer(view_path).deliver_to('test@pakyow.org')
```

The view will be constructed just like it would be if it was being presented in a browser. You can also access the view for manipulation and binding:

```ruby
mailer = mailer(view_path)
mailer.view.scope(:foo).apply(some_data)
mailer.deliver_to(['test@pakyow.org', 'example@pakyow.org'])
```

Access to the [mail message](https://github.com/mikel/mail) object is also available:

```ruby
mailer = mailer(view_path)
mailer.message.subject = 'Pakyow Rocks!'
mailer.message.add_file('/path/to/file.jpg')
mailer.deliver_to('test@pakyow.org')
```

There are several configuration settings for Mailer. See [configuration](/docs/config) for more information.
