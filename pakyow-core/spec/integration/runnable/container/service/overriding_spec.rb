require_relative "../../shared"

RSpec.describe "overriding functionality in process subclasses" do
  include_context "runnable container"

  shared_examples :examples do
    describe "restartable?" do
      before do
        definitions
      end

      let(:definitions) {
        local = self

        container.service :foo do
          define_method :perform do
            local.write_to_parent("foo")
          end

          define_method :restartable? do
            options[:service_restart]
          end
        end
      }

      let(:container_options) {
        { restartable: false }
      }

      describe "disabling restarts" do
        let(:run_options) {
          { service_restart: false }
        }

        it "can disable restarts" do
          run_container do
            expect {
              wait_for length: 6, timeout: 0.1 do; end
            }.to raise_error(Timeout::Error)
          end
        end
      end

      describe "enabling restarts" do
        let(:run_options) {
          { service_restart: true }
        }

        it "can enable restarts" do
          run_container do
            wait_for length: 6, timeout: 1 do |result|
              expect(result.scan(/foo/).count).to eq(2)
            end
          end
        end
      end

      describe "calling super" do
        let(:definitions) {
          local = self

          container.service :foo do
            define_method :perform do
              local.write_to_parent("foo")
            end

            define_method :restartable? do
              super()
            end
          end
        }

        it "has the default behavior" do
          run_container do
            wait_for length: 6, timeout: 1 do |result|
              expect(result.scan(/foo/).count).to eq(2)
            end
          end
        end
      end
    end

    describe "limit" do
      before do
        definitions

        allow(Pakyow.logger).to receive(:warn)
      end

      let(:definitions) {
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            local.write_to_parent("foo")
          end

          define_method :limit do
            options[:service_limit]
          end
        end
      }

      let(:container_options) {
        { restartable: false }
      }

      let(:run_options) {
        { service_limit: 2, formation: Pakyow::Runnable::Formation.build { |formation| formation.run(:foo, 3) } }
      }

      it "can define its own limiting logic" do
        run_container do
          wait_for length: 6, timeout: 1 do |result|
            expect(result.scan(/foo/).count).to eq(2)
          end
        end
      end

      describe "calling super" do
        let(:definitions) {
          local = self

          container.service :foo, restartable: false do
            define_method :perform do
              local.write_to_parent("foo")
            end

            define_method :limit do
              super()
            end
          end
        }

        it "has the default behavior" do
          run_container do
            wait_for length: 9, timeout: 1 do |result|
              expect(result.scan(/foo/).count).to eq(3)
            end
          end
        end
      end
    end

    describe "count" do
      before do
        definitions

        allow(Pakyow.logger).to receive(:warn)
      end

      let(:definitions) {
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            local.write_to_parent("foo")
          end

          define_method :count do
            options[:service_count]
          end
        end
      }

      let(:container_options) {
        { restartable: false }
      }

      let(:run_options) {
        { service_count: 2 }
      }

      it "can define its own count logic" do
        run_container do
          wait_for length: 6, timeout: 1 do |result|
            expect(result.scan(/foo/).count).to eq(2)
          end
        end
      end

      describe "calling super" do
        let(:definitions) {
          local = self

          container.service :foo, restartable: false do
            define_method :perform do
              local.write_to_parent("foo")
            end

            define_method :count do
              super()
            end
          end
        }

        it "has the default behavior" do
          run_container do
            wait_for length: 3, timeout: 1 do |result|
              expect(result.scan(/foo/).count).to eq(1)
            end
          end
        end
      end
    end

    xdescribe "strategy" do
      before do
        definitions

        allow(Pakyow.logger).to receive(:warn)
      end

      let(:definitions) {
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            local.write_to_parent("foo")
          end

          define_method :count do
            options[:service_count]
          end
        end
      }

      let(:container_options) {
        { restartable: false }
      }

      let(:run_options) {
        { service_count: 2 }
      }

      it "can define its own count logic" do
        run_container do
          wait_for length: 6, timeout: 1 do |result|
            expect(result.scan(/foo/).count).to eq(2)
          end
        end
      end

      describe "calling super" do
        let(:definitions) {
          local = self

          container.service :foo, restartable: false do
            define_method :perform do
              local.write_to_parent("foo")
            end

            define_method :count do
              super()
            end
          end
        }

        it "has the default behavior" do
          run_container do
            wait_for length: 3, timeout: 1 do |result|
              expect(result.scan(/foo/).count).to eq(1)
            end
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
