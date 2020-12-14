require_relative "../../shared"

RSpec.describe "defining the service strategy", :repeatable, runnable: true do
  include_context "runnable container"

  before do
    container.service :foo, restartable: false, strategy: :forked do
      define_method :perform do
        options[:toplevel].notify("foo #{Process.pid} #{Thread.current.object_id}")
      end
    end

    container.service :bar, restartable: false, strategy: :threaded do
      define_method :perform do
        ::Async::Task.current.sleep 0.25
        options[:toplevel].notify("bar #{Process.pid} #{Thread.current.object_id}")
      end
    end
  end

  let(:container_options) {
    { restartable: false }
  }

  it "runs each service in its defined strategy" do
    run_container do
      listen_for length: 2, timeout: 1 do |result|
        foo, bar = result

        _, foo_process, _ = foo.split(" ")
        _, bar_process, bar_thread = bar.split(" ")

        expect(foo_process.to_i).not_to eq(Process.pid)
        expect(bar_process.to_i).to eq(Process.pid)
        expect(bar_thread.to_i).not_to eq(Thread.current.object_id)
      end
    end
  end
end
