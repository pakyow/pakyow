---
title: Customizing reflected actions
---

Reflection is designed to integrate with any existing backend actions that might exist in your project. It extends your application with actions only when the doesn't already exist. This gives you a way to replace a reflected action entirely, or extend it to fit your specific needs.

## Replacing an action

You can replace a reflected action by defining an action yourself. Let's look at an example. In this case, we'll assume that we need an action for creating messages through a form defined on the frontend. Pakyow expects you to define the action at a route that follows RESTful conventions for request method and path.

When reflection looks for an existing action, it only looks for routes that match the method and path. Reflection does not require you to setup your backend endpoints in any particular structure.

Here's how you would define an action for `create` within the `messages` resource:

<div class="filename">
  backend/resources/messages.rb
</div>

```ruby
resource :messages, "/messages" do
  create do
    # Custom behavior can be performed here.
  end
end
```

The `:messages` argument defines the type of data our resource is for, while the second `/messages` argument defines the request path that the resource is mounted at. Defining the resource with a create action is all that's required to replace the reflected behavior. Reflection will see that an action already exists and will step aside and let the custom code handle these form submissions.

## Extending an action with operations

Actions can be extended rather than completely replaced. There are a couple of ways to do this depending on what exactly you need to do. The first approach is to extend the `reflect` operation.

Operations are a backend feature in Pakyow that let you define a sequence of steps to perform in order. Most of the business logic for an application will be defined in operations, and reflection is no exception. Here are the steps defined on the `reflect` operation as it pertains to actions:

* `verify`: Verifies and validates submitted values, raising an error if it encounters invalid data.
* `perform`: Performs the business logic for the action, such as creating data in the database.
* `redirect`: Redirects the user to a logical endpoint after the action is performed.

Operations can be extended at runtime, injecting custom behavior where you need it. Each step is defined as an "action" on the operation (not to be confused with the action endpoint on the resource). Here's how you can extend the `reflect` operation to replace the `perform` step:

```ruby
resource :messages, "/messages" do
  create do
    operations.reflect do
      action :perform do
        # Custom behavior goes here.
      end
    end
  end
end
```

The operation will still handle `verify` and `redirect`, which take place before and after `perform`. Custom behavior you define in the `perform` action will be used instead of the default perform behavior defined by reflection.

You can also insert new steps into the operation. Here's how you can add behavior after the `perform` step:

```ruby
resource :messages, "/messages" do
  create do
    operations.reflect do
      action :custom, after: :perform do
        # Custom behavior goes here.
      end
    end
  end
end
```

Now the entire `reflect` operation will be called, but your custom behavior will be called between the default `perform` and `redirect` behavior.

## Extending an action with helpers

Reflection makes several helper methods available for you to use. You can use these helpers as primitives to build your own custom behavior with. Here's a list of available action helpers:

`with_reflected_action`

Lets you safely perform behavior if a reflected action is available.

```ruby
with_reflected_action do |action|
  # only called if a reflected action is available
end
```

`verify_reflected_form`

Performs verification and validation on a form submission.

`perform_reflected_action`

Performs the behavior for the action, creating, updating, or deleting data as necessary.

`redirect_to_reflected_destination`

Redirects the user to the logical destination for the action.

`reflected_destination`

Returns the path to the destination for the action. Does not perform the redirect.
