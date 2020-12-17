require_relative "../shared"

RSpec.describe "running a single service in a container", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      container.service :foo do
        define_method :perform do
          loop do
            options[:container].notify("foo")

            ::Async::Task.current.sleep 0.25
          end
        end
      end
    end

    it "runs the service until the container is stopped" do
      run_container do
        listen_for length: 2, timeout: 1 do |result|
          expect(result).to eq(["foo", "foo"])
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

RSpec.describe "running a single nested service in a container", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      local = self

      container.service :foo do
        define_method :perform do
          options[:container].notify("foo")

          local.run_container_raw(local.container2, context: self)
        end
      end

      container2.service :bar do
        define_method :perform do
          loop do
            options[:toplevel].notify("bar")

            ::Async::Task.current.sleep 0.25
          end
        end
      end
    end

    let(:container2) {
      Pakyow::Runnable::Container.make(:test2, **container_options)
    }

    it "runs the nested service until the top-level container is stopped" do
      run_container do
        listen_for length: 3, timeout: 1 do |result|
          expect(result).to eq(["foo", "bar", "bar"])
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
