require "pakyow/support/pipeline"
require "pakyow/support/pipeline/object"

# TODO: There are several edge-cases to resolve here when pulling this out into `core-pipeline`.
#
RSpec.xdescribe "passing mixed arguments through pipelines" do
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

  context "action accepts state as well as a required argument and a required keyword argument" do
    shared_examples :common do
      it "accepts expected arguments" do
        expect(call("foo", bar: "bar")).to eq(["foo", "bar"])
      end

      it "fails when no argument is passed" do
        expect {
          ignore_warnings do
            call(bar: "bar")
          end
        }.to raise_error(ArgumentError)
      end

      it "fails when no keyword argument is passed" do
        expect {
          call("foo")
        }.to raise_error(ArgumentError)
      end

      it "fails when no arguments are passed" do
        expect {
          ignore_warnings do
            call
          end
        }.to raise_error(ArgumentError)
      end
    end

    context "action is a method" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo

          def foo(result, foo, bar:)
            result << foo
            result << bar
          end
        }
      }

      include_examples :common
    end

    context "action is a block" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo do |result, foo, bar:|
            result << foo
            result << bar
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
            def call(result, foo, bar:)
              result << foo
              result << bar
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
            def call(result, foo, bar:)
              result << foo
              result << bar
            end
          }.new
        }
      }

      include_examples :common
    end
  end

  context "action accepts state as well as an optional argument and a required keyword argument" do
    shared_examples :common do
      it "accepts an argument and keyword argument" do
        expect(call("foo", bar: "bar")).to eq(["foo", "bar"])
      end

      it "accepts just a keyword argument" do
        expect(call(bar: "bar")).to eq([nil, "bar"])
      end

      it "fails when no keyword argument is passed" do
        expect {
          call("foo")
        }.to raise_error(ArgumentError)
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

          def foo(result, foo = nil, bar:)
            result << foo
            result << bar
          end
        }
      }

      include_examples :common
    end

    context "action is a block" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo do |result, foo = nil, bar:|
            result << foo
            result << bar
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
            def call(result, foo = nil, bar:)
              result << foo
              result << bar
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
            def call(result, foo = nil, bar:)
              result << foo
              result << bar
            end
          }.new
        }
      }

      include_examples :common
    end
  end

  context "action accepts state as well as a required argument and an optional keyword argument" do
    shared_examples :common do
      it "accepts an argument and keyword argument" do
        expect(call("foo", bar: "bar")).to eq(["foo", "bar"])
      end

      it "accepts just an argument" do
        expect(call("foo")).to eq(["foo", nil])
      end

      it "behaves as expected when no argument is passed" do
        # This is counter-intuitive, but it's how normal methods behave.
        #
        ignore_warnings do
          expect(call(bar: "bar")).to eq([{ bar: "bar" }, nil])
        end
      end

      it "behaves as expected when no argument is passed" do
        # This is counter-intuitive, but it's the expected behavior.
        #
        ignore_warnings do
          expect(call).to eq([{}, nil])
        end
      end
    end

    context "action is a method" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo

          def foo(result, foo, bar: nil)
            result << foo
            result << bar
          end
        }
      }

      include_examples :common
    end

    context "action is a block" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo do |result, foo, bar: nil|
            result << foo
            result << bar
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
            def call(result, foo, bar: nil)
              result << foo
              result << bar
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
            def call(result, foo, bar: nil)
              result << foo
              result << bar
            end
          }.new
        }
      }

      include_examples :common
    end
  end

  context "action accepts state as well as an optional argument and an optional keyword argument" do
    shared_examples :common do
      it "accepts an argument and keyword argument" do
        expect(call("foo", bar: "bar")).to eq(["foo", "bar"])
      end

      it "accepts just an argument" do
        expect(call("foo")).to eq(["foo", nil])
      end

      it "behaves as expected when no argument is passed" do
        expect(call(bar: "bar")).to eq([nil, "bar"])
      end

      it "behaves as expected when no argument is passed" do
        expect(call).to eq([nil, nil])
      end
    end

    context "action is a method" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo

          def foo(result, foo = nil, bar: nil)
            result << foo
            result << bar
          end
        }
      }

      include_examples :common
    end

    context "action is a block" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo do |result, foo = nil, bar: nil|
            result << foo
            result << bar
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
            def call(result, foo = nil, bar: nil)
              result << foo
              result << bar
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
            def call(result, foo = nil, bar: nil)
              result << foo
              result << bar
            end
          }.new
        }
      }

      include_examples :common
    end
  end
end
