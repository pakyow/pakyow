require "pakyow/support/pipeline"
require "pakyow/support/pipeline/object"

RSpec.describe "passing keyword arguments through pipelines" do
  let(:result) {
    Class.new {
      include Pakyow::Support::Pipeline::Object

      attr_reader :results

      def initialize
        @results = []
      end

      def <<(result)
        @results << result
      end
    }
  }

  let(:pipeline) {
    pipelined.new
  }

  def call(*args, **kwargs)
    pipeline.call(result.new, *args, **kwargs)
  end

  context "action accepts state as well as a required keyword argument" do
    shared_examples :common do
      it "accepts keyword arguments" do
        expect(call(foo: "foo").results).to eq(["foo"])
      end

      it "fails when no arguments are passed" do
        expect {
          call
        }.to raise_error(ArgumentError)
      end
    end

    context "action is a method" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo

          def foo(result, foo:)
            result << foo
          end
        }
      }

      include_examples :common
    end

    context "action is a block" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo do |result, foo:|
            result << foo
          end
        }
      }

      include_examples :common
    end

    context "action is a class" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo, Class.new {
            def call(result, foo:)
              result << foo
            end
          }
        }
      }

      include_examples :common
    end

    context "action is an instance" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo, Class.new {
            def call(result, foo:)
              result << foo
            end
          }.new
        }
      }

      include_examples :common
    end
  end

  context "action accepts state as well as an optional keyword argument" do
    shared_examples :common do
      it "accepts keyword arguments" do
        expect(call(foo: "foo").results).to eq(["foo"])
      end

      it "does not fail when no arguments are passed" do
        expect {
          call
        }.not_to raise_error
      end
    end

    context "action is a method" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo

          def foo(result, foo: nil)
            result << foo
          end
        }
      }

      include_examples :common
    end

    context "action is a block" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo do |result, foo: nil|
            result << foo
          end
        }
      }

      include_examples :common
    end

    context "action is a class" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo, Class.new {
            def call(result, foo: nil)
              result << foo
            end
          }
        }
      }

      include_examples :common
    end

    context "action is an instance" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo, Class.new {
            def call(result, foo: nil)
              result << foo
            end
          }.new
        }
      }

      include_examples :common
    end
  end

  context "action accepts only a required keyword argument" do
    shared_examples :common do
      it "accepts keyword arguments" do
        call(foo: "foo")

        expect(results).to eq(["foo"])
      end

      it "fails when no arguments are passed" do
        expect {
          call
        }.to raise_error(ArgumentError)
      end
    end

    let(:results) {
      []
    }

    context "action is a method" do
      let(:pipelined) {
        local = self

        Class.new {
          include Pakyow::Support::Pipeline

          action :foo

          define_method :foo do |foo:|
            local.results << foo
          end
        }
      }

      include_examples :common
    end

    context "action is a block" do
      let(:pipelined) {
        local = self

        Class.new {
          include Pakyow::Support::Pipeline

          action :foo do |foo:|
            local.results << foo
          end
        }
      }

      include_examples :common
    end

    context "action is a class" do
      let(:pipelined) {
        local = self

        Class.new {
          include Pakyow::Support::Pipeline

          action :foo, Class.new {
            define_method :call do |foo:|
              local.results << foo
            end
          }
        }
      }

      include_examples :common
    end

    context "action is an instance" do
      let(:pipelined) {
        local = self

        Class.new {
          include Pakyow::Support::Pipeline

          action :foo, Class.new {
            define_method :call do |foo:|
              local.results << foo
            end
          }.new
        }
      }

      include_examples :common
    end
  end

  context "action accepts only an optional keyword argument" do
    shared_examples :common do
      it "accepts keyword arguments" do
        call(foo: "foo")

        expect(results).to eq(["foo"])
      end

      it "does not fail when no arguments are passed" do
        expect {
          call
        }.not_to raise_error
      end
    end

    let(:results) {
      []
    }

    context "action is a method" do
      let(:pipelined) {
        local = self

        Class.new {
          include Pakyow::Support::Pipeline

          action :foo

          define_method :foo do |foo: nil|
            local.results << foo
          end
        }
      }

      include_examples :common
    end

    context "action is a block" do
      let(:pipelined) {
        local = self

        Class.new {
          include Pakyow::Support::Pipeline

          action :foo do |foo: nil|
            local.results << foo
          end
        }
      }

      include_examples :common
    end

    context "action is a class" do
      let(:pipelined) {
        local = self

        Class.new {
          include Pakyow::Support::Pipeline

          action :foo, Class.new {
            define_method :call do |foo: nil|
              local.results << foo
            end
          }
        }
      }

      include_examples :common
    end

    context "action is an instance" do
      let(:pipelined) {
        local = self

        Class.new {
          include Pakyow::Support::Pipeline

          action :foo, Class.new {
            define_method :call do |foo: nil|
              local.results << foo
            end
          }.new
        }
      }

      include_examples :common
    end
  end

  context "action accepts state as the only argument" do
    shared_examples :common do
      it "does not pass arguments" do
        expect(call.results).to eq([])
      end

      it "does not fail when passing keyword arguments" do
        expect {
          call(foo: "foo")
        }.not_to raise_error
      end
    end

    context "action is a method" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo

          def foo(result); end
        }
      }

      include_examples :common
    end

    context "action is a block" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo do |result|; end
        }
      }

      include_examples :common
    end

    context "action is a class" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo, Class.new {
            def call(result); end
          }
        }
      }

      include_examples :common
    end

    context "action is an instance" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo, Class.new {
            def call(result); end
          }.new
        }
      }

      include_examples :common
    end
  end

  context "action does not accept any arguments" do
    shared_examples :common do
      it "does not pass arguments" do
        expect(call.results).to eq([])
      end

      it "does not fail when passing keyword arguments" do
        expect {
          call(foo: "foo")
        }.not_to raise_error
      end
    end

    context "action is a method" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo

          def foo; end
        }
      }

      include_examples :common
    end

    context "action is a block" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo do; end
        }
      }

      include_examples :common
    end

    context "action is a class" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo, Class.new {
            def call; end
          }
        }
      }

      include_examples :common
    end

    context "action is an instance" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo, Class.new {
            def call; end
          }.new
        }
      }

      include_examples :common
    end
  end
end
