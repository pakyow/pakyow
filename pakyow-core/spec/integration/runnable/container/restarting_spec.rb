require_relative "../shared"

RSpec.describe "restarting runnable containers" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      @message = "foo"

      local = self

      container.service :foo do
        define_method :perform do
          message = local.message.dup

          loop do
            sleep 0.4

            local.write_to_parent(message)
          end
        end
      end

      run_container(timeout: 1) do |instance|
        sleep 0.6

        @message = "bar"
        instance.restart
      end
    end

    attr_reader :message

    context "container is restartable" do
      it "restarts the container" do
        expect(read_from_child).to eq("foobarbar")
      end
    end

    context "container is not restartable" do
      let(:container_options) {
        { restartable: false }
      }

      it "does not restart" do
        expect(read_from_child).not_to include("bar")
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
end

RSpec.describe "restarting a service that exits successfully" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      local = self

      container.service :foo do
        define_method :perform do
          sleep 0.4

          local.write_to_parent("foo")
        end
      end
    end

    it "restarts the service until the container is stopped" do
      run_container(timeout: 1)

      expect(read_from_child).to eq("foofoo")
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

RSpec.describe "restarting a failing service" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      local = self

      container.service :foo do
        define_method :perform do
          local.write_to_parent("foo")

          fail "something went wrong"
        end
      end
    end

    before do
      allow(Pakyow.logger).to receive(:houston)
    end

    it "restarts the service with backoff until the container is stopped" do
      run_container(timeout: 1)

      expect(read_from_child).to eq("foofoofoo")
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

RSpec.describe "restarting a failing service alongside a running service" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      local = self

      container.service :foo do
        define_method :perform do
          local.write_to_parent("foo")

          fail "something went wrong"
        end
      end

      container.service :bar do
        define_method :perform do
          loop do
            sleep 0.4

            local.write_to_parent("bar")
          end
        end
      end
    end

    before do
      allow(Pakyow.logger).to receive(:houston)
    end

    it "runs the service and backs off the failing service until the container is stopped" do
      run_container(timeout: 4)

      expect(result.scan(/foo/).count).to eq(5)
      expect(result.scan(/bar/).count).to eq(9)
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

RSpec.describe "running an unrestartable container" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      local = self

      container.service :foo, restartable: false do
        define_method :perform do
          local.write_to_parent("foo")
        end
      end

      run_container(timeout: 0.1)
    end

    let(:container_options) {
      { restartable: false }
    }

    it "does not restart" do
      expect(read_from_child).to eq("foo")
    end

    it "appears stopped" do
      expect(container_instance.running?).to eq(false)
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

RSpec.describe "running an unrestartable service in a restartable container" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      local = self

      container.service :foo, restartable: false do
        define_method :perform do
          local.write_to_parent("foo")
        end
      end

      container.service :bar do
        define_method :perform do
          sleep
        end
      end
    end

    it "only runs the service once" do
      run_container(timeout: 0.1)

      expect(read_from_child).to eq("foo")
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

RSpec.describe "running a restartable service in an unrestartable container" do
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

    let(:container_options) {
      { restartable: false }
    }

    it "runs the service until the container is stopped" do
      run_container(timeout: 1)

      expect(read_from_child).to eq("foofoo")
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
