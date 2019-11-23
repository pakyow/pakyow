RSpec.describe "run hooks" do
  before do
    Pakyow.config.server.host = "0.0.0.0"
    allow(Pakyow).to receive(:start_processes).and_return(thread)
  end

  let(:thread) {
    Thread.new {}
  }

  context "before run hook fails" do
    before do
      Console.logger = Logger.new(IO::NULL)

      Pakyow.before "run" do
        fail
      end
    end

    it "handles gracefully" do
      expect {
        Pakyow.run
      }.not_to raise_error
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
