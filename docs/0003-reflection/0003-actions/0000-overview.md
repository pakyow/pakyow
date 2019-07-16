---
title: Actions
---

Actions cause changes in the underlying state of your application, often changing data stored in the database. Reflection is concerned with actions triggered by a user interacting with the interface, such as form submissions. When data needs to be changed, action endpoints are responsible for interacting directly with data sources to create, update, or delete data.

Each reflected action handles the following concerns for you:

1. Verifying that the values submitted through the form are expected, removing values that shouldn't be there. This prevents users from tampering with a form and submitting values that they shouldn't.
2. Validating that the submitted values contain the right information. For example, you might want to ensure that a value looks like an email address.
3. Presenting errors back to the user if verification or validation fails.
4. Saving verified and validated values to the database, either by creating new records, updating existing ones, or deleting records entirely.
5. Redirecting the user to the next page in the application.

Let's look at an example of how an action is defined. Here's a form that defines a `message` binding with a single `content` attribute:

<div class="filename">
  frontend/pages/messages/new.html
</div>

```html
<form binding="message">
  <div class="form-field">
    <input type="text" binding="content" required>
  </div>

  <input type="submit" value="Save">
</form>
```

Reflection defines a matching `messages` data source, which you can inspect using the `info:sources` command:

```
:messages pakyow/reflection
  has_many :replies

  attribute :id,         :bignum
  attribute :content,    :string
  attribute :created_at, :datetime
  attribute :updated_at, :datetime
```

Next, Reflection defines an action that creates messages through the data source. The action is attached at an endpoint, just like the presentation endpoints we discussed in the previous section. Reflection builds endpoints based on REST, or [Representational State Transfer](https://en.wikipedia.org/wiki/Representational_state_transfer). Following RESTful conventions, action endpoints are always defined with a non-`GET` request method.

Here's what the endpoint looks like for the example above:

```
Action Name       HTTP Method  Request Path  Who Defined the Action
-----------       -----------  ------------  ----------------------
:messages_create  POST         /messages     pakyow/reflection
```

The form is automatically configured to submit to the action defined for it. You can see how reflection handles the form submission in the logs. Here's what you would see after submitting a form with valid values:

```
124.00μs http.d5edd133 | POST /messages (for 127.0.0.1 at 2019-07-16 18:52:59 +0000)
  1.58ms http.d5edd133 | [reflection] verified and validated submitted values for `message'
  1.67ms http.d5edd133 | [reflection] performing `messages_create' for `/'
  5.55ms http.d5edd133 | [reflection] changes have been saved to the `messages' data source
 24.44ms http.d5edd133 | [reflection] redirecting to `/messages/13'
 32.77ms http.d5edd133 | 302 (Found)
```

Submissions that don't pass validation are also logged:

```
643.00μs http.984c735c | POST /messages (for 127.0.0.1 at 2019-07-04 15:27:53 +0000)
  4.98ms http.984c735c | INVALID DATA
                       |
                       |   › Provided data didn't pass verification
                       |
                       |   Here's the data:
                       |
                       |       {
                       |         "message": {
                       |           "content": ""
                       |         }
                       |       }
                       |
                       |   And here are the failures:
                       |
                       |       {
                       |         "message": {
                       |           "content": [
                       |             "cannot be blank"
                       |           ]
                       |         }
                       |       }
```

Just for fun, here's what the backend code would look like if we were to write it on our own:

```ruby
resource :messages, "/messages" do
  create do
    verify do
      required :message do
        required :content do
          validate :presence
        end
      end
    end

    created_message = data.messages.create(params[:message]).one

    redirect :messages_show, created_message
  end
end
```

Not only does reflection keep you from writing this code yourself, it automatically reflects changes made in your form. If you add another field to the form, the reflection will expect the new field when it performs the verification step. Writing the code yourself means coordinating changes in the view with changes on the backend, requiring someone to manually update the `verify` block to expect the new field.

Reflection makes your backend actions reactive, updating your backend to immediately reflect frontend changes.
