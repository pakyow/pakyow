require "pakyow/plugin"

require "pakyow/support/class_state"

RSpec.describe "plugin features" do
  before do
    class TestPlugin < Pakyow::Plugin(:testable, File.join(__dir__, "support/plugin"))
      extend Pakyow::Support::ClassState
      class_state :loaded_features, default: [], inheritable: true

      aspect :feature_stubs

      action :test
      def test(connection)
        connection.body = self.class.loaded_features
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

  it "uses all features by default" do
    call("/test-plugin/features").tap do |result|
      expect(result[0]).to eq(200)
      expect(result[2].body.sort).to eq([:default, :feature_one, :feature_two])
    end
  end

  context "feature is disabled" do
    let :app_def do
      Proc.new do
        plug :testable, at: "/" do
          disable :feature_one
        end
      end
    end

    it "does not use the disabled feature" do
      call("/test-plugin/features").tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2].body).to_not include(:feature_one)
      end
    end

    it "uses the non-disabled features" do
      call("/test-plugin/features").tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2].body.sort).to eq([:default, :feature_two])
      end
    end
  end

  context "feature is enabled" do
    let :app_def do
      Proc.new do
        plug :testable, at: "/" do
          enable :feature_one
        end
      end
    end

    it "uses the enabled feature" do
      call("/test-plugin/features").tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2].body).to include(:feature_one)
      end
    end

    it "uses the default feature" do
      call("/test-plugin/features").tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2].body).to include(:default)
      end
    end

    it "does not use any non-enabled feature" do
      call("/test-plugin/features").tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2].body).to_not include(:feature_two)
      end
    end
  end

  describe "disabling multiple features" do
    let :app_def do
      Proc.new do
        plug :testable, at: "/" do
          disable :feature_one, :feature_two
        end
      end
    end

    it "disables multiple features" do
      call("/test-plugin/features").tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2].body.sort).to eq([:default])
      end
    end
  end

  describe "enabling multiple features" do
    let :app_def do
      Proc.new do
        plug :testable, at: "/" do
          enable :feature_one, :feature_two
        end
      end
    end

    it "enables multiple features" do
      call("/test-plugin/features").tap do |result|
        expect(result[0]).to eq(200)
        expect(result[2].body.sort).to eq([:default, :feature_one, :feature_two])
      end
    end
  end
end
