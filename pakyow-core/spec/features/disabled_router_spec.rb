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
    let :autorun do
      false
    end

    before do
      Pakyow::App.config.routing.enabled = false
      run
    end

    it "does not call routes" do
      res = call
      expect(res[2].body.first).not_to eq("called")
    end
  end

  context "when the router is not disabled" do
    let :autorun do
      false
    end

    before do
      Pakyow::App.config.routing.enabled = true
      run
    end

    it "does call routes" do
      res = call
      expect(res[2].body.first).to eq("called")
    end
  end
end
