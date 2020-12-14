require "pakyow/support/deep_dup"

module Pakyow
  # Stub this out globally so it doesn't cause us trouble.
  #
  def self.deep_freeze; end
end

RSpec.configure do |config|
  using Pakyow::Support::DeepDup

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

  if ENV.key?("CI")
    require "rspec/repeat"
    config.include RSpec::Repeat

    config.around :each, :repeatable do |example|
      repeat example, 10.times, verbose: true
    end
  end

  def rss
   `ps -eo pid,rss | grep #{Process.pid} | awk '{print $2}'`.to_i
  end

  config.before :suite do
    require "pastel"
    require "pakyow/application"
    require "pakyow/support/cli/style"
    Pakyow::Support::CLI.instance_variable_set(:@__style, Pastel.new(enabled: true))

    if Pakyow.respond_to?(:config)
      $original_pakyow_config = Pakyow.config
    end

    if Pakyow.instance_variable_defined?(:@__class_state)
      $original_class_state = Pakyow.instance_variable_get(:@__class_state).keys.each_with_object({}) do |class_level_ivar, state|
        unless class_level_ivar == :@__definable_registries
          state[class_level_ivar] = Pakyow.instance_variable_get(class_level_ivar)
        end
      end
    end

    $original_load_path_count = $LOAD_PATH.count

    if ENV["SPEC_PROFILE"] == "memory"
      require "memory_profiler"
      MemoryProfiler.start
    end

    if ENV["SPEC_PROFILE"] && ENV["SPEC_PROFILE"] != "memory"
      require "ruby-prof"
      RubyProf.start
    end
  end

  config.after :suite do
    if ENV["SPEC_PROFILE"] == "memory"
      puts "printing"
      GC.start
      MemoryProfiler.stop.pretty_print
    end

    if ENV["SPEC_PROFILE"] && ENV["SPEC_PROFILE"] != "memory"
      result = RubyProf.stop
      printer = RubyProf::FlatPrinter.new(result)
      printer.print(STDOUT)
    end
  end

  config.before do
    allow($stdout).to receive(:tty?).and_return(true)

    $original_constants = Object.constants

    allow(Process).to receive(:exit)

    cache_config(Pakyow)
    cache_config(Pakyow::Application) if defined?(Pakyow::Application)
    cache_config(Pakyow::Plugin) if defined?(Pakyow::Plugin)

    if defined?(Pakyow::Processes::Environment)
      allow(Pakyow::Processes::Environment).to receive(:trap)
    end

    allow(Pakyow).to receive(:require).and_call_original
    allow(Pakyow).to receive(:require).with("pakyow/integrations/bundler/setup")
    allow(Pakyow).to receive(:require).with("pakyow/integrations/bootsnap")
    allow(Pakyow).to receive(:require).with("pakyow/integrations/bundler/require")
    allow(Pakyow).to receive(:require).with("pakyow/integrations/dotenv")

    if Pakyow.instance_variable_defined?(:@__class_state)
      $original_class_state.each do |ivar, original_value|
        Pakyow.instance_variable_set(ivar, original_value.deep_dup)
      end
    end

    @defined_constants = Module.constants.dup

    allow(Bundler).to receive(:reset!)
  end

  config.after do
    if defined?(Rake)
      Rake.application.clear
    end

    $LOAD_PATH.shift($LOAD_PATH.count - $original_load_path_count)

    if Pakyow.respond_to?(:apps)
      # Cleanup app state.
      #
      Pakyow.apps.each do |app|
        if app.respond_to?(:data)
          app.data&.subscribers&.shutdown
        end
      end
    end

    reset_config(Pakyow::Plugin) if defined?(Pakyow::Plugin)
    reset_config(Pakyow::Application) if defined?(Pakyow::Application)
    reset_config(Pakyow)

    [:@port, :@host, :@logger, :@app, :@output, :@deprecator, :@config, :@error].each do |ivar|
      if Pakyow.instance_variable_defined?(ivar)
        Pakyow.remove_instance_variable(ivar)
      end
    end

    if Object.const_defined?("Pakyow::Presenter::Composers::View")
      Pakyow::Presenter::Composers::View.__cache.clear
    end

    if defined?(Pakyow::Support::Deprecator) && Pakyow::Support::Deprecator.instance_variable_defined?(:@global)
      Pakyow::Support::Deprecator.remove_instance_variable(:@global)
    end

    if Pakyow.respond_to?(:__definable_registries)
      sticky_registries = %i(container)

      Pakyow.__definable_registries.values.each do |registry|
        unless sticky_registries.include?(registry.name)
          registry.instance_variable_set(:@definitions, [])
          registry.instance_variable_set(:@priorities, {})
          registry.instance_variable_set(:@state, {})
        end
      end
    end

    if defined?(Pakyow::Assets::Scripts::Babel)
      Pakyow::Assets::Scripts::Babel.destroy
    end

    if defined?(Pakyow::Assets::Scripts::Terser)
      Pakyow::Assets::Scripts::Terser.destroy
    end

    if defined?(Pakyow::Loader)
      Pakyow::Loader.reset
    end

    remove_constants(
      (Object.constants - $original_constants).select { |constant_name|
        constant_name.to_s.start_with?("Test")
      }.map(&:to_sym)
    )

    if defined?(Pakyow::Commands)
      remove_constants(["Commands"], Pakyow, false)
    end

    if defined?(Pakyow::Generators)
      remove_constants(["Generators"], Pakyow, false)
    end

    if defined?(Pakyow::Support::ThreadLocalizer)
      Pakyow::Support::ThreadLocalizer.thread_localized_store&.clear
    end

    if ENV["RSS"]
      GC.start
      puts "rss: #{rss} live objects (#{GC.stat[:heap_live_slots]})"
    end
  end

  def cache_config(object)
    config = if object.respond_to?(:__settings)
      object
    elsif object.respond_to?(:__config)
      object.__config
    end

    if config
      @config_defaults_cache ||= {}
      @config_blocks_cache ||= {}
      @config_blocks_cache[config.name] ||= {}
      @config_defaults_cache[config.name] ||= {}

      config.__settings.each_value do |setting|
        @config_defaults_cache[config.name][setting.name] = setting.instance_variable_get(:@default).deep_dup
        @config_blocks_cache[config.name][setting.name] = setting.instance_variable_get(:@block).deep_dup
      end

      config.__groups.each_value do |group|
        cache_config(group)
      end
    end
  end

  def reset_config(object)
    config = if object.respond_to?(:__settings)
      object
    elsif object.respond_to?(:__config)
      object.__config
    end

    if config
      config.__settings.each_value do |setting|
        setting.instance_variable_set(:@default, @config_defaults_cache.dig(config.name, setting.name))
        setting.instance_variable_set(:@block, @config_blocks_cache.dig(config.name, setting.name))

        if setting.instance_variable_defined?(:@value)
          setting.remove_instance_variable(:@value)
        end
      end

      config.__groups.each_value do |group|
        reset_config(group)
      end
    end
  end

  def remove_constants(constant_names, within = Object, remove_root = true)
    constant_names.each do |constant_name|
      if within.const_defined?(constant_name, false)
        constant = within.const_get(constant_name, false)

        if constant.respond_to?(:constants)
          remove_constants(constant.constants(false), constant.respond_to?(:remove_const, true) ? constant : within)

          if remove_root
            within.__send__(:remove_const, constant_name)
          end
        end
      end
    end
  end

  def ignore_warnings(&block)
    $warnings.ignore(&block)
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
    actual.to_s.gsub(/\s+/, "").include?(expected.to_s.gsub(/\s+/, ""))
  end

  diffable
end

require "pakyow/support/system"

require "warning"

module Pakyow
  module Support
    # This will eventually make its way into an official warning collector in `pakyow/support`.
    #
    class Warnings
      attr_reader :warnings

      def initialize
        @warnings = []
        @ignoring = false
        @lock = Mutex.new

        Warning.dedup

        ruby_gem_path = Pakyow::Support::System.ruby_gem_path_string
        ruby_lib_path = RbConfig::CONFIG["libdir"]

        Warning.process do |warning|
          next if ignoring?
          next if warning.start_with?(ruby_gem_path)
          next if warning.start_with?(ruby_lib_path)

          # Two warnings are generated for this, combine them.
          #
          if warning.match?(/warning: The called method (.*) is defined here/)
            @lock.synchronize do
              if @warnings.last&.match?(/Using the last argument as keyword parameters is deprecated; maybe \*\* should be added to the call/)
                append_to_last_warning!(warning)
              end
            end
          else
            handle_warning(warning)
          end
        end
      end

      def ignore
        @ignoring = true

        yield
      ensure
        @ignoring = false
      end

      def ignoring?
        @ignoring == true
      end

      private def handle_warning(warning)
        if ENV.include?("CI")
          raise warning
        else
          @lock.synchronize do
            @warnings << warning
          end
        end
      end

      private def append_to_last_warning!(warning)
        return if ENV.include?("CI")

        @warnings.last << warning
      end
    end
  end
end

$pakyow_path = File.expand_path("../../", __FILE__)
$toplevel_pid ||= Process.pid
$warnings = Pakyow::Support::Warnings.new

at_exit do
  if Process.pid == $toplevel_pid && ENV["WARN"] != "false"
    require "pakyow/support/cli/style"

    warnings = $warnings.warnings

    if warnings.any?
      puts Pakyow::Support::CLI.style.yellow("encountered #{warnings.count} warnings:")

      warnings.each do |warning|
        warning = warning.gsub(/^#{$pakyow_path}\//, "")
        warning = warning.strip

        warning.each_line.each_with_index do |line, index|
          if index == 0
            puts Pakyow::Support::CLI.style.yellow("  › ") + line
          else
            puts Pakyow::Support::CLI.style.yellow("    ") + line
          end
        end
      end

      puts
    end
  end
rescue Interrupt
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

def wait_for_redis!(redis_url = ENV["REDIS_URL"] || "redis://127.0.0.1:6379")
  require "redis"

  connected = false
  iterations = 0
  until iterations > 30
    connection = Redis.new(url: redis_url)

    begin
      connection.info
      connected = true
      break
    rescue
      iterations += 1
      sleep 1
    end
  end

  unless connected
    raise RuntimeError, "Could not connect to redis: #{redis_url}"
  end
end
