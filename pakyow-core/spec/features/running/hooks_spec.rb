require "pakyow/support/system"

RSpec.describe "run hooks" do
  include_context "app"
  include_context "runnable"

  before do
    Pakyow.setup(env: :test)
    Pakyow.config.runnable.server.host = "0.0.0.0"
    Pakyow.config.runnable.server.port = Pakyow::Support::System.available_port
  end

  context "before run hook fails" do
    before do
      Console.logger = Logger.new(IO::NULL)

      Pakyow.before "run" do
        fail
      end
    end

    it "raises the error" do
      expect {
        Pakyow.run
      }.to raise_error(RuntimeError)
    end
  end

  describe "after run hooks" do
    before do
      @calls = []

      Pakyow.after "run", exec: false do
        @calls << "after run"
      end

      Pakyow.after "shutdown", exec: false do
        @calls << "after shutdown"
      end
    end

    it "calls before after shutdown hooks" do
      shutdown_thread = Thread.new do
        sleep 0.25
        Pakyow.shutdown
      end

      Pakyow.run
      shutdown_thread.join
      expect(@calls).to eq(["after run", "after shutdown"])
    end
  end
end
