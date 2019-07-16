---
title: Customizing reflected endpoints
---

Reflection is designed to integrate with any existing backend endpoints that might exist in your project. It extends your application with endpoints only when the doesn't already exist. This gives you a way to replace a reflected endpoint entirely, or extend it to fit your specific needs.

## Replacing an endpoint

You can replace a reflected endpoint by defining it yourself. Reflection does not require you to setup your backend endpoints in any particular structure, instead it just looks for a route that matches the request path for the endpoint.

Let's look at an example. In this case, we'll define an endpoint for presenting messages at the root path in our application. Endpoints are defined within controllers, like this:

<div class="filename">
  backend/controllers/default.rb
</div>

```ruby
controller "/" do
  default do
    # Custom behavior can be performed here.
  end
end
```

The `"/"` argument defines the request path that the controller is mounted at. Within the controller is a `default` route that matches requests to `GET /`. Defining the controller with a default route is all that's required to replace the reflected behavior. Reflection will see that an endpoint already exists and will step aside and let the custom code handle requests.

## Extending an endpoint with operations

Endpoints can be extended rather than completely replaced. There are a couple of ways to do this depending on what exactly you need to do. The first approach is to extend the `reflect` operation.

Operations are a backend feature in Pakyow that let you define a sequence of steps to perform in order. Most of the business logic for an application will be defined in operations, and reflection is no exception. There's only a single step in the `reflect` operation that pertains to endpoints:

* `expose`: Exposes datasets for every binding in the related view template.

Operations can be extended at runtime, injecting custom behavior where you need it. Each step is defined as an "action" on the operation. Here's how you can extend the `reflect` operation to replace the `expose` step:

```ruby
controller "/" do
  default do
    operations.reflect do
      action :expose do
        # Custom behavior goes here.
      end
    end
  end
end
```

Custom behavior you define in the new `expose` action will be used instead of the default behavior defined by reflection.

You can also insert new steps into the operation. Here's how you can add behavior before the `expose` step:

```ruby
controller "/" do
  default do
    operations.reflect do
      action :custom, before: :expose do
        # Custom behavior goes here.
      end
    end
  end
end
```

Now the entire `reflect` operation will be called, but your custom behavior will be called before the built-in `expose` behavior.

## Extending an action with helpers

Reflection makes several helper methods available for you to use. You can use these helpers as primitives to build your own custom behavior with. Here's a list of available endpoint helpers:

`with_reflected_endpoint`

Lets you safely perform behavior if a reflected endpoint is available.

```ruby
with_reflected_endpoint do |endpoint|
  # only called if a reflected endpoint is available
end
```

`reflective_expose`

Exposes a dataset for every binding in the view template.
