require_relative "../shared"

# TODO: Rename to status spec?
#
RSpec.describe "determining container success" do
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
        run_container timeout: 1 do |container|
          # Give the container time to update its internal state.
          #
          sleep 0.5

          expect(container.success?).to be(true)
        end
      end
    end

    context "service failed" do
      before do
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            fail
          ensure
            local.write_to_parent("failed")
          end
        end

        allow(Pakyow.logger).to receive(:houston)
      end

      it "appears unsuccessful" do
        run_container do |container|
          wait_for length: 6, timeout: 1 do |result|
            expect(container.success?).to be(false)
          end
        end
      end
    end

    context "one service succeeded but another failed" do
      before do
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            # noop
          end
        end

        container.service :foo, restartable: false do
          define_method :perform do
            fail
          ensure
            local.write_to_parent("failed")
          end
        end

        allow(Pakyow.logger).to receive(:houston)
      end

      it "appears unsuccessful" do
        run_container do |container|
          wait_for length: 6, timeout: 1 do |result|
            expect(container.success?).to be(false)
          end
        end
      end
    end

    context "nested service succeeded" do
      before do
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            local.run_container(local.container2, restartable: false, parent: self)
          end
        end

        container2.service :bar, restartable: false do
          define_method :perform do
            local.write_to_parent("bar")
          end
        end
      end

      let(:container2) {
        Pakyow::Runnable::Container.make(:test2)
      }

      it "appears successful" do
        run_container do |container|
          wait_for length: 3, timeout: 1 do
            # Give the container time to update its internal state.
            #
            sleep 0.5

            expect(container.success?).to be(true)
          end
        end
      end
    end

    context "nested service failed" do
      before do
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            local.run_container(local.container2, timeout: 0.1, restartable: false, parent: self)
          end
        end

        container2.service :bar, restartable: false do
          define_method :perform do
            fail
          ensure
            local.write_to_parent("failed")
          end
        end

        allow(Pakyow.logger).to receive(:houston)
      end

      let(:container2) {
        Pakyow::Runnable::Container.make(:test2)
      }

      it "appears unsuccessful" do
        run_container do |container|
          wait_for length: 6, timeout: 1 do |result|
            expect(container.success?).to be(false)
          end
        end
      end
    end

    context "one nested service succeeded but another failed" do
      before do
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            local.run_container(local.container2, timeout: 0.1, restartable: false, parent: self)
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
            local.write_to_parent("failed")
          end
        end

        allow(Pakyow.logger).to receive(:houston)
      end

      let(:container2) {
        Pakyow::Runnable::Container.make(:test2)
      }

      it "appears unsuccessful" do
        run_container do |container|
          wait_for length: 6, timeout: 1 do |result|
            expect(container.success?).to be(false)
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
