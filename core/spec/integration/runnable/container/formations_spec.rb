require_relative "../shared"

RSpec.describe "running a formation container", :repeatable, runnable: true do
  include_context "runnable container"

  shared_examples :examples do
    before do
      containers
    end

    let(:run_options) {
      { formation: formation, restartable: false }
    }

    let(:containers) {
      container.service :foo, count: 2, restartable: false do
        define_method :perform do
          options[:toplevel].notify("foo")
        end
      end

      container.service :bar, count: 3, restartable: false do
        define_method :perform do
          options[:toplevel].notify("bar")
        end
      end
    }

    context "formation describes running n instances of all" do
      let(:formation) {
        Pakyow::Runnable::Formation.all
      }

      it "runs the expected number of services" do
        run_container do
          listen_for length: 5, timeout: 1 do |result|
            expect(result.count("foo")).to eq(2)
            expect(result.count("bar")).to eq(3)
          end
        end
      end
    end

    context "formation describes running multiple instances of all" do
      let(:formation) {
        Pakyow::Runnable::Formation.all(3)
      }

      it "runs multiple instances of all known services" do
        run_container do
          listen_for length: 6, timeout: 1 do |result|
            expect(result.count("foo")).to eq(3)
            expect(result.count("bar")).to eq(3)
          end
        end
      end
    end

    context "formation describes running n instances of a single service" do
      let(:formation) {
        Pakyow::Runnable::Formation.build { |formation|
          formation.run(:bar, 3)
        }
      }

      it "runs the expected number of services" do
        run_container do
          listen_for length: 3, timeout: 1 do |result|
            expect(result.count("foo")).to eq(0)
            expect(result.count("bar")).to eq(3)
          end
        end
      end
    end

    context "formation describes running one instance of a single service" do
      let(:formation) {
        Pakyow::Runnable::Formation.build { |formation|
          formation.run(:foo, 1)
        }
      }

      it "runs a single instance of the described service" do
        run_container do
          listen_for length: 1, timeout: 1 do |result|
            expect(result.count("foo")).to eq(1)
          end
        end
      end
    end

    context "formation describes running n instances of many services" do
      let(:formation) {
        Pakyow::Runnable::Formation.build { |formation|
          formation.run(:foo)
          formation.run(:bar)
        }
      }

      it "runs the expected number of services" do
        run_container do
          listen_for length: 5, timeout: 1 do |result|
            expect(result.count("foo")).to eq(2)
            expect(result.count("bar")).to eq(3)
          end
        end
      end
    end

    context "formation describes running one instance of many services" do
      let(:formation) {
        Pakyow::Runnable::Formation.build { |formation|
          formation.run(:foo, 1)
          formation.run(:bar, 1)
        }
      }

      it "runs a single instance of the described services" do
        run_container do
          listen_for length: 2, timeout: 1 do |result|
            expect(result.count("foo")).to eq(1)
            expect(result.count("bar")).to eq(1)
          end
        end
      end
    end

    context "formation describes running multiple instances of many services" do
      let(:formation) {
        Pakyow::Runnable::Formation.build { |formation|
          formation.run(:foo, 5)
          formation.run(:bar, 2)
        }
      }

      it "runs multiple instances of the described services" do
        run_container do
          listen_for length: 7, timeout: 1 do |result|
            expect(result.count("foo")).to eq(5)
            expect(result.count("bar")).to eq(2)
          end
        end
      end
    end

    context "formation describes top-level and nested services" do
      let(:containers) {
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            options[:toplevel].notify("foo")
          end
        end

        container.service :bar, restartable: false do
          define_method :perform do
            local.run_container_raw(local.container2, context: self)
          end
        end

        container2.service :baz, restartable: false do
          define_method :perform do
            options[:toplevel].notify("baz")
          end
        end
      }

      let(:container2) {
        Pakyow::Runnable::Container.make(:test2, **container_options)
      }

      let(:formation) {
        Pakyow::Runnable::Formation.build(:test) { |formation|
          formation.run(:foo, 1)
          formation.run(:bar, 2)

          formation.build(:test2) { |nested_formation|
            nested_formation.run(:baz, 3)
          }
        }
      }

      it "runs the expected formation" do
        run_container do
          listen_for length: 7, timeout: 1 do |result|
            expect(result.count("foo")).to eq(1)
            expect(result.count("baz")).to eq(6)
          end
        end
      end
    end

    context "formation describes only a nested service" do
      let(:containers) {
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            local.run_container_raw(local.container2, context: self)
          end
        end

        container.service :bar, restartable: false do
          define_method :perform do
            options[:toplevel].notify("bar")
          end
        end

        container2.service :baz, restartable: false do
          define_method :perform do
            options[:toplevel].notify("baz")
          end
        end

        container2.service :qux, restartable: false do
          define_method :perform do
            options[:toplevel].notify("qux")
          end
        end
      }

      let(:container2) {
        Pakyow::Runnable::Container.make(:test2, **container_options)
      }

      let(:formation) {
        Pakyow::Runnable::Formation.parse("test.test2.baz=3")
      }

      it "runs the one nested service along with all services in the parent container" do
        run_container do
          listen_for length: 4, timeout: 1 do |result|
            expect(result.count("bar")).to eq(1)
            expect(result.count("baz")).to eq(3)
            expect(result.count("qux")).to eq(0)
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
