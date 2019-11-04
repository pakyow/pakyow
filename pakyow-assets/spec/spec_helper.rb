start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "pakyow/assets"

require_relative "../../spec/helpers/mock_handler"

module GlobalContext
  extend RSpec::SharedContext

  let :latest_pakyow_js do
    @latest_pakyow_js
  end
end

RSpec.configure do |spec_config|
  spec_config.before :all do
    @latest_pakyow_js = `npm show @pakyow/js version`.strip
  end

  spec_config.before do
    local = self
    @default_app_def = Proc.new do
      configure do
        config.root = File.expand_path("../support/app", __FILE__)
      end

      define_method :pakyow_js_version do
        local.latest_pakyow_js
      end

      after "initialize" do
        self.class.__plugs.each do |plug|
          plug.class_exec do
            define_method :pakyow_js_version do
              local.latest_pakyow_js
            end
          end
        end
      end
    end
  end

  spec_config.after do
    Pakyow::Assets::Babel.instance_variable_set(:@context, nil)
  end

  spec_config.include GlobalContext
end

require_relative "../../spec/context/app_context"
require_relative "../../spec/context/suppressed_output_context"
