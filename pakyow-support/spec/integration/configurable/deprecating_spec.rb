require "pakyow/support/configurable"

RSpec.describe "deprecating a setting" do
  before do
    allow(Pakyow::Support::Deprecator.global).to receive(:deprecated)
  end

  let(:object) {
    Class.new do
      include Pakyow::Support::Configurable

      deprecated_setting :name, :default
    end
  }

  context "writing the setting" do
    before do
      object.configure do
        config.name = :changed
      end

      object.configure!
    end

    it "reports the deprecation" do
      expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(
        "config.name", "do not use"
      )
    end

    it "writes the setting" do
      expect(object.config.name).to eq(:changed)
    end
  end

  context "reading the setting" do
    before do
      object.configure!
    end

    let!(:value) {
      object.config.name
    }

    it "reports the deprecation" do
      expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(
        "config.name", "do not use"
      )
    end

    it "returns the value" do
      expect(value).to eq(:default)
    end
  end

  context "setting is in a group" do
    let(:object) {
      Class.new do
        include Pakyow::Support::Configurable

        configurable :group do
          deprecated_setting :name, :default
        end
      end
    }

    before do
      object.configure do
        config.group.name = :changed
      end

      object.configure!
    end

    it "reports the correct name" do
      expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(
        "config.group.name", "do not use"
      )
    end
  end

  context "setting is in a nested group" do
    let(:object) {
      Class.new do
        include Pakyow::Support::Configurable

        configurable :group1 do
          configurable :group2 do
            deprecated_setting :name, :default
          end
        end
      end
    }

    before do
      object.configure do
        config.group1.group2.name = :changed
      end

      object.configure!
    end

    it "reports the correct name" do
      expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(
        "config.group1.group2.name", "do not use"
      )
    end
  end

  describe "providing a solution" do
    let(:object) {
      Class.new do
        include Pakyow::Support::Configurable

        deprecated_setting :name, :default, "use `other_name'"
      end
    }

    before do
      object.configure!
    end

    let!(:value) {
      object.config.name
    }

    it "reports the given solution" do
      expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(
        "config.name", "use `other_name'"
      )
    end
  end
end

RSpec.describe "deprecating a group of settings" do
  before do
    allow(Pakyow::Support::Deprecator.global).to receive(:deprecated)
  end

  let(:object) {
    Class.new do
      include Pakyow::Support::Configurable

      deprecated_configurable :group do
        setting :name, :default
      end
    end
  }

  context "writing a setting in the group" do
    before do
      object.configure do
        config.group.name = :changed
      end

      object.configure!
    end

    it "reports the deprecation" do
      expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(
        "config.group.name", "do not use"
      )
    end

    it "writes the setting" do
      expect(object.config.group.name).to eq(:changed)
    end
  end

  context "reading a setting in the group" do
    before do
      object.configure!
    end

    let!(:value) {
      object.config.group.name
    }

    it "reports the deprecation" do
      expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(
        "config.group.name", "do not use"
      )
    end

    it "returns the value" do
      expect(value).to eq(:default)
    end
  end

  describe "providing a solution" do
    let(:object) {
      Class.new do
        include Pakyow::Support::Configurable

        deprecated_configurable :group, "use `other_group'" do
          setting :name, :default
        end
      end
    }

    before do
      object.configure!
    end

    let!(:value) {
      object.config.group.name
    }

    it "reports the given solution" do
      expect(Pakyow::Support::Deprecator.global).to have_received(:deprecated).with(
        "config.group.name", "use `other_group'"
      )
    end
  end
end
