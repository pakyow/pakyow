# pakyow-test

This gem consists of helpers that you can use to write tests for Pakyow apps.

## Getting Started w/ TestUnit and/or Minitest

Create a `test` folder in the root app folder. In it, create a file named `test_helper.rb` with the following code:

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

Now create files within the `test` directory that follow the `*_test.rb` naming convention and use `rake test` to run the test suite.

## Getting Started w/ Rspec

Create a `spec` folder in the root app folder. In it, create a file named `spec_helper.rb` with the following code:

```ruby
require 'pakyow-test'
Pakyow::TestHelp.setup

RSpec.configure do |config|
  config.include Pakyow::TestHelp::Helpers
end
```

Now create files within the `spec` directory that follow the `*_spec.rb` naming convention and use `spec` to run the specs.

## Simulator Usage

TODO
