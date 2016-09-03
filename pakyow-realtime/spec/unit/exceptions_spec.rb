require "spec_helper"
require "pakyow/realtime/exceptions"

describe Pakyow::Realtime::MissingMessageHandler do
  it "subclasses `Pakyow::Error`" do
    expect(Pakyow::Realtime::MissingMessageHandler.ancestors).to include(Pakyow::Error)
  end
end
