RSpec.describe "running an async task within the environment" do
  before do
    Pakyow.config.server.host = "0.0.0.0"
    allow(Pakyow).to receive(:start_processes).and_return(thread)

    local = self
    Pakyow.before :run do
      async do |task|
        local.instance_variable_set(:@task, task)
        task.sleep 0.1
      end
    end
  end

  let(:thread) {
    Thread.new {}
  }

  it "runs the async task" do
    Pakyow.run

    expect(@task).to be_instance_of(Async::Task)
  end

  it "starts the processes before the task completes" do
    expect(Pakyow).to receive(:start_processes) do
      expect(@task.status).to eq(:running); thread
    end

    Pakyow.run
  end

  context "once the async task completes" do
    it "joins the process thread" do
      expect(thread).to receive(:join) do
        expect(@task.status).to eq(:complete)
      end

      Pakyow.run
    end
  end

  context "async task running when shutting down" do
    before do
      local = self
      Pakyow.before :run do
        async do |task|
          local.instance_variable_set(:@task, task)

          loop do
            task.sleep 0.1
          end
        end
      end
    end

    let(:process_manager) {
      double(:process_manager, stop: nil)
    }

    it "stops the reactor" do
      shutdown_thread = Thread.new do
        sleep 0.25
        Pakyow.shutdown
      end

      Pakyow.run
      shutdown_thread.join
      expect(@task.status).to be(:stopped)
    end
  end
end
