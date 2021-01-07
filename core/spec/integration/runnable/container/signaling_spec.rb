require_relative "../shared"

RSpec.describe "signaling runnable containers", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      FileUtils.mkdir_p(path)
    end

    after do
      FileUtils.rm_r(path)
    end

    let(:path) {
      Pathname.new(File.expand_path("../tmp/#{SecureRandom.hex(4)}", __FILE__))
    }

    let(:result_path) {
      path.join("result.txt")
    }

    # We can only test forked here because threaded services run in this process.
    #
    let(:run_options) {
      { strategy: :forked }
    }

    let(:container_options) {
      { restartable: false }
    }

    before do
      local = self

      container.service :foo, restartable: false do
        define_method :perform do
          local.run_container_raw(local.container2, context: self, **local.nested_run_options)

          loop do
            ::Async::Task.current.sleep 1
          end
        end
      end

      service
    end

    let(:container2) {
      Pakyow::Runnable::Container.make(:test2, **container_options)
    }

    let(:service) {
      container2.service :bar, restartable: false do
        define_method :perform do
          options[:toplevel].notify("bar: perform")

          @stopped = false

          until @stopped do
            ::Async::Task.current.sleep(0.25)
          end
        end

        define_method :shutdown do
          @stopped = true

          options[:toplevel].notify("bar: stop")
        end
      end
    }

    def run_then_kill
      run_container do |instance|
        listen_for length: 1, timeout: 1
        @pid = instance.instance_variable_get(:@strategy).instance_variable_get(:@services).first.reference
        ::Process.kill(signal, @pid)

        yield
      end
    end

    describe "signaling a container: INT" do
      let(:signal) {
        "INT"
      }

      it "cleanly stops each process" do
        run_then_kill do
          listen_for length: 2, timeout: 3 do |result|
            expect(result).to eq(["bar: perform", "bar: stop"])
          end
        end
      end

      context "service in the container does not stop on int" do
        let(:service) {
          container2.service :bar, restartable: false do
            define_method :perform do
              at_exit do
                options[:toplevel].notify("exited")
              end

              options[:toplevel].notify("running")

              loop do
                ::Async::Task.current.sleep 10
              end
            end
          end
        }

        it "forces the service to stop" do
          run_then_kill do
            listen_for length: 2, timeout: 2

            # Rely on the above timeout to cause the test to fail.
          end
        end
      end

      context "service in the container does not stop on int or term" do
        let(:service) {
          local = self

          container2.service :bar, restartable: false do
            define_method :perform do
              Signal.trap(:TERM) do
                # eat this one
              end

              options[:toplevel].notify("running")

              loop do
                local.result_path.write(Time.now.to_s)

                ::Async::Task.current.sleep 0.25
              end
            end
          end
        }

        it "force quits the service after the timeout" do
          # Only the forked strategy get get itself into this state.
          #
          next unless nested_run_options[:strategy] == :forked

          run_then_kill do
            sleep 5

            expect(Time.now - Time.parse(result_path.read)).to be > 3
          end
        end
      end
    end

    describe "signaling a container: TERM" do
      let(:signal) {
        "TERM"
      }

      it "forces each process to stop" do
        run_then_kill do
          sleep 1

          expect(messages).to eq(["bar: perform"])
        end
      end

      context "service in the container does not stop on term" do
        let(:service) {
          local = self

          container2.service :bar, restartable: false do
            define_method :perform do
              Signal.trap(:TERM) do
                # eat this one
              end

              options[:toplevel].notify("running")

              loop do
                if local.result_path.dirname.exist?
                  local.result_path.write(Time.now.to_s)
                end

                ::Async::Task.current.sleep 0.25
              end
            end

            define_method :shutdown do
              ::Async::Task.current.sleep(10)
            end
          end
        }

        it "force quits the service after the timeout" do
          # Only the forked strategy get get itself into this state.
          #
          next unless nested_run_options[:strategy] == :forked

          run_then_kill do
            sleep 5

            expect(Time.now - Time.parse(result_path.read)).to be > 4
          end
        end
      end
    end

    describe "signaling a container: HUP" do
      let(:signal) {
        "HUP"
      }

      context "container is restartable" do
        let(:container2) {
          Pakyow::Runnable::Container.make(:test2, restartable: true)
        }

        it "restarts the container" do
          run_then_kill do
            listen_for length: 3, timeout: 1 do |result|
              expect(result).to eq(["bar: perform", "bar: stop", "bar: perform"])
            end
          end
        end
      end

      context "container is not restartable" do
        let(:container2) {
          Pakyow::Runnable::Container.make(:test2, restartable: false)
        }

        it "ignores the signal" do
          run_then_kill do
            sleep 1

            expect(messages).to eq(["bar: perform"])
          end
        end
      end
    end

    describe "sending two int signals" do
      let(:signal) {
        "INT"
      }

      let(:service) {
        container2.service :bar, restartable: false do
          define_method :perform do
            at_exit do
              options[:toplevel].notify("exited")
            end

            options[:toplevel].notify("running")

            loop do
              ::Async::Task.current.sleep 10
            end
          end
        end
      }

      it "sends term on the second int" do
        run_then_kill do
          ::Process.kill(signal, @pid)

          listen_for length: 2, timeout: 2

          # Rely on the above timeout to cause the test to fail.
        end
      end
    end

    describe "sending three int signals" do
      let(:signal) {
        "INT"
      }

      let(:service) {
        local = self

        container2.service :bar, restartable: false do
          define_method :perform do
            Signal.trap(:TERM) do
              # eat this one
            end

            options[:toplevel].notify("running")

            loop do
              local.result_path.write(Time.now.to_s)

              ::Async::Task.current.sleep 0.25
            end
          end
        end
      }

      it "force quits on the third int" do
        # Only the forked strategy get get itself into this state.
        #
        next unless nested_run_options[:strategy] == :forked

        run_then_kill do
          ::Process.kill(signal, @pid)
          ::Process.kill(signal, @pid)

          sleep 5

          expect(Time.now - Time.parse(result_path.read)).to be > 3
        end
      end
    end
  end

  context "forked container" do
    let(:nested_run_options) {
      { strategy: :forked }
    }

    include_examples :examples
  end

  context "threaded container" do
    let(:nested_run_options) {
      { strategy: :threaded }
    }

    include_examples :examples
  end

  context "hybrid container" do
    let(:nested_run_options) {
      { strategy: :hybrid }
    }

    include_examples :examples
  end

  context "async container" do
    let(:nested_run_options) {
      { strategy: :async }
    }

    include_examples :examples
  end
end
