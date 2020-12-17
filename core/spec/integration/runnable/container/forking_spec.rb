require_relative "../shared"

RSpec.describe "hooking into fork events", runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      definitions
      allow(Pakyow).to receive(:houston)
      run_container(timeout: 0.1)
    end

    let(:container_options) {
      { restartable: false }
    }

    let(:definitions) {
      local = self

      container.service :foo, restartable: false do
        define_method :perform do
          # noop
        end
      end

      container.on "fork" do
        local.forked = true
        local.forked_pid = Process.pid
      end
    }

    attr_writer :forked, :forked_pid

    it "calls fork hooks" do
      expect(@forked).to be(true)
    end

    it "calls fork hooks in the process the container is running in" do
      expect(@forked_pid).to be(Process.pid)
    end
  end

  context "forked container" do
    let(:run_options) {
      { strategy: :forked }
    }

    include_examples :examples
  end

  context "threaded container" do
    let(:run_options) {
      { strategy: :threaded }
    }

    include_examples :examples
  end

  context "hybrid container" do
    let(:run_options) {
      { strategy: :hybrid }
    }

    include_examples :examples
  end

  context "async container" do
    let(:run_options) {
      { strategy: :async }
    }

    include_examples :examples
  end
end
