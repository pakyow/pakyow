require_relative "../../shared"

RSpec.describe "defining the service strategy" do
  include_context "runnable container"

  before do
    local = self

    container.service :foo, restartable: false, strategy: :forked do
      define_method :perform do
        local.write_to_parent("foo #{Process.pid} #{Thread.current.object_id}")
      end
    end

    container.service :bar, restartable: false, strategy: :threaded do
      define_method :perform do
        sleep 0.25
        local.write_to_parent("bar #{Process.pid} #{Thread.current.object_id}")
      end
    end
  end

  let(:container_options) {
    { restartable: false }
  }

  it "runs each service in its defined strategy" do
    run_container do
      sleep 0.5

      foo, bar = result.split("bar")
      _, foo_process, foo_thread = foo.split(" ")
      bar_process, bar_thread = bar.split(" ")

      expect(foo_process.to_i).not_to eq(Process.pid)
      expect(bar_process.to_i).to eq(Process.pid)
      expect(bar_thread.to_i).not_to eq(Thread.current.object_id)
    end
  end
end
