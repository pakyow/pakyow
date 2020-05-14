require_relative "../shared"

RSpec.describe "running a single service in a container" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      local = self

      container.service :foo do
        define_method :perform do
          loop do
            sleep 0.4

            local.write_to_parent("foo")
          end
        end
      end
    end

    it "runs the service until the container is stopped" do
      run_container(timeout: 1)

      expect(read_from_child).to eq("foofoo")
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
            sleep 0.4

            local.write_to_parent("bar")
          end
        end
      end
    end

    let(:container2) {
      Pakyow::Runnable::Container.make(:test2)
    }

    it "runs the nested service until the top-level container is stopped" do
      run_container(timeout: 1)

      expect(result).to eq("foobarbar")
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
