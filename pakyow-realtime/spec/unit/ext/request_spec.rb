require "spec_helper"
require "pakyow/realtime/ext/request"

describe Pakyow::Request do
  let :req do
    Pakyow::Request.new(env)
  end

  describe "#socket?" do
    context "when `pakyow.socket` in env is true" do
      let :env do
        { 'pakyow.socket' => true }
      end

      it "returns true" do
        expect(req.socket?).to be(true)
      end
    end
    
    context "when `pakyow.socket` in env is false" do
      let :env do
        { 'pakyow.socket' => false }
      end

      it "returns false" do
        expect(req.socket?).to be(false)
      end
    end
    
    context "when `pakyow.socket` in env is missing" do
      let :env do
        {}
      end

      it "returns false" do
        expect(req.socket?).to be(false)
      end
    end
  end
end
