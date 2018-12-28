require "pakyow/plugin"

RSpec.describe "accessing helpers from the plugin" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      def boot
        @object = Class.new do
          def initialize(connection)
            @connection = connection
          end
        end

        self.class.include_helpers :passive, @object
      end

      action :test
      def test(connection)
        if connection.path == File.join(self.class.mount_path, "test-plugin/helpers")
          connection.body = @object.new(connection).test_helper
          connection.halt
        end
      end
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)
  end

  include_context "app"

  let :app_definition do
    Proc.new {
      plug :testable, at: "/"
      plug :testable, at: "/foo", as: :foo
    }
  end

  it "calls the helpers in the correct context" do
    call("/test-plugin/helpers").tap do |result|
      expect(result[0]).to eq(200)
      expect(result[2].body).to eq("test_helper: Test::Testable::Default")
    end

    call("/foo/test-plugin/helpers").tap do |result|
      expect(result[0]).to eq(200)
      expect(result[2].body).to eq("test_helper: Test::Testable::Foo")
    end
  end
end

RSpec.describe "accessing helpers from the app" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      # intentionally empty
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)
  end

  include_context "app"

  let :app_definition do
    Proc.new {
      plug :testable, at: "/"
      plug :testable, at: "/foo", as: :foo

      action :test

      after :initialize do
        @object = Class.new do
          def initialize(connection)
            @connection = connection
          end

          def some_action
            :some_action
          end
        end

        self.class.include_helpers :passive, @object
      end

      class_eval do
        def test(connection)
          plug = connection.params[:plug]
          helper = connection.params[:helper] || :test_helper

          helper_context = if plug
            @object.new(connection).testable(plug)
          else
            @object.new(connection).testable
          end

          connection.body = helper_context.send(helper)
          connection.halt
        end
      end
    }
  end

  it "calls the helpers in the correct context" do
    call("/helpers/default").tap do |result|
      expect(result[0]).to eq(200)
      expect(result[2].body).to eq("test_helper: Test::Testable::Default")
    end

    call("/helpers?plug=foo").tap do |result|
      expect(result[0]).to eq(200)
      expect(result[2].body).to eq("test_helper: Test::Testable::Foo")
    end
  end

  it "has access to methods in the original context" do
    call("/helpers/default?helper=test_context").tap do |result|
      expect(result[0]).to eq(200)
      expect(result[2].body).to eq("test_context: some_action")
    end
  end
end
