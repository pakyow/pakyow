require "pakyow/support/configurable"

RSpec.describe "deprecating a setting" do
  before do
    allow(Pakyow::Support::Deprecator.global).to receive(:deprecated)
  end

  let(:object) {
    Class.new {
      include Pakyow::Support::Configurable
      setting :name, :default

      config.deprecate :name
    }.tap do |object|
      stub_const "Configurable", object
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
        "Configurable.config.name", solution: "do not use"
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

    let(:value) {
      object.config.name
    }

    it "reports the deprecation" do
      expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(
        "Configurable.config.name", solution: "do not use"
      )

      value
    end

    it "returns the value" do
      expect(value).to eq(:default)
    end
  end

  context "config is for an anonymous class" do
    let(:object) {
      Class.new {
        include Pakyow::Support::Configurable
        setting :name, :default

        config.deprecate :name
      }
    }

    before do
      object.configure!
    end

    let(:value) {
      object.config.name
    }

    it "reports the deprecation" do
      expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(
        "config.name", solution: "do not use"
      )

      value
    end
  end

  context "setting is in a group" do
    let(:object) {
      Class.new {
        include Pakyow::Support::Configurable

        configurable :group do
          setting :name, :default
          deprecate :name
        end
      }.tap do |object|
        stub_const "Configurable", object
      end
    }

    before do
      object.configure do
        config.group.name = :changed
      end
    end

    it "reports the correct name" do
      expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(
        "Configurable.config.group.name", solution: "do not use"
      )

      object.configure!
    end
  end

  context "setting is in a nested group" do
    let(:object) {
      Class.new {
        include Pakyow::Support::Configurable

        configurable :group1 do
          configurable :group2 do
            setting :name, :default
            deprecate :name
          end
        end
      }.tap do |object|
        stub_const "Configurable", object
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
        "Configurable.config.group1.group2.name", solution: "do not use"
      )
    end
  end

  describe "providing a solution" do
    let(:object) {
      Class.new {
        include Pakyow::Support::Configurable

        setting :name, :default
        config.deprecate :name, solution: "use `other_name'"
      }.tap do |object|
        stub_const "Configurable", object
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
        "Configurable.config.name", solution: "use `other_name'"
      )
    end
  end
end

RSpec.describe "deprecating a group of settings" do
  before do
    allow(Pakyow::Support::Deprecator.global).to receive(:deprecated)
  end

  let(:object) {
    Class.new {
      include Pakyow::Support::Configurable

      configurable :group do
        setting :name, :default
      end

      config.deprecate :group
    }.tap do |object|
      stub_const "Configurable", object
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
        "Configurable.config.group", solution: "do not use"
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
        "Configurable.config.group", solution: "do not use"
      )
    end

    it "returns the value" do
      expect(value).to eq(:default)
    end
  end

  describe "providing a solution" do
    let(:object) {
      Class.new {
        include Pakyow::Support::Configurable

        configurable :group do
          setting :name, :default
        end

        config.deprecate :group, solution: "use `other_group'"
      }.tap do |object|
        stub_const "Configurable", object
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
        "Configurable.config.group", solution: "use `other_group'"
      )
    end
  end
end
