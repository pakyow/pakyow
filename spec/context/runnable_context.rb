RSpec.shared_context "runnable" do
  before do
    allow($stdout).to receive(:isatty).and_return(false)
    allow(Async::IO::SharedEndpoint).to receive(:bound).and_return(bound_endpoint)
    allow(Pakyow.logger).to receive(:<<)
    allow(::Process).to receive(:exit)

    @container_threads = []

    case runnable_mode
    when :single_service
      # Let containers work as closely to normal containers as possible, stubbing out the parts that
      # depend on actual running services.
      #
      Pakyow.containers.each do |container|
        allow(container).to receive(:new).and_wrap_original do |original, *args, **kwargs, &block|
          instance = container.allocate

          allow(container).to receive(:load_strategy).and_wrap_original do |method, *args|
            method.call(*args).tap do |strategy|
              # Make sure the container immediately stops.
              #
              allow(strategy).to receive(:wait) do
                instance.stop
              end

              # Stub these methods since they expect running services.
              #
              allow(strategy).to receive(:wait_for_service)
              allow(strategy).to receive(:stop)
            end
          end

          instance.send(:initialize, *args, **kwargs, &block)
          instance
        end
      end

      allow(::Process).to receive(:fork) do |&block|
        block.call
      end

      allow(::Process).to receive(:spawn)
    when :multi_service
      # Run each container as normal, but within a thread so that it doesn't block the tests.
      #
      Pakyow.containers.each do |container|
        allow(container).to receive(:new).and_wrap_original do |original, *args, **kwargs, &block|
          instance = original.call(*args, **kwargs, &block)

          allow(instance).to receive(:run).and_wrap_original do |original, &block|
            container_thread = Thread.new {
              original.call(&block)
            }

            @container_threads << container_thread

            # Give the thread time to call the original implementation.
            #
            sleep 0.1
          end

          instance
        end
      end
    else
      fail "unknown runnable mode: #{runnable_mode.inspect}"
    end
  end

  after do
    @container_threads.each do |thread|
      thread.kill; thread.join
    end
  end

  let(:runnable_mode) {
    :multi_service
  }

  let(:bound_endpoint) {
    double(:bound_endpoint, close: nil, accept: nil)
  }

  let(:container_double) {
    instance_double(Pakyow::Runnable::Container, options: {}, stop: nil, success?: true, running?: false)
  }

  def stub_container_run(container)
    allow(Pakyow.container(container)).to receive(:run).and_yield(
      container_double
    )
  end
end
