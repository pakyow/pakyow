require "spec_helper"
require "pakyow/realtime/ext/app"

describe Pakyow::App do
  describe "#socket" do
    it "creates a context with app instance" do
      expect(Pakyow::Realtime::Context).to receive(:new).with(instance_of(Pakyow::App))
      Pakyow::App.new.socket
    end

    it "returns a realtime context" do
      expect(Pakyow::App.new.socket).to be_instance_of(Pakyow::Realtime::Context)
    end
  end
end
