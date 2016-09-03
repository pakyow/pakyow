---
name: Testing Routes
desc: Writing tests for routes and logic.
---

Simulations (described in the overview) are useful for testing the result of
routing application requests. Let's look at an example, then break it down.

```ruby
describe 'default route' do
  it 'succeeds' do
    get '/' do |sim|
      expect(sim.status).to eq(200)
    end
  end
end
```

The first bit looks a lot like a route definition. Here though, we are instead
describing the simulation we want to occur. We want to send a `get` request to
`/`. This would execute the matching route and then return a response.

We can use any of the HTTP methods in place of `get`, including: get, put,
post, patch, and delete. The second argument can be a request path, or we can
use the name of a route.

```ruby
describe 'default route' do
  it 'succeeds' do
    get :default do |sim|
      expect(sim.status).to eq(200)
    end
  end
end
```

We can also test against a named route that's part of a group.

```ruby
describe 'foo/bar route' do
  it 'succeeds' do
    get foo: :bar do |sim|
      expect(sim.status).to eq(200)
    end
  end
end
```

## Response Status Codes

To make sure the route works as we expect, we assert that the resulting status
code is `200`, meaning a request to that path works as we expect it to. We
could also use `:ok` in place of the numerical status code.

```ruby
describe 'default route' do
  it 'succeeds' do
    get :default do |sim|
      expect(sim.status).to eq(:ok)
    end
  end
end
```

## Reponse Types

It's easy to test against the response type.

```ruby
describe 'default route' do
  it 'responds as html' do
    get :default do |sim|
      expect(sim.type).to eq('text/html')
    end
  end
end
```

A user-friendly representation of the response type can also be used.

```ruby
describe 'default route' do
  it 'responds as html' do
    get :default do |sim|
      expect(sim.type).to eq(:html)
    end
  end
end
```

## Request Parameters

Many routes expect input in the form of request parameters. For example, a route
might make a decision based on the value of a particular parameter.

```ruby
get :default do
  handle 400 if params[:foo] = 'bar'
end
```

We can test our route by passing parameter values using the `with` keyword. Any
value passed to `with` will be available in the `params` hash in a route.

```ruby
describe 'default route' do
  context 'when passed a valid parameter' do
    it 'succeeds' do
      get :default, with: { foo: '123' } do |sim|
        expect(sim.status).to eq(200)
      end
    end
  end

  context 'when passed an invalid parameter' do
    it 'handles as bad request' do
      get :default, with: { foo: 'bar' } do |sim|
        expect(sim.status).to eq(400)
      end
    end
  end
end
```

## Sessions &amp; Cookies

Similar to request parameters, we can also set session and cookie values when
setting up a simulation. For example, our route might expect a valid User ID
value in the session for authentication purposes.

```ruby
get :default do
  handle 401 unless User[session[:user_id]]
end
```

We can test our route by passing session data using the `session` keyword.


```ruby
let :user do
  User.create
end

describe 'default route' do
  context 'as an authenticated user' do
    it 'succeeds' do
      get :default, session: { user_id: user.id } do |sim|
        expect(sim.status).to eq(200)
      end
    end
  end

  context 'as an unauthenticated user' do
    it 'handles as unauthorized' do
      get :default, session: { user_id: nil } do |sim|
        expect(sim.status).to eq(401)
      end
    end
  end
end
```

Cookies can be set much the same way using the `cookies` keyword.

## Redirects &amp; Reroutes

Redirecting requests are a common part of application logic. For example, we
might redirect an old URL to the new one.

```ruby
get :about, '/about' do
  # ...
end

get :company, '/company' do
  redirect :about, 301
end
```

This can be tested quite easily using the `redirected?` helper.

```ruby
describe 'company route' do
  it 'redirects' do
    get :company do |sim|
      expect(sim.redirected?).to eq(true)
    end
  end
end
```

It might be importent to know *where* the request was redirected, along with
the type of redirect (since we expect it to be a permanent redirect).

```ruby
describe 'company route' do
  it 'redirects permanently to about' do
    get :company do |sim|
      expect(sim.redirected?(to: :about, as :permanent).to eq(true)
    end
  end
end
```

Reroutes, or internal redirects of application logic within one request, can be
tested in a similar manner. For example, we might define an alias to some other
route as a convenience to the user.

```ruby
get :default do
  reroute :dashboard
end

get :dashboard, '/dashboard' do
  # ...
end
```

This can be tested with the `rerouted?` helper.

```ruby
describe 'default route' do
  it 'reroutes to dashboard' do
    get :default do |sim|
      expect(sim.status).to eq(200)
      expect(sim.rerouted?(to: :dashboard).to eq(true)
    end
  end
end
```

## Rack Env

Any Rack environment variable can be used in a simulation via the `env` keyword.

```ruby
get :default, env: { foo: 'bar' } do
  # ...
end
```

This is useful for testing that routes handle particular HTTP Headers, for example.

## Simulation Contexts

Sometimes it might be necessary to write multiple assertions per simulation (we
saw an example of that in the rerouting test above). In this case it's better
to run the simulation once, then separate each assertion into a single test
case. Fortunately our test helpers make this easy.

```ruby
describe 'default route' do
  let :sim do
    get :default
  end

  it 'succeeds' do
    expect(sim.status).to eq(200)
  end

  it 'reroutes to dashboard' do
    expect(sim.rerouted?(to: :dashboard).to eq(true)
  end
end
```
