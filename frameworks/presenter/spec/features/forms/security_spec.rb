RSpec.describe "form sanitization during presentation" do
  include Pakyow::Support::SafeStringHelpers

  include_context "app"

  let :presenter do
    Pakyow.apps.first.isolated(:Presenter).new(view, app: Pakyow.apps[0])
  end

  context "creating select options" do
    let :view do
      Pakyow::Presenter::View.new("<form binding=\"post\"><select binding=\"tag\"></select></form>")
    end

    before do
      presenter.form(:post).options_for(:tag, [[">haha", ">lol"]])
    end

    it "escapes the submitted and presented values" do
      expect(presenter.view.to_s).to include("<option value=\"&gt;haha\">&gt;lol</option>")
    end
  end

  context "creating grouped select options" do
    let :view do
      Pakyow::Presenter::View.new("<form binding=\"post\"><select binding=\"tag\"></select></form>")
    end

    before do
      presenter.form(:post).grouped_options_for(:tag, [["\"><script></script>", [[">haha", ">lol"]]]])
    end

    it "escapes the group label" do
      expect(presenter.view.to_s).to include("<optgroup label=\"&quot;&gt;&lt;script&gt;&lt;/script&gt;\">")
    end

    it "escapes the submitted and presented values" do
      expect(presenter.view.to_s).to include("<option value=\"&gt;haha\">&gt;lol</option>")
    end
  end
end
