require "pakyow/plugin"

RSpec.describe Pakyow::Plugin do
  let :instance do
    subclass.new(app)
  end

  let :subclass do
    Pakyow::Plugin(:test, "/")
  end

  let :app do
    double(:app, environment: :test)
  end

  describe "#top" do
    before do
      allow(app).to receive(:top).and_return(app)
    end

    it "returns parent top" do
      expect(instance.top).to be(app)
    end
  end
end
