RSpec.shared_context "runnable container" do
  let(:container) {
    Pakyow::Runnable::Container.make(:test, **container_options)
  }

  let(:container_options) {
    {}
  }

  let(:run_options) {
    {}
  }

  let!(:sockets) {
    Socket.pair(:UNIX, :STREAM, 0)
  }

  let(:child_socket) {
    sockets[0]
  }

  let(:parent_socket) {
    sockets[1]
  }

  let(:result) {
    read_from_child
  }

  attr_reader :container_instance

  def run_container(container = self.container, timeout: nil, **options)
    final_options = run_options.merge(options)

    if final_options[:strategy] == :threaded
      allow(Process).to receive(:exit)
    else
      allow(Process).to receive(:exit).and_call_original
    end

    @container_instance = container.new

    thread = Thread.new {
      @container_instance.run(**final_options)
    }

    yield @container_instance if block_given?
    sleep timeout if timeout

    @container_instance.stop
    thread.kill; thread.join
  end

  def write_to_parent(value)
    parent_socket.sendmsg(value)
  end

  def read_from_child
    Timeout.timeout(3) do
      child_socket.recv(4096)
    end
  end
end
