require_relative "../../shared"

RSpec.describe "overriding functionality in process subclasses", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    describe "restartable?" do
      before do
        definitions
      end

      let(:definitions) {
        container.service :foo do
          define_method :perform do
            options[:toplevel].notify("foo")
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
              listen_for length: 2, timeout: 1
            }.to raise_error(Async::TimeoutError)
          end
        end
      end

      describe "enabling restarts" do
        let(:run_options) {
          { service_restart: true }
        }

        it "can enable restarts" do
          run_container do
            listen_for length: 2, timeout: 1 do |result|
              expect(result.count("foo")).to eq(2)
            end
          end
        end
      end

      describe "calling super" do
        let(:definitions) {
          container.service :foo do
            define_method :perform do
              options[:toplevel].notify("foo")
            end

            define_method :restartable? do
              super()
            end
          end
        }

        it "has the default behavior" do
          run_container do
            listen_for length: 2, timeout: 1 do |result|
              expect(result.count("foo")).to eq(2)
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
        container.service :foo, restartable: false do
          define_method :perform do
            options[:toplevel].notify("foo")
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
          listen_for length: 2, timeout: 1 do |result|
            expect(result.count("foo")).to eq(2)
          end
        end
      end

      describe "calling super" do
        let(:definitions) {
          container.service :foo, restartable: false do
            define_method :perform do
              options[:toplevel].notify("foo")
            end

            define_method :limit do
              super()
            end
          end
        }

        it "has the default behavior" do
          run_container do
            listen_for length: 3, timeout: 1 do |result|
              expect(result.count("foo")).to eq(3)
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
        container.service :foo, restartable: false do
          define_method :perform do
            options[:toplevel].notify("foo")
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
          listen_for length: 2, timeout: 1 do |result|
            expect(result.count("foo")).to eq(2)
          end
        end
      end

      describe "calling super" do
        let(:definitions) {
          container.service :foo, restartable: false do
            define_method :perform do
              options[:toplevel].notify("foo")
            end

            define_method :count do
              super()
            end
          end
        }

        it "has the default behavior" do
          run_container do
            listen_for length: 1, timeout: 1 do |result|
              expect(result.count("foo")).to eq(1)
            end
          end
        end
      end
    end

    describe "logger" do
      before do
        definitions

        allow(Pakyow.logger).to receive(:warn)
      end

      let(:definitions) {
        container.service :foo, restartable: false do
          define_method :perform do
            options[:toplevel].notify(logger.class.name)
          end

          define_method :logger do
            options[:service_logger]
          end
        end
      }

      let(:container_options) {
        { restartable: false }
      }

      let(:run_options) {
        { service_logger: nil }
      }

      it "can define its own logger" do
        run_container do
          listen_for length: 1, timeout: 1 do |result|
            expect(result).to eq(["NilClass"])
          end
        end
      end

      describe "calling super" do
        let(:definitions) {
          container.service :foo, restartable: false do
            define_method :perform do
              options[:toplevel].notify(logger.class.name)
            end

            define_method :logger do
              super()
            end
          end
        }

        it "has the default behavior" do
          run_container do
            listen_for length: 1, timeout: 1 do |result|
              expect(result).to eq(["Pakyow::Logger::ThreadLocal"])
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

  context "async container" do
    let(:run_options) {
      { strategy: :async }
    }

    include_examples :examples
  end
end
