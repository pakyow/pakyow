RSpec.describe "nodes marked for prototype" do
  include_context "app"

  context "running in prototype mode" do
    let :mode do
      :prototype
    end

    it "does not remove the prototype nodes" do
      expect(call("/prototyping")[2]).to eq_sans_whitespace(
        <<~HTML
          <div>
            foo
          </div>
        HTML
      )
    end
  end

  context "not running in prototype mode" do
    it "removes the prototype nodes" do
      expect(call("/prototyping")[2]).to_not include_sans_whitespace(
        <<~HTML
          <div>
            foo
          </div>
        HTML
      )
    end

    it "removes prototype nodes nested within a binding" do
      expect(call("/prototyping/within_binding")[2]).to_not include_sans_whitespace(
        <<~HTML
          <div>
            foo
          </div>
        HTML
      )
    end
  end
end
