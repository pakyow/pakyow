RSpec.describe "significant nodes" do
  describe "containers" do
    it "needs specs"
  end

  describe "partials" do
    it "needs specs"
  end

  describe "scopes" do
    it "needs specs"
  end

  describe "props" do
    it "needs specs"
  end

  describe "components" do
    let :view do
      Pakyow::Presenter::View.new("<div ui=\"foo\"></div>")
    end

    it "sets data-ui" do
      expect(view.to_s).to eq("<div data-ui=\"foo\"></div>")
    end
  end

  describe "forms" do
    it "needs specs"
  end

  describe "options" do
    it "needs specs"
  end

  describe "optgroups" do
    it "needs specs"
  end

  describe "templates" do
    it "needs specs"
  end

  describe "title" do
    it "needs specs"
  end

  describe "body" do
    it "needs specs"
  end

  describe "head" do
    it "needs specs"
  end
end
