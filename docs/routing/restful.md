---
name: RESTful APIs
desc: Buidling RESTful APIs.
---

Pakyow has a built-in route [template](/docs/routing/templates) for defining [RESTful APIs](http://en.wikipedia.org/wiki/Representational_state_transfer). Eight actions are supported. Here's an example:

```ruby
Pakyow::App.routes do
  restful :post, '/posts' do
    # GET '/posts'
    list do
      # ...
    end

    # GET '/posts/:post_id'
    show do
      # ...
    end

    # GET '/posts/new'
    new do
      # ...
    end

    # POST '/posts'
    create do
      # ...
    end

    # GET '/posts/:post_id/edit'
    edit do
      # ...
    end

    # PATCH '/posts/:post_id'
    update do
      # ...
    end

    # PUT '/posts/:post_id'
    replace do
      # ...
    end

    # DELETE '/posts/:post_id'
    remove do
      # ...
    end
  end
end
```

Collection and member routes can also be defined:

```ruby
Pakyow::App.routes do
  restful :post '/posts' do
    collection do
    # GET '/posts/some_collection_route'
      get 'some_collection_route' do
        # ...
      end
    end

    member do
      # GET '/posts/:post_id/some_member_route'
      get 'some_member_route' do
        # ...
      end
    end
  end
end
```
