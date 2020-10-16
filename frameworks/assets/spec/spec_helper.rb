start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "pakyow/assets"
require "pakyow/assets/babel"

require_relative "../../../spec/helpers/command_helpers"
require_relative "../../../spec/helpers/mock_handler"
require_relative "../../../spec/helpers/cached_expectation"

module ExpectationCache
  extend RSpec::SharedContext

  let(:expectations_cache_path) {
    Pathname.new(File.expand_path("../expectations", __FILE__))
  }
end

$latest_pakyow_js = "1.1.0-alpha.2"

RSpec.configure do |spec_config|
  spec_config.before do
    @default_app_def = Proc.new do
      configure do
        config.root = File.expand_path("../support/app", __FILE__)
      end

      define_singleton_method :pakyow_js_version do
        $latest_pakyow_js
      end

      after "initialize" do
        self.class.__plugs.each do |plug|
          plug.class_exec do
            define_method :pakyow_js_version do
              $latest_pakyow_js
            end
          end
        end
      end
    end
  end

  spec_config.after do
    Pakyow::Assets::Babel.instance_variable_set(:@context, nil)
  end

  spec_config.include CommandHelpers
  spec_config.include CachedExpectation
  spec_config.include ExpectationCache
end

require_relative "../../../spec/context/app_context"
require_relative "../../../spec/context/command_context"
require_relative "../../../spec/context/suppressed_output_context"
