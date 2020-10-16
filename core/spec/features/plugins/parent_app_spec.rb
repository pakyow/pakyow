require "pakyow/plugin"

RSpec.describe "accessing the parent app from a plugin" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      after "boot" do
        @object = Class.new do
          def initialize(connection)
            @connection = connection
          end

          def test
            "parent app: #{app.parent.class}"
          end
        end

        self.class.include_helpers :passive, @object
      end

      action :test
      def test(connection)
        connection.body = StringIO.new(@object.new(connection).test)
        connection.halt
      end
    end
  end

  include_context "app"

  let :app_def do
    Proc.new do
      plug :testable, at: "/"
    end
  end

  it "exposes the parent app" do
    call("/test-plugin/parent-app").tap do |result|
      expect(result[0]).to eq(200)
      expect(result[2]).to eq("parent app: Test::Application")
    end
  end
end
