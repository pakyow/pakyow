require_relative "../shared"

# TODO: Rename to status spec?
#
RSpec.describe "determining container success", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    let(:container_options) {
      { restartable: false }
    }

    context "service succeeded" do
      before do
        container.service :foo, restartable: false do
          define_method :perform do
            # noop
          end
        end
      end

      it "appears successful" do
        container = run_container timeout: 1 do
          # Give the container time to update its internal state.
          #
          sleep 0.5
        end

        expect(container.success?).to be(true)
      end
    end

    context "service failed" do
      before do
        container.service :foo, restartable: false do
          define_method :perform do
            fail
          ensure
            options[:container].notify("failed")
          end
        end

        allow(Pakyow.logger).to receive(:houston)
      end

      it "appears unsuccessful" do
        container = run_container do
          listen_for length: 1, timeout: 1 do |result|
            expect(result).to eq(["failed"])
          end
        end

        expect(container.success?).to be(false)
      end
    end

    context "one service succeeded but another failed" do
      before do
        container.service :foo, restartable: false do
          define_method :perform do
            # noop
          end
        end

        container.service :bar, restartable: false do
          define_method :perform do
            fail
          ensure
            options[:container].notify("failed")
          end
        end

        allow(Pakyow.logger).to receive(:houston)
      end

      it "appears unsuccessful" do
        container = run_container do
          listen_for length: 1, timeout: 1 do |result|
            expect(result).to eq(["failed"])
          end
        end

        expect(container.success?).to be(false)
      end
    end

    context "nested service succeeded" do
      before do
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            local.run_container_raw(local.container2, context: self)
          end
        end

        container2.service :bar, restartable: false do
          define_method :perform do
            options[:toplevel].notify("bar")
          end
        end
      end

      let(:container2) {
        Pakyow::Runnable::Container.make(:test2, **container_options)
      }

      it "appears successful" do
        container = run_container do
          listen_for length: 1, timeout: 1 do |result|
            expect(result).to eq(["bar"])
          end

          # sleep 1
        end

        expect(container.success?).to be(true)
      end
    end

    context "nested service failed" do
      before do
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            local.run_container_raw(local.container2, context: self)
          end
        end

        container2.service :bar, restartable: false do
          define_method :perform do
            fail
          ensure
            options[:toplevel].notify("failed")
          end
        end

        allow(Pakyow.logger).to receive(:houston)
      end

      let(:container2) {
        Pakyow::Runnable::Container.make(:test2, **container_options)
      }

      it "appears unsuccessful" do
        container = run_container do
          listen_for length: 1, timeout: 1 do |result|
            expect(result).to eq(["failed"])
          end

          # sleep 1
        end

        expect(container.success?).to be(false)
      end
    end

    context "one nested service succeeded but another failed" do
      before do
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            local.run_container_raw(local.container2, context: self)
          end
        end

        container2.service :bar, restartable: false do
          define_method :perform do
            # noop
          end
        end

        container2.service :baz, restartable: false do
          define_method :perform do
            fail
          ensure
            options[:toplevel].notify("failed")
          end
        end

        allow(Pakyow.logger).to receive(:houston)
      end

      let(:container2) {
        Pakyow::Runnable::Container.make(:test2, **container_options)
      }

      it "appears unsuccessful" do
        container = run_container do
          listen_for length: 1, timeout: 1 do |result|
            expect(result).to eq(["failed"])
          end

          # sleep 1
        end

        expect(container.success?).to be(false)
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
