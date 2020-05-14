require_relative "../../shared"

RSpec.describe "limiting the number of services" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      local = self

      container.service :foo, restartable: false, limit: 2 do
        define_method :perform do
          local.write_to_parent("foo")
        end
      end

      allow(Pakyow.logger).to receive(:warn)
    end

    let(:container_options) {
      { restartable: false }
    }

    let(:run_options) {
      { formation: Pakyow::Runnable::Formation.all(3) }
    }

    it "limits the number of services" do
      run_container do
        wait_for length: 6, timeout: 1 do |result|
          expect(result.scan(/foo/).count).to eq(2)
        end
      end
    end

    it "communicates to the user that the service was limited" do
      run_container timeout: 0.1

      expect(Pakyow.logger).to have_received(:warn).with("attempted to run service `test.foo' 3 times, but was limited to 2")
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
end
