---
title: Mailer
---

Pakyow provides the following **application** config options for mailer:

* <a href="#mailer.default_sender" name="mailer.default_sender">`mailer.default_sender`</a>: Name to use as the sender when unspecified by a mailer.
<span class="default">Default: `"Pakyow"`</span>

* <a href="#mailer.delivery_method" name="mailer.delivery_method">`mailer.delivery_method`</a>: The delivery method to use.
<span class="default">Default: `:sendmail`</span>

* <a href="#mailer.delivery_options" name="mailer.delivery_options">`mailer.delivery_options`</a>: Options to use when delivering mail.
<span class="default">Default: `{}`</span>

* <a href="#mailer.encoding" name="mailer.encoding">`mailer.encoding`</a>: Encoding to use for messages.
<span class="default">Default: `"UTF-8"`</span>

* <a href="#mailer.silent" name="mailer.silent">`mailer.silent`</a>: If `true`, outgoing mail will not be logged.
<span class="default">Default: `true`; `false` in *development*</span>
