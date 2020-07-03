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
    end

    let(:container_options) {
      { restartable: false }
    }

    it "does not restart" do
      run_container timeout: 0.1 do
        expect(read_from_child).to eq("foo")
      end
    end

    it "appears stopped" do
      run_container timeout: 0.1 do |container|
        expect(container.running?).to eq(false)
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

RSpec.describe "running an unrestartable service in a restartable container" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      local = self

      container.service :foo, restartable: false do
        define_method :perform do
          local.write_to_parent(options[:message])
        end
      end

      container.service :bar do
        define_method :perform do
          sleep
        end
      end
    end

    let(:run_options) {
      { message: "foo" }
    }

    it "only runs the service once" do
      run_container(timeout: 0.1)

      expect(read_from_child).to eq("foo")
    end

    it "restarts the service along with the container" do
      run_container(timeout: 0.2) do |instance|
        sleep 0.1
        instance.options[:message] = "bar"
        instance.restart
      end

      expect(read_from_child).to eq("foobar")
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

RSpec.describe "restarting runnable containers from other processes" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      definitions
    end

    let(:definitions) {
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

      container.service :bar, restartable: false do
        define_method :perform do
          sleep 0.15
          options[:container_instance].restart
        end
      end
    }

    attr_reader :message

    it "restarts the container" do
      run_container do
        sleep 0.15
        @message = "bar"
        wait_for length: 9, timeout: 1 do |result|
          expect(result.scan(/foo/).count).to eq(1)
          expect(result.scan(/bar/).count).to eq(2)
        end
      end
    end

    context "container defines an on restart hook" do
      let(:definitions) {
        @message = "foo"

        local = self

        container.on :restart, exec: false do |**payload|
          @payload = payload
        end

        container.service :foo, restartable: false do
          define_method :perform do
            options[:container_instance].restart(foo: "bar")
          end
        end
      }

      attr_reader :payload

      it "calls the hook with provided options" do
        run_container do
          sleep 0.1

          expect(@payload).to eq(foo: "bar")
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
