require "pakyow/plugin"

RSpec.describe "booting plugins" do
  let!(:plugin) {
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      action :test
      def test(connection)
        connection.body = StringIO.new((@value || :did_not_boot).to_s)
        connection.halt
      end
    end

    TestPlugin
  }

  include_context "app"

  let :app_def do
    local = self
    Proc.new do
      plug :testable, at: "/" do
        after :boot do
          local.instance_variable_set(:@booted, true)
        end
      end
    end
  end

  let :autorun do
    false
  end

  it "calls boot hooks" do
    setup_and_run
    expect(@booted).to eq(true)
  end

  context "plugin implements boot" do
    before do
      plugin.class_eval do
        def boot
          @value = :booted
        end
      end

      setup_and_run
    end

    it "calls boot" do
      expect(call("/")[0]).to eq(200)
      expect(call("/")[2]).to eq("booted")
    end
  end

  context "plugin does not implement boot" do
    before do
      if plugin.method_defined?(:boot)
        plugin.remove_method(:boot)
      end

      setup_and_run
    end

    it "calls boot" do
      expect(call("/")[0]).to eq(200)
      expect(call("/")[2]).to eq("did_not_boot")
    end
  end
end
