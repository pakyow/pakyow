RSpec.shared_context "runnable container" do
  before do
    if run_options[:strategy] == :threaded
      allow(Process).to receive(:exit)
    else
      allow(Process).to receive(:exit).and_call_original
    end
  end

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

  def run_container(container = self.container, timeout: nil, **options)
    final_options = run_options.merge(options)

    container_instance = container.new(**final_options)
    container_instance.options[:container_instance] = container_instance

    thread = Thread.new {
      container_instance.run
    }

    yield container_instance if block_given?
    sleep timeout if timeout

    container_instance.stop

    begin
      with_timeout 1 do
        thread.join
      end
    rescue Timeout::Error
      thread.kill
    end

    container_instance
  rescue Timeout::Error => error
    container_instance.stop
    thread.kill; raise error
  end

  def write_to_parent(value)
    parent_socket.sendmsg(value)
  end

  def read_from_child
    with_timeout(3) do
      child_socket.recv(4096)
    end
  end

  def wait_for(length:, timeout: nil)
    with_timeout(timeout) do
      start = Time.now
      result = String.new

      until result.length >= length
        result << child_socket.recv(4096)
      end

      if block_given?
        yield result[0...length], Time.now - start
      end
    end
  end

  def with_timeout(timeout, &block)
    if timeout
      Timeout.timeout(timeout, &block)
    else
      yield
    end
  end
end
