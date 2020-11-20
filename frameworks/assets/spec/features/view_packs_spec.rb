RSpec.describe "asset packs for views" do
  include_context "app"

  it "includes the layout stylesheet" do
    expect(call("/view_packs")[2]).to include("<link rel=\"stylesheet\" type=\"text/css\" media=\"all\" href=\"/assets/packs/layouts/view_packs.css\">")
  end

  it "includes the layout javascript" do
    expect(call("/view_packs")[2]).to include("<script async src=\"/assets/packs/layouts/view_packs.js\"></script>")
  end

  it "includes the page stylesheet" do
    expect(call("/view_packs")[2]).to include("<link rel=\"stylesheet\" type=\"text/css\" media=\"all\" href=\"/assets/packs/layouts/view_packs.css\">")
  end

  it "includes the page javascript" do
    expect(call("/view_packs")[2]).to include("<script async src=\"/assets/packs/pages/view_packs.js\"></script>")
  end

  describe "layout stylesheet" do
    it "includes layout styles" do
      expect(call("/assets/packs/layouts/view_packs.css")[2]).to include("view_packs.css")
    end
  end

  describe "layout javascript" do
    it "includes layout javascript" do
      expect(call("/assets/packs/layouts/view_packs.js")[2]).to include("view_packs.js")
    end
  end

  describe "page stylesheet" do
    it "includes page styles" do
      expect(call("/assets/packs/pages/view_packs.css")[2]).to include("index.css")
    end

    it "includes styles for partials included by the page" do
      expect(call("/assets/packs/pages/view_packs.css")[2]).to include("partial.css")
    end

    it "includes styles for partials included by the layout" do
      expect(call("/assets/packs/pages/view_packs.css")[2]).to include("foo.css")
    end
  end

  describe "page javascript" do
    it "includes page javascript" do
      expect(call("/assets/packs/pages/view_packs.js")[2]).to include("index.js")
    end

    it "includes javascript for partials included by the page" do
      expect(call("/assets/packs/pages/view_packs.js")[2]).to include("partial.js")
    end

    it "includes javascript for partials included by the layout" do
      expect(call("/assets/packs/pages/view_packs.js")[2]).to include("foo.js")
    end
  end
end
