require_relative "../shared"

RSpec.describe "signaling runnable containers" do
  include_context "runnable container"

  # We can only test forked here because threaded services run in this process.
  #
  let(:run_options) {
    { strategy: :forked }
  }

  let(:container_options) {
    { restartable: false }
  }

  before do
    local = self

    container.service :foo, restartable: false do
      define_method :perform do
        local.run_container(local.container2, timeout: 1, parent: self)
      end
    end

    container2.service :bar do
      define_method :perform do
        local.write_to_parent("bar: perform")

        sleep
      end

      define_method :stop do
        local.write_to_parent("bar: stop")
      end
    end

    run_container do |instance|
      sleep 0.1

      @pid = instance.instance_variable_get(:@strategy).instance_variable_get(:@services).first.reference

      ::Process.kill(signal, @pid)

      sleep 0.1
    end
  end

  let(:container2) {
    Pakyow::Runnable::Container.make(:test2)
  }

  describe "signaling a container: INT" do
    let(:signal) {
      "INT"
    }

    it "cleanly stops each process" do
      expect(result).to include("bar: stop")
    end
  end

  describe "signaling a container: TERM" do
    let(:signal) {
      "TERM"
    }

    it "forces each process to stop" do
      expect(result).not_to include("bar: stop")
    end
  end

  describe "signaling a container: HUP" do
    let(:signal) {
      "HUP"
    }

    context "container is restartable" do
      let(:container2) {
        Pakyow::Runnable::Container.make(:test2, restartable: true)
      }

      it "restarts the container" do
        expect(result).to include("bar: stop")
      end
    end

    context "container is not restartable" do
      let(:container2) {
        Pakyow::Runnable::Container.make(:test2, restartable: false)
      }

      it "ignores the signal" do
        expect(result).to eq("bar: perform")
      end
    end
  end
end
