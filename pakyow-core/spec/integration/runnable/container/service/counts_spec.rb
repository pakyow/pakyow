require_relative "../../shared"

RSpec.describe "defining the number of services", :repeatable do
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
          local.write_to_parent("foo")
        end
      end
    }

    it "defaults to one service" do
      run_container do
        wait_for length: 3, timeout: 1 do |result|
          expect(result.scan(/foo/).count).to eq(1)
        end
      end
    end

    context "service defines a count" do
      let(:definitions) {
        local = self

        container.service :foo, restartable: false, count: 3 do
          define_method :perform do
            local.write_to_parent("foo")
          end
        end
      }

      it "runs the correct number of services" do
        run_container do
          wait_for length: 9, timeout: 1 do |result|
            expect(result.scan(/foo/).count).to eq(3)
          end
        end
      end
    end

    context "service sets the count based on an option" do
      let(:run_options) {
        { service_count: 6 }
      }

      let(:definitions) {
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            local.write_to_parent("foo")
          end

          define_method :count do
            options[:service_count]
          end
        end
      }

      it "runs the correct number of services" do
        run_container do
          wait_for length: 18, timeout: 1 do |result|
            expect(result.scan(/foo/).count).to eq(6)
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
