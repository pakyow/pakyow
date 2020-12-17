require_relative "../shared"

RSpec.describe "running multiple services in a container", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      container.service :foo do
        define_method :perform do
          loop do
            ::Async::Task.current.sleep 0.1

            options[:toplevel].notify("foo")
          end
        end
      end

      container.service :bar do
        define_method :perform do
          loop do
            ::Async::Task.current.sleep 0.1

            options[:toplevel].notify("bar")
          end
        end
      end
    end

    it "runs each service until the container is stopped" do
      run_container do
        listen_for length: 4, timeout: 1 do |result|
          expect(result.count("foo")).to eq(2)
          expect(result.count("bar")).to eq(2)
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

RSpec.describe "running multiple nested service in a container", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      local = self

      container.service :foo do
        define_method :perform do
          options[:toplevel].notify("foo")

          local.run_container_raw(local.container2, context: self)
        end
      end

      container2.service :bar do
        define_method :perform do
          loop do
            ::Async::Task.current.sleep 0.1

            options[:toplevel].notify("bar")
          end
        end
      end

      container2.service :baz do
        define_method :perform do
          loop do
            ::Async::Task.current.sleep 0.1

            options[:toplevel].notify("baz")
          end
        end
      end
    end

    let(:container2) {
      Pakyow::Runnable::Container.make(:test2)
    }

    it "runs the nested services until the top-level container is stopped" do
      run_container do
        listen_for length: 5, timeout: 1 do |result|
          expect(result.count("foo")).to eq(1)
          expect(result.count("bar")).to eq(2)
          expect(result.count("baz")).to eq(2)
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
