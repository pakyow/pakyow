require_relative "../shared"

RSpec.describe "restarting runnable containers", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      @message = "foo"

      local = self

      container.service :foo do
        define_method :perform do
          message = local.message.dup
          options[:toplevel].notify(message)
          ::Async::Task.current.sleep 10
        end
      end
    end

    def restart(instance)
      sleep 1
      @message = "bar"
      instance.restart
    end

    attr_reader :message

    context "container is restartable" do
      it "restarts the container" do
        run_container do |instance|
          listen_for length: 1, timeout: 1 do |result|
            expect(result.count("foo")).to eq(1)
          end

          restart(instance)

          listen_for length: 2, timeout: 1 do |result|
            expect(result.count("bar")).to eq(1)
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

          with_timeout 1 do
            expect(messages).to eq(["foo"])
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

RSpec.describe "restarting a service that exits successfully", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      container.service :foo do
        define_method :perform do
          options[:toplevel].notify("foo")
        end
      end
    end

    it "restarts the service until the container is stopped" do
      run_container do
        listen_for length: 3, timeout: 1 do |result|
          expect(result.count("foo")).to eq(3)
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

RSpec.describe "restarting a failing service", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      container.service :foo do
        define_method :perform do
          options[:toplevel].notify("foo")

          fail "something went wrong"
        end
      end
    end

    before do
      allow(Pakyow.logger).to receive(:houston)
    end

    it "restarts the service with backoff until the container is stopped" do
      run_container do
        listen_for length: 3, timeout: 1 do |result, elapsed|
          expect(result.count("foo")).to eq(3)
          expect(elapsed).to be > 0.2
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

RSpec.describe "restarting a failing service alongside a running service", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      container.service :foo do
        define_method :perform do
          options[:toplevel].notify("foo")

          fail "something went wrong"
        end
      end

      container.service :bar do
        define_method :perform do
          loop do
            options[:toplevel].notify("bar")

            ::Async::Task.current.sleep 0.25
          end
        end
      end
    end

    before do
      allow(Pakyow.logger).to receive(:houston)
    end

    it "runs the service and backs off the failing service until the container is stopped" do
      run_container do
        listen_for length: 7, timeout: 1 do |result|
          expect(result.count("foo")).to be <= 4
          expect(result.count("bar")).to be >= 4
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

RSpec.describe "running an unrestartable container", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      container.service :foo, restartable: false do
        define_method :perform do
          options[:toplevel].notify("foo")
        end
      end
    end

    let(:container_options) {
      { restartable: false }
    }

    it "does not restart" do
      run_container timeout: 0.1 do
        sleep 1

        expect(messages).to eq(["foo"])
      end
    end

    it "appears stopped" do
      container = run_container

      expect(container.running?).to eq(false)
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

RSpec.describe "running an unrestartable service in a restartable container", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      container.service :foo, restartable: false do
        define_method :perform do
          options[:toplevel].notify(options[:message])
        end
      end

      container.service :bar do
        define_method :perform do
          ::Async::Task.current.sleep 10
        end
      end
    end

    let(:run_options) {
      { message: "foo" }
    }

    it "only runs the service once" do
      run_container do
        listen_for length: 1, timeout: 1 do |result|
          expect(result.count("foo")).to eq(1)
        end
      end
    end

    it "restarts the service along with the container" do
      run_container do |instance|
        listen_for length: 1, timeout: 1 do |result|
          expect(result.count("foo")).to eq(1)
        end

        instance.options[:message] = "bar"
        instance.restart

        listen_for length: 2, timeout: 1 do |result|
          expect(result.count("bar")).to eq(1)
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

RSpec.describe "running a restartable service in an unrestartable container", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      container.service :foo do
        define_method :perform do
          loop do
            options[:toplevel].notify("foo")

            ::Async::Task.current.sleep 0.25
          end
        end
      end
    end

    let(:container_options) {
      { restartable: false }
    }

    it "runs the service until the container is stopped" do
      run_container do
        listen_for length: 3, timeout: 1 do |result|
          expect(result.count("foo")).to eq(3)
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

RSpec.describe "restarting runnable containers from other processes", :repeatable, runnable: true do
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
          options[:toplevel].notify(message)
          ::Async::Task.current.sleep 10
        end
      end

      container.service :bar, restartable: false do
        define_method :perform do
          ::Async::Task.current.sleep 0.5
          options[:toplevel].restart
        end
      end
    }

    attr_reader :message

    it "restarts the container" do
      run_container do
        sleep 0.25

        @message = "bar"

        listen_for length: 3, timeout: 3 do |result|
          expect(result.count("foo")).to eq(1)
          expect(result.count("bar")).to eq(2)
        end
      end
    end

    context "container defines an on restart hook" do
      let(:definitions) {
        @message = "foo"

        container.on :restart do |**payload|
          options[:toplevel].notify(payload)
        end

        container.service :foo, restartable: false do
          define_method :perform do
            options[:container].restart(foo: "bar")
          end
        end
      }

      attr_reader :payload

      it "calls the hook with provided options" do
        run_container do
          listen_for length: 1, timeout: 1 do |result|
            expect(result).to eq([{foo: "bar"}])
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
      { strategy: :hybrid }
    }

    include_examples :examples
  end
end
