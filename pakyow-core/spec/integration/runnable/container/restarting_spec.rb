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
            sleep 0.1

            local.write_to_parent(message)
          end
        end
      end
    end

    def restart(instance)
      sleep 0.15
      @message = "bar"
      instance.restart
    end

    attr_reader :message

    context "container is restartable" do
      it "restarts the container" do
        run_container do |instance|
          restart(instance)

          wait_for length: 9, timeout: 1 do |result|
            expect(result.scan(/foo/).count).to eq(1)
            expect(result.scan(/bar/).count).to eq(2)
          end
        end
      end
    end

    context "container is not restartable" do
      let(:container_options) {
        { restartable: false }
      }

      it "does not restart" do
        run_container do |instance|
          restart(instance)

          wait_for length: 9, timeout: 1 do |result|
            expect(result.scan(/foo/).count).to eq(3)
            expect(result.scan(/bar/).count).to eq(0)
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

RSpec.describe "restarting a service that exits successfully" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      local = self

      container.service :foo do
        define_method :perform do
          local.write_to_parent("foo")
        end
      end
    end

    it "restarts the service until the container is stopped" do
      run_container do
        wait_for length: 9, timeout: 1 do |result|
          expect(result.scan(/foo/).count).to eq(3)
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
      run_container do
        wait_for length: 9, timeout: 1 do |result, elapsed|
          expect(result.scan(/foo/).count).to eq(3)
          expect(elapsed).to be > 0.5
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
            local.write_to_parent("bar")
          end
        end
      end
    end

    before do
      allow(Pakyow.logger).to receive(:houston)
    end

    it "runs the service and backs off the failing service until the container is stopped" do
      run_container do
        wait_for length: 21, timeout: 1 do |result, elapsed|
          expect(result.scan(/foo/).count).to be < 4
          expect(result.scan(/bar/).count).to be > 4
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

  context "hybrid container" do
    let(:run_options) {
      { strategy: :hybrid }
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

  context "hybrid container" do
    let(:run_options) {
      { strategy: :hybrid }
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
            local.write_to_parent("foo")
          end
        end
      end
    end

    let(:container_options) {
      { restartable: false }
    }

    it "runs the service until the container is stopped" do
      run_container do
        wait_for length: 9, timeout: 1 do |result|
          expect(result).to eq("foofoofoo")
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
