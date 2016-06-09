---
name: Testing Presentation
desc: Writing tests for presentation logic.
---

As we learned in the overview, Pakyow makes it easy to write tests for the
presentation layer. We can test that the right view is used in a route, but the
usefulness grows well beyond this simple case. It's also possible to write more
advanced view tests, such as testing that the expected scopes are available in
the view. Finally, we can test that our data is bound into the view correctly.

View tests help enforce a contract between the back-end and front-end developers
working on a Pakyow project. Because views are defined separately from back-end
logic, we can only make assumptions. Wrapping tests around our expectations
helps protect from changes that inadvertantly break part of the application.

Let's start with a simple example. Here's a route that renders a view other than
the default one (in this case it would render the view at path `/` by default):

```ruby
get :default do
  presenter.path = 'sub'
end
```

Since this is not default behavior of the framework, let's write a test for it.

```ruby
describe 'default route' do
  it 'renders the sub view' do
    get :default do |sim|
      expect(sim.presenter.path).to eq('sub')
    end
  end
end
```

Here we use the `presenter` helper to ask questions about the state of the view
after the route executes. This is one of the simplest view tests we can write.

## View Scopes

Pakyow views contain scopes, which define nodes that represent data.

```html
<div data-scope="post">
  <p data-prop="body">
    this is a post
  </p>
</div>
```

Assuming this view is rendered by the `default` route, we can test that it
contains the scope we expect it to contain.

```ruby
describe 'default route' do
  it 'renders a view that contains a post scope' do
    expect(sim.view.scope?(:post)).to eq(true)
  end
end
```

## View Transformation

It's rare to render a scope without some back-end logic acting on it. Here's a
route that applies some data to the view (the same view from the "View Scopes"
section above).

```ruby
get :default do
  view.scope(:post).apply(params[:data])
end
```

This application logic should be well tested, and we can do that easily.

```ruby
describe 'default route' do
  let :data do
    [{ body: 'one' }]
  end

  it 'applies data to the view' do
    get :default, with: { data: data } do |sim|
      sim.view.scope(:post).with do |view|
        expect(view.applied?(data)).to eq(true)
      end
    end
  end
end
```

You'll notice the use of `with` in the above example. This, along with `for`
(seen in the next example) work exactly like they do outside of testing. In
fact, it's still using the underlying `View` object.

Let's go a step further and assert that particular values were bound.

```ruby
describe 'default route' do
  let :data do
    [{ body: 'one' }]
  end

  it 'binds proper values to the view' do
    get :default, with: { data: data } do |sim|
      sim.view.scope(:post).for(data) do |view, datum|
        expect(view.prop(:title).bound?(datum[:title])).to eq(true)
      end
    end
  end
end
```

We used `apply` in the above example, but you can write assertions against other
view transformation methods too, including `bind`, `match`, and `repeat`.

## View Attributes

The back-end often makes changes to view attributes. We can test that these
changes occur as we expect by writing assertions for the final values.

```ruby
describe 'default route' do
  it 'changes the view class' do
    get :default do |sim|
      expect(sim.view.scope(:post)[0].attrs.class.value).to eq(['foo'])
    end
  end
end
```

## View Manipulation

Other view manipulations can occur from the back-end that need to be tested. For
example, a route could remove a particular scope from the view.

```ruby
get :default do |sim|
  expect(sim.view.scope(:post).exists?).to be(false)
end
```

We can also check that another view was appended to the view:

```ruby
get :default do |sim|
  expect(sim.view.scope(:post).appended?(view)).to be(true)
end
```

We can write similar tests for other view manipulation methods, including:
`prepend`, `before`, `after`, and `replace`.

## Other View Tests

Most aspects of a rendered view can be tested. For example, we could assert that
a view uses a particular template:

```ruby
get :default do |sim|
  expect(sim.view.template.name).to eq(:default)
end
```

Or, that the title of the view is what we expect:

```ruby
get :default do |sim|
  expect(sim.view.title).to eq('my page title')
end
```

The more knowledge you gain of Pakyow's inner workings, the more tests you'll be
able to identify and write. Hopefully this guide is a good start!
