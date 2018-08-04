RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    # TODO This option will default to `true` in RSpec 4. Remove then.
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # TODO Will default to `true` in RSpec 4. Remove then
    mocks.verify_partial_doubles = true
  end

  config.disable_monkey_patching!
  config.warnings = true
  config.color = true

  config.order = :random
  Kernel.srand config.seed

  if ENV.key?("CI_BENCH")
    config.filter_run benchmark: true
  else
    config.filter_run_excluding benchmark: true
  end

  if ENV.key?("CI_SMOKE")
    config.filter_run smoke: true
  else
    config.filter_run_excluding smoke: true
  end

  config.before do
    if Pakyow.respond_to?(:config)
      Pakyow.config.freeze_on_boot = false
    end

    allow(Pakyow).to receive(:at_exit)

    if Pakyow.respond_to?(:config)
      @original_pakyow_config = Pakyow.config.dup
    end

    if Pakyow.instance_variable_defined?(:@__class_state)
      @original_class_state = Pakyow.instance_variable_get(:@__class_state).keys.each_with_object({}) do |class_level_ivar, state|
        state[class_level_ivar] = Pakyow.instance_variable_get(class_level_ivar).dup
      end

      allow(Process).to receive(:exit)
    end
  end

  config.after do
    if defined?(Rake)
      Rake.application.clear
    end

    if Pakyow.instance_variable_defined?(:@__class_state)
      @original_class_state.each do |ivar, original_value|
        Pakyow.instance_variable_set(ivar, original_value)
      end

      # duping the builder isn't enough to prevent leaky state
      Pakyow.instance_variable_set(:"@builder", Rack::Builder.new)
    end

    [:@env, :@port, :@host, :@server, :@logger, :@app].each do |ivar|
      Pakyow.remove_instance_variable(ivar) if Pakyow.instance_variable_defined?(ivar)
    end

    if instance_variable_defined?(:@original_pakyow_config)
      Pakyow.instance_variable_set(:@config, @original_pakyow_config)
    end

    if Kernel.const_defined?(:Test)
      Test.constants(false).each do |const_to_unset|
        Test.__send__(:remove_const, const_to_unset)
      end
    end
  end
end

RSpec::Matchers.define :eq_sans_whitespace do |expected|
  match do |actual|
    expected.gsub(/\s+/, "") == actual.gsub(/\s+/, "")
  end

  diffable
end

RSpec::Matchers.define :include_sans_whitespace do |expected|
  match do |actual|
    actual.gsub(/\s+/, "").include?(expected.gsub(/\s+/, ""))
  end

  diffable
end

require "warning"
warnings = []
pakyow_path = File.expand_path("../../", __FILE__)
Warning.process do |warning|
  if warning.start_with?(pakyow_path) && !warning.include?("_spec.rb") && !warning.include?("spec/")
    warnings << warning.gsub(/^#{pakyow_path}\//, "")
  end
end

at_exit do
  if warnings.any?
    require "pakyow/support/cli/style"
    puts Pakyow::Support::CLI.style.yellow "#{warnings.count} warnings were generated:"
    warnings.each do |warning|
      puts Pakyow::Support::CLI.style.yellow("  › ") + warning.strip
    end
    puts
  end
end

def start_simplecov(&block)
  if ENV["COVERAGE"]
    require "simplecov"
    require "simplecov-console"

    SimpleCov::Formatter::Console.table_options = { max_width: 200 }
    SimpleCov.formatter = SimpleCov::Formatter::Console
    SimpleCov.start do
      add_filter "spec/"
      add_filter ".bundle/"
      self.instance_eval(&block) if block_given?
    end
  end
end

require "pry"

ENV["SESSION_SECRET"] = "sekret"
