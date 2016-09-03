---
name: Email Notifications
desc: Capturing failures as email notifications.
---

This plugin sends failure notifications via email. To use it, first add `pakyow-fail-mail` to your Gemfile:

```ruby
gem "pakyow-fail-mail"
```

Then define the following config option under the appropriate environment in `app.rb`:

```ruby
fail.mail_to     # where to send failures
```

The following optional config option is also available:

```ruby
fail.mail_sender # who the message should be sent as (default: {app.name} Fail)
```
