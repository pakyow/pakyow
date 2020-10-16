require "pakyow/assets/babel"

RSpec.describe Pakyow::Assets::Babel do
  before do
    allow(Pakyow::Assets::Scripts::Babel).to receive(:transform)
  end

  describe "::transform" do
    it "is deprecated" do
      expect(Pakyow::Support::Deprecator.global).to receive(:deprecated).with(
        Pakyow::Assets::Babel, :transform, solution: "use `Pakyow::Assets::Scripts::Babel::transform'"
      )

      described_class.transform("")
    end

    it "calls Pakyow::Assets::Scripts::Babel::transform" do
      expect(Pakyow::Assets::Scripts::Babel).to receive(:transform).with(
        "code", foo: "bar"
      )

      Pakyow::Support::Deprecator.global.ignore do
        described_class.transform("code", foo: "bar")
      end
    end
  end
end
