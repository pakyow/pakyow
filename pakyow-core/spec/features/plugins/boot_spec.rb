require "pakyow/plugin"

RSpec.describe "booting plugins" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      action :test
      def test(connection)
        connection.body = @value || :did_not_boot
        connection.halt
      end
    end
  end

  after do
    Object.send(:remove_const, :TestPlugin)
  end

  include_context "testable app"

  let :app_definition do
    Proc.new {
      plug :testable, at: "/"
    }
  end

  let :autorun do
    false
  end

  context "plugin implements boot" do
    before do
      TestPlugin.class_eval do
        def boot
          @value = :booted
        end
      end

      run_app
    end

    it "calls boot" do
      expect(call("/")[0]).to eq(200)
      expect(call("/")[2].body).to eq(:booted)
    end
  end

  context "plugin does not implement boot" do
    before do
      if TestPlugin.method_defined?(:boot)
        TestPlugin.remove_method(:boot)
      end

      run_app
    end

    it "calls boot" do
      expect(call("/")[0]).to eq(200)
      expect(call("/")[2].body).to eq(:did_not_boot)
    end
  end
end
