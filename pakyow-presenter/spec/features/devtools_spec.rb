RSpec.describe "devtools" do
  include_context "app"

  context "in prototype mode" do
    let :mode do
      :prototype
    end

    it "renders the devtools" do
      expect(call("/prototyping/prototype_bar")[2]).to include_sans_whitespace(
        <<~HTML
          <div class="pw-devtools" data-ui="devtools(environment: prototype, viewPath: /prototyping/prototype_bar); devtools:reloader">
            <div class="pw-devtools__versions">
              UI Mode: <select class="pw-devtools__mode-selector" data-ui="devtools:mode-selector">
                <option value="default" selected="selected">Default</option>
              </select>
            </div>

            <div class="pw-devtools__environment" data-ui="devtools:environment">
              Prototype
            </div>
          </div>
        HTML
      )
    end

    context "view does not contain a body" do
      it "does not render the devtools" do
        expect(call("/prototyping/prototype_bar/no_body")[2]).not_to include_sans_whitespace(
          <<~HTML
            div class="pw-devtools"
          HTML
        )
      end
    end
  end

  context "in development mode" do
    let :mode do
      :development
    end

    it "renders the devtools" do
      expect(call("/prototyping/prototype_bar")[2]).to include_sans_whitespace(
        <<~HTML
          <div class="pw-devtools" data-ui="devtools(environment: development, viewPath: /prototyping/prototype_bar); devtools:reloader">
            <div class="pw-devtools__environment" data-ui="devtools:environment">
              Development
            </div>
          </div>
        HTML
      )
    end

    context "view does not contain a body" do
      it "does not render the bar" do
        expect(call("/prototyping/prototype_bar/no_body")[2]).not_to include_sans_whitespace(
          <<~HTML
            div class="pw-devtools"
          HTML
        )
      end
    end
  end

  context "not in prototype or development mode" do
    let :mode do
      :test
    end

    it "does not render the bar" do
      expect(call("/prototyping/prototype_bar")[2]).not_to include_sans_whitespace(
        <<~HTML
          div class="pw-devtools"
        HTML
      )
    end
  end
end
