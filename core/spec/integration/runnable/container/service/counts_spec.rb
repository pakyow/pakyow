require_relative "../../shared"

RSpec.describe "defining the number of services", :repeatable, runnable: true do
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
          options[:toplevel].notify("foo")
        end
      end
    }

    it "defaults to one service" do
      run_container do
        listen_for length: 1, timeout: 1 do |result|
          expect(result.count("foo")).to eq(1)
        end
      end
    end

    context "service defines a count" do
      let(:definitions) {
        container.service :foo, restartable: false, count: 3 do
          define_method :perform do
            options[:toplevel].notify("foo")
          end
        end
      }

      it "runs the correct number of services" do
        run_container do
          listen_for length: 3, timeout: 1 do |result|
            expect(result.count("foo")).to eq(3)
          end
        end
      end
    end

    context "service sets the count based on an option" do
      let(:run_options) {
        { service_count: 6 }
      }

      let(:definitions) {
        container.service :foo, restartable: false do
          define_method :perform do
            options[:toplevel].notify("foo")
          end

          define_method :count do
            options[:service_count]
          end
        end
      }

      it "runs the correct number of services" do
        run_container do
          listen_for length: 6, timeout: 1 do |result|
            expect(result.count("foo")).to eq(6)
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
