require "spec_helper"
require "pakyow/core/app"

RSpec.describe Pakyow::App do
  let :app do
    Pakyow::App.new :test
  end

  it "is hookable" do
    expect(Pakyow::App.ancestors).to include(Pakyow::Support::Hookable)
  end

  describe "known events" do
    describe "init" do
      it "is known" do
        expect(Pakyow::App.is_known_event?(:init)).to be true
      end
    end

    describe "configure" do
      it "is known" do
        expect(Pakyow::App.is_known_event?(:configure)).to be true
      end
    end

    describe "load" do
      it "is known" do
        expect(Pakyow::App.is_known_event?(:load)).to be true
      end
    end

    describe "reload" do
      it "is known" do
        expect(Pakyow::App.is_known_event?(:reload)).to be true
      end
    end

    # TODO: move to test pakyow/environment
    # describe "fork" do
    #   it "is known" do
    #     expect(Pakyow::App.is_known_event?(:fork)).to be true
    #   end
    # end
  end

  # TODO: move to test pakyow/environment
  # describe "#forking" do
  #   it "calls before: :fork hooks" do
  #     expect(app).to receive(:call_hooks).with(:before, :fork)
  #     app.forking
  #   end
  # end

  # TODO: move to test pakyow/environment
  # describe "#forked" do
  #   it "calls after: :fork hooks" do
  #     expect(app).to receive(:call_hooks).with(:after, :fork)
  #     app.forked
  #   end
  # end
end
