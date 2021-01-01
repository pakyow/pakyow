require_relative "../shared"

RSpec.describe "stopping down runnable containers", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      local = self

      container.service :foo do
        define_method(:perform, &local.perform_block)
        define_method(:shutdown, &local.shutdown_block)
      end
    end

    let(:perform_block) {
      Proc.new {
        options[:toplevel].notify("started")

        @stopped = false

        until @stopped do
          ::Async::Task.current.sleep(0.25)
        end

        options[:toplevel].notify("finished")
      }
    }

    let(:shutdown_block) {
      Proc.new {
        options[:toplevel].notify("shutdown")

        @stopped = true
      }
    }

    def stop(instance)
      instance.stop
    end

    it "stops the container" do
      run_container do |instance|
        listen_for length: 1, timeout: 1 do |result|
          expect(result.count("started")).to eq(1)
        end

        stop(instance)

        listen_for length: 3, timeout: 1 do |result|
          expect(result).to eq(%w(started shutdown finished))
        end
      end
    end

    describe "async friendliness" do
      let(:perform_block) {
        Proc.new {
          options[:toplevel].notify("started")

          @condition = ::Async::Condition.new
          @condition.wait

          options[:toplevel].notify("finished")
        }
      }

      let(:shutdown_block) {
        Proc.new {
          options[:toplevel].notify("shutdown")

          @condition.signal
        }
      }

      it "stops within the same async context as perform" do
        # This does not work for threaded containers, as fibers cannot be resumed across threads.
        #
        next if run_options[:strategy] == :threaded

        run_container do |instance|
          listen_for length: 1, timeout: 1 do |result|
            expect(result.count("started")).to eq(1)
          end

          stop(instance)

          listen_for length: 3, timeout: 1 do |result|
            expect(result).to eq(%w(started shutdown finished))
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
