start_simplecov do
  lib_path = File.expand_path("../../lib", __FILE__)

  add_filter do |file|
    !file.filename.start_with?(lib_path)
  end

  track_files File.join(lib_path, "**/*.rb")
end

require "pakyow/realtime"

require_relative "../../../spec/helpers/mock_handler"

RSpec.configure do |spec_config|
  spec_config.before :suite do
    wait_for_redis!
  end

  spec_config.before do |example|
    require "concurrent/executor/single_thread_executor"

    allow_any_instance_of(Concurrent::SingleThreadExecutor).to receive(:<<) do |_, block|
      block.call
    end
  end

  spec_config.after do
    Pakyow::Realtime::Server.instance_variable_set(:@queue, Queue.new)
  end
end

require_relative "context/websocket_context"
require_relative "../../../spec/context/app_context"
require_relative "../../../spec/context/suppressed_output_context"

$realtime_app_boilerplate = Proc.new do
end
