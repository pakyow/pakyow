RSpec.describe "disabling the router" do
  include_context "testable app"

  let :app_definition do
    -> {
      router do
        default do
          send "called"
        end
      end
    }
  end

  context "when the router disabled" do
    before do
      Pakyow::App.config.routing.enabled = false
    end

    it "does not call routes" do
      res = call
      expect(res[2].body.first).not_to eq("called")
    end
  end

  context "when the router is not disabled" do
    before do
      Pakyow::App.config.routing.enabled = true
    end

    it "does call routes" do
      res = call
      expect(res[2].body.first).to eq("called")
    end
  end
end
