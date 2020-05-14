require_relative "../shared"

# TODO: Rename to status spec?
#
RSpec.describe "determining container success" do
  include_context "runnable container"

  shared_examples :examples do
    context "service succeeded" do
      before do
        container.service :foo do
          define_method :perform do
            # noop
          end
        end

        run_container(timeout: 0.1)
      end

      it "appears successful" do
        expect(@container_instance.success?).to be(true)
      end
    end

    context "service failed" do
      before do
        container.service :foo do
          define_method :perform do
            fail
          end
        end

        allow(Pakyow.logger).to receive(:houston)

        run_container(timeout: 0.1)
      end

      it "appears unsuccessful" do
        expect(@container_instance.success?).to be(false)
      end
    end

    context "one service succeeded but another failed" do
      before do
        container.service :foo do
          define_method :perform do
            # noop
          end
        end

        container.service :foo do
          define_method :perform do
            fail
          end
        end

        allow(Pakyow.logger).to receive(:houston)

        run_container(timeout: 0.1)
      end

      it "appears unsuccessful" do
        expect(@container_instance.success?).to be(false)
      end
    end

    context "nested service succeeded" do
      before do
        local = self

        container.service :foo do
          define_method :perform do
            # noop
          end
        end

        container2.service :bar do
          define_method :perform do
            # noop
          end
        end

        run_container(timeout: 0.1)
      end

      let(:container2) {
        Pakyow::Runnable::Container.make(:test2)
      }

      it "appears successful" do
        expect(@container_instance.success?).to be(true)
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
          end
        end

        allow(Pakyow.logger).to receive(:houston)

        run_container(timeout: 0.2, restartable: false)
      end

      let(:container2) {
        Pakyow::Runnable::Container.make(:test2)
      }

      it "appears unsuccessful" do
        expect(@container_instance.success?).to be(false)
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
          end
        end

        allow(Pakyow.logger).to receive(:houston)

        run_container(timeout: 0.2, restartable: false)
      end

      let(:container2) {
        Pakyow::Runnable::Container.make(:test2)
      }

      it "appears unsuccessful" do
        expect(@container_instance.success?).to be(false)
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
