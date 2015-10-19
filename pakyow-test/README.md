# pakyow-test

Helpers for testing in Pakyow.

## Getting Started w/ TestUnit and/or Minitest

Create a `test` folder in the root app folder. In it, create a file named
`test_helper.rb` with the following code:

```ruby
require 'pakyow-test'
Pakyow::TestHelp.setup
```

Follow the rest of the instructions to gain access to helper methods.

### Test::Unit

class Test::Unit::TestCase
  include Pakyow::TestHelp::Helpers
end

### Minitest

class MiniTest::Unit::TestCase
  include Pakyow::TestHelp::Helpers
end

### MiniTest::Spec

class MiniTest::Spec
  include Pakyow::TestHelp::Helpers
end

---

Next, open up your `Rakefile` and define the following:

```ruby
require 'rake/testtask'

desc "Run the pakyow test suite"
Rake::TestTask.new("test") do |t|
  t.libs << 'test'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = false
  t.warning = false
end
```

Now create files within the `test` directory that follow the `*_test.rb` naming
convention and use `rake test` to run the test suite.

## Getting Started w/ Rspec

Create a `spec` folder in the root app folder. In it, create a file named
`spec_helper.rb` with the following code:

```ruby
require 'pakyow-test'
Pakyow::TestHelp.setup

RSpec.configure do |config|
  config.include Pakyow::TestHelp::Helpers
end
```

Now create files within the `spec` directory that follow the `*_spec.rb` naming
convention and use `spec` to run the specs.

## Usage

Check out the testing docs. It also might be helpful to take a look at the
integration tests for pakyow-test itself:

- https://github.com/pakyow/pakyow/tree/master/pakyow-test/spec/integration

# Download

The latest version of Pakyow Test can be installed with RubyGems:

```
gem install pakyow-test
```

Source code can be downloaded as part of the Pakyow project on Github:

- https://github.com/pakyow/pakyow/tree/master/pakyow-test

# License

Pakyow Test is released free and open-source under the [MIT
License](http://opensource.org/licenses/MIT).

# Support

Documentation is available here:

- http://pakyow.org/docs/testing

Found a bug? Tell us about it here:

- https://github.com/pakyow/pakyow/issues

We'd love to have you in the community:

- http://pakyow.org/get-involved
