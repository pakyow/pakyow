require_relative "../shared"

RSpec.describe "running a formation container" do
  include_context "runnable container"

  shared_examples :examples do
    before do
      containers
    end

    let(:run_options) {
      { formation: formation, restartable: false }
    }

    let(:containers) {
      local = self

      container.service :foo, count: 2, restartable: false do
        define_method :perform do
          local.write_to_parent("foo")
        end
      end

      container.service :bar, count: 3, restartable: false do
        define_method :perform do
          local.write_to_parent("bar")
        end
      end
    }

    context "formation describes running n instances of all" do
      let(:formation) {
        Pakyow::Runnable::Formation.all
      }

      it "runs the expected number of services" do
        run_container do
          wait_for length: 15, timeout: 1 do |result|
            expect(result.scan(/foo/).count).to eq(2)
            expect(result.scan(/bar/).count).to eq(3)
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
          wait_for length: 18, timeout: 1 do |result|
            expect(result.scan(/foo/).count).to eq(3)
            expect(result.scan(/bar/).count).to eq(3)
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
          wait_for length: 9, timeout: 1 do |result|
            expect(result.scan(/foo/).count).to eq(0)
            expect(result.scan(/bar/).count).to eq(3)
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
          wait_for length: 3, timeout: 1 do |result|
            expect(result.scan(/foo/).count).to eq(1)
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
          wait_for length: 15, timeout: 1 do |result|
            expect(result.scan(/foo/).count).to eq(2)
            expect(result.scan(/bar/).count).to eq(3)
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
          wait_for length: 6, timeout: 1 do |result|
            expect(result.scan(/foo/).count).to eq(1)
            expect(result.scan(/bar/).count).to eq(1)
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
          wait_for length: 21, timeout: 1 do |result|
            expect(result.scan(/foo/).count).to eq(5)
            expect(result.scan(/bar/).count).to eq(2)
          end
        end
      end
    end

    context "formation describes top-level and nested services" do
      let(:containers) {
        local = self

        container.service :foo, restartable: false do
          define_method :perform do
            local.write_to_parent("foo")
          end
        end

        container.service :bar, restartable: false do
          define_method :perform do
            local.run_container(local.container2, timeout: 0.1, restartable: false, parent: self, **options)
          end
        end

        container2.service :baz, restartable: false do
          define_method :perform do
            local.write_to_parent("baz")
          end
        end
      }

      let(:container2) {
        Pakyow::Runnable::Container.make(:test2)
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
          wait_for length: 21, timeout: 3 do |result|
            expect(result.scan(/foo/).count).to eq(1)
            expect(result.scan(/baz/).count).to eq(6)
          end
        end
      end
    end

    context "formation describes only a nested service" do
      let(:containers) {
        local = self

        container.service :test2, restartable: false do
          define_method :perform do
            local.run_container(local.container2, timeout: 0.1, restartable: false, parent: self, **options)
          end
        end

        container2.service :baz, restartable: false do
          define_method :perform do
            local.write_to_parent("baz")
          end
        end
      }

      let(:container2) {
        Pakyow::Runnable::Container.make(:test2)
      }

      let(:formation) {
        Pakyow::Runnable::Formation.parse("test.test2.baz=3")
      }

      it "runs the expected formation" do
        run_container do
          wait_for length: 9, timeout: 1 do |result|
            expect(result.scan(/baz/).count).to eq(3)
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
end
