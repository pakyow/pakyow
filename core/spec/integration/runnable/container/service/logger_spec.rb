require_relative "../../shared"

RSpec.describe "defining the service logger", :repeatable do
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
      local = self

      container.service :foo, restartable: false do
        define_method :perform do
          local.write_to_parent(logger.class.name[0])
        end
      end
    }

    it "defaults to the pakyow logger" do
      run_container do
        wait_for length: 1, timeout: 1 do |result|
          expect(result).to eq("P")
        end
      end
    end

    context "service defines a logger" do
      let(:definitions) {
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            local.write_to_parent(logger.class.name[0])
          end

          define_method :logger do
            nil
          end
        end
      }

      it "uses the service logger" do
        run_container do
          wait_for length: 1, timeout: 1 do |result|
            expect(result).to eq("N")
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
end
