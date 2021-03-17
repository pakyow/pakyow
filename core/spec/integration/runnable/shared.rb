require "timeout"

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

  let(:messages) {
    []
  }

  let(:container_timeout) {
    1
  }

  def run_container_raw(container, context:, **options)
    final_options = context.options.merge(
      parent: context
    ).merge(options)

    instance = container.new(**final_options)
    instance.options[:container] = instance

    Pakyow.async {
      instance.run
    }.wait
  end

  def run_container(container = self.container, timeout: nil, **options)
    final_options = run_options.merge(options)
    final_options[:timeout] ||= container_timeout

    instance = container.new(**final_options)
    instance.options[:toplevel] = instance
    instance.options[:container] = instance

    instance.listen do |message|
      messages << message
    end

    thread = Thread.new {
      Pakyow.async {
        instance.run
      }.wait
    }

    until instance.running?
      sleep 0.25
    end

    yield instance if block_given?
    sleep timeout if timeout

    Timeout.timeout(15) do
      instance.stop
      thread.join
      instance
    end
  end

  def listen_for(length:, timeout: nil)
    with_timeout(timeout) do |task|
      start = Time.now

      until messages.length >= length
        task.sleep 0.1
      end

      yield messages.take(length), Time.now - start if block_given?
    end
  end

  def with_timeout(timeout)
    if timeout
      Async { |task|
        task.with_timeout(timeout) do
          yield task
        end
      }.wait
    else
      yield
    end
  end
end
