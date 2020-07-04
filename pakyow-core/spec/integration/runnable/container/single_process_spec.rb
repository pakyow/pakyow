require_relative "../shared"

RSpec.describe "running a single service in a container" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      local = self

      container.service :foo do
        define_method :perform do
          loop do
            local.write_to_parent("foo")
          end
        end
      end
    end

    it "runs the service until the container is stopped" do
      run_container do
        wait_for length: 6, timeout: 1 do |result|
          expect(result).to eq("foofoo")
        end
      end
    end
  end

  context "forked container" do
    let(:container_options) {
      { strategy: :forked }
    }

    include_examples :examples
  end

  context "threaded container" do
    let(:container_options) {
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

RSpec.describe "running a single nested service in a container" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      local = self

      container.service :foo do
        define_method :perform do
          local.write_to_parent("foo")

          local.run_container(local.container2, timeout: 1, parent: self)
        end
      end

      container2.service :bar do
        define_method :perform do
          loop do
            local.write_to_parent("bar")
          end
        end
      end
    end

    let(:container2) {
      Pakyow::Runnable::Container.make(:test2, **container_options)
    }

    it "runs the nested service until the top-level container is stopped" do
      run_container do
        wait_for length: 9, timeout: 1 do |result|
          expect(result).to eq("foobarbar")
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
