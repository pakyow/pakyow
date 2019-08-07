RSpec.describe "message handling" do
  include_context "app"
  include_context "websocket"

  let :app_def do
    local = self
    Proc.new do
      handle_websocket_message :test1 do |payload|
        local.calls << ["test1", payload, self]
      end

      handle_websocket_message :test2 do |payload|
        local.calls << ["test2", payload, self]
      end
    end
  end

  let :calls do
    []
  end

  before do
    websocket << {
      type: "test1", payload: "foo"
    }
  end

  it "calls the handler with the payload" do
    expect(calls.count).to eq(1)
    expect(calls[0][0]).to eq("test1")
    expect(calls[0][1]).to eq("foo")
  end

  describe "handler call context" do
    it "is the websocket instance" do
      expect(calls[0][2]).to be_a(Pakyow::Realtime::WebSocket)
    end
  end
end
