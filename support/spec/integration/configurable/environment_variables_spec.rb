require "pakyow/support/configurable"

RSpec.describe "configuring with environment variables" do
  let(:object) {
    Class.new {
      include Pakyow::Support::Configurable

      envar :pwtest
    }
  }

  before do
    ENV["PWTEST__FOO"] = "env_foo"
    ENV["PWTEST__BAR__BAZ"] = "env_bar_baz"
    ENV["PWTEST__BAZ__QUX__QUUX"] = "env_baz_qux_quux"

    object.setting :foo

    object.configurable :bar do
      setting :baz
    end

    object.configurable :baz do
      configurable :qux do
        setting :quux
      end
    end
  end

  it "uses the environment variable value for a setting" do
    expect(object.config.foo).to eq("env_foo")
  end

  it "uses the environment variable value for a setting in a group" do
    expect(object.config.bar.baz).to eq("env_bar_baz")
  end

  it "uses the environment variable value for a setting in a nested group" do
    expect(object.config.baz.qux.quux).to eq("env_baz_qux_quux")
  end

  describe "instance config" do
    let(:instance) {
      object.new
    }

    it "uses the environment variable value for an instance-level setting" do
      expect(instance.config.foo).to eq("env_foo")
    end
  end

  context "object is configured" do
    def configure
      object.configure do
        config.foo = "configured_foo"
      end

      object.configure!
    end

    it "gives precedence to the environment variable" do
      configure

      expect(object.config.foo).to eq("env_foo")
    end

    context "environment variable is not passed" do
      before do
        ENV.delete("PWTEST__FOO")
      end

      it "uses the configured value" do
        configure

        expect(object.config.foo).to eq("configured_foo")
      end
    end
  end

  context "configurable does not define an envar prefix" do
    let(:object) {
      Class.new {
        include Pakyow::Support::Configurable
      }
    }

    it "does not configure the setting" do
      expect(object.config.foo).to eq(nil)
    end
  end
end
