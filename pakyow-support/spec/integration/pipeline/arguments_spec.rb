require "pakyow/support/pipeline"
require "pakyow/support/pipeline/object"

RSpec.describe "passing arguments through pipelines" do
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

  def call(*args, **kwargs)
    pipelined.new.call(result.new, *args, **kwargs)
  end

  context "action accepts state as well as a required argument" do
    shared_examples :common do
      it "accepts arguments" do
        expect(call("foo")).to eq(["foo"])
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

          def foo(result, foo)
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

          action :foo do |result, foo|
            result << foo
          end
        }
      }

      it "accepts arguments" do
        expect(call("foo")).to eq(["foo"])
      end

      it "does not fail when no arguments are passed" do
        expect {
          call
        }.not_to raise_error
      end
    end

    context "action is a class" do
      let(:pipelined) {
        Class.new {
          include Pakyow::Support::Pipeline

          action :foo, Class.new {
            def call(result, foo)
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
            def call(result, foo)
              result << foo
            end
          }.new
        }
      }

      include_examples :common
    end
  end

  context "action accepts state as well as an optional argument" do
    shared_examples :common do
      it "accepts arguments" do
        expect(call("foo")).to eq(["foo"])
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

          def foo(result, foo = nil)
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

          action :foo do |result, foo = nil|
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
            def call(result, foo = nil)
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
            def call(result, foo = nil)
              result << foo
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
        expect(call).to eq(nil)
      end

      it "does not fail when passing arguments" do
        expect {
          call("foo")
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
        expect(call).to eq(nil)
      end

      it "does not fail when passing arguments" do
        expect {
          call("foo")
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
