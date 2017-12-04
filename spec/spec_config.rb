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

  config.filter_run_excluding benchmark: true

  config.before do
    if Pakyow.respond_to?(:config)
      @original_pakyow_config = Pakyow.config.dup
    end
  end

  config.after do
    [:@env, :@port, :@host, :@server, :@mounts, :@builder, :@logger, :@apps, :@mounts].each do |ivar|
      Pakyow.remove_instance_variable(ivar) if Pakyow.instance_variable_defined?(ivar)
    end

    if instance_variable_defined?(:@original_pakyow_config)
      Pakyow.instance_variable_set(:@config, @original_pakyow_config)
    end
  end
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

require "pakyow/support/silenceable"
Pakyow::Support::Silenceable.silence_warnings do
  require "pry"
end

require "spec_helper"

ENV["SESSION_SECRET"] = "sekret"
