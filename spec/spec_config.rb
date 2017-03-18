RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    # TODO This option will default to `true` in RSpec 4. Remove then.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # TODO Will default to `true` in RSpec 4. Remove then
    mocks.verify_partial_doubles = true
  end

  config.filter_run :focus
  config.run_all_when_everything_filtered = true

  config.example_status_persistence_file_path = "spec/examples.txt"
  config.disable_monkey_patching!
  config.warnings = true
  config.color = true

  config.order = :random
  Kernel.srand config.seed
end

def start_simplecov(&block)
  if ENV["COVERAGE"]
    require "simplecov"
    require "simplecov-console"
    SimpleCov.formatter = SimpleCov::Formatter::Console
    SimpleCov.start do
      add_filter "spec/"
      add_filter ".bundle/"
      self.instance_eval(&block) if block_given?
    end
  end
end

require "pry"
require "spec_helper"

ENV["SESSION_SECRET"] = "sekret"

Pakyow::Controller.before :error do
  $stderr.puts req.error

  req.error.backtrace.each do |line|
    $stderr.puts line
  end
end
