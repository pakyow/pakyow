require "pakyow/plugin"

RSpec.describe Pakyow::Plugin do
  let :instance do
    subclass.new(app)
  end

  let :subclass do
    Pakyow::Plugin(:test, "/").tap do |subclass|
      subclass.instance_variable_set(:@__object_name, Pakyow::Support::ObjectName.build(:test, "plugin"))
    end
  end

  let :app do
    Class.new(Pakyow::Application).new(:test)
  end

  describe "#top" do
    before do
      allow(app).to receive(:top).and_return(:top)
    end

    it "returns parent top" do
      expect(instance.top).to eq(:top)
    end
  end
end
