---
name: Testing Logging
desc: Writing tests for logging.
---

Logging can be important in some applications. It might be necessary, for
example, to log user access for auditing purposes. The Pakyow test helpers make
it easy to verify that your application is logging to your expectations.

Here's an example route that will log any message passed to it:

```ruby
get :log, '/log' do
  log.info params[:message]
end
```

And here's a test using the `log.include?` helper:

```ruby
describe 'log route' do
  let :message do
    'hello'
  end

  it 'logs the message' do
    get :log, with: { message: message } do
      expect(sim.log).to include(message)
    end
  end
end
```
