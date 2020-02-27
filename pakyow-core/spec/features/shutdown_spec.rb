RSpec.describe "shutting down the environment" do
  before do
    allow(Pakyow).to receive(:exit)
    allow(Pakyow.logger).to receive(:houston)
    allow(Pakyow.logger).to receive(:<<)
    allow(Pakyow).to receive(:start_processes).and_return(instance_double(Thread, join: nil))

    @at_exit_block = nil
    allow(Pakyow).to receive(:at_exit) do |&block|
      @at_exit_block = block
    end

    apps

    Pakyow.run
  end

  after do
    if Pakyow.instance_variable_defined?(:@__process_thread)
      Pakyow.remove_instance_variable(:@__process_thread)
    end
  end

  let(:apps) {
    Pakyow.app :test_1 do
      attr_reader :did_shutdown

      on "shutdown" do
        @did_shutdown = true
      end
    end

    Pakyow.app :test_2 do
      attr_reader :did_shutdown

      on "shutdown" do
        @did_shutdown = true
      end
    end
  }

  def shutdown
    Pakyow.shutdown

    # Pretend to be a child process.
    #
    allow(Process).to receive(:pid).and_return(42)

    @at_exit_block.call
  end

  it "shuts down each app" do
    shutdown

    expect(Pakyow.app(:test_1).did_shutdown).to be(true)
    expect(Pakyow.app(:test_2).did_shutdown).to be(true)
  end

  describe "handling application shutdown errors" do
    let(:apps) {
      local = self
      Pakyow.app :test_1 do
        on "shutdown" do
          raise local.error
        end
      end

      Pakyow.app :test_2 do
        attr_reader :did_shutdown

        on "shutdown" do
          @did_shutdown = true
        end
      end
    }

    let(:error) {
        begin
          fail "something went wrong"
        rescue => error
          error
        end
      }

    it "rescues the application" do
      shutdown

      expect(Pakyow.app(:test_1).rescued?).to be(true)
    end

    it "shuts down other applications" do
      shutdown

      expect(Pakyow.app(:test_2).did_shutdown).to be(true)
    end
  end
end
