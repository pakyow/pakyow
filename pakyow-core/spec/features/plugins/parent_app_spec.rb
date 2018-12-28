require "pakyow/plugin"

RSpec.describe "accessing the parent app from a plugin" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      def boot
        @object = Class.new do
          def initialize(connection)
            @connection = connection
          end

          def test
            "parent app: #{parent_app.class}"
          end
        end

        self.class.include_helpers :passive, @object
      end

      action :test
      def test(connection)
        connection.body = @object.new(connection).test
        connection.halt
      end
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)
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
      expect(result[2].body).to eq("parent app: Test::App")
    end
  end
end
