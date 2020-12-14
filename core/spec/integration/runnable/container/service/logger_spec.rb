require_relative "../../shared"

RSpec.describe "defining the service logger", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      definitions

      allow(Pakyow.logger).to receive(:warn)
    end

    let(:container_options) {
      { restartable: false }
    }

    let(:definitions) {
      container.service :foo, restartable: false do
        define_method :perform do
          options[:toplevel].notify(logger.class.name)
        end
      end
    }

    it "defaults to the pakyow logger" do
      run_container do
        listen_for length: 1, timeout: 1 do |result|
          expect(result).to eq(["Pakyow::Logger::ThreadLocal"])
        end
      end
    end

    context "service defines a logger" do
      let(:definitions) {
        container.service :foo, restartable: false do
          define_method :perform do
            options[:toplevel].notify(logger.class.name)
          end

          define_method :logger do
            nil
          end
        end
      }

      it "uses the service logger" do
        run_container do
          listen_for length: 1, timeout: 1 do |result|
            expect(result).to eq(["NilClass"])
          end
        end
      end
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
