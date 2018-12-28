RSpec.describe "telling the user about a missing view in development" do
  include_context "app"

  let :mode do
    :development
  end

  context "view was explicitly rendered" do
    let :app_init do
      Proc.new do
        controller do
          default do
            render "/nonexistent"
          end
        end
      end
    end

    it "responds 404" do
      expect(call[0]).to eq(404)
    end

    it "includes instructions for creating a page" do
      expect(call[2].body.read).to include("Try creating a view template for this path:")
      expect(call[2].body.read).to include("frontend/pages/nonexistent.html")
    end

    it "does not include instructions for defining an endpoint" do
      expect(call[2].body.read).to_not include("If you want to call backend code instead")
    end
  end

  context "view was implicitly rendered" do
    it "responds 404" do
      expect(call("/nonexistent")[0]).to eq(404)
    end

    it "includes instructions for creating a page" do
      expect(call("/nonexistent")[2].body.read).to include("Try creating a view template for this path:")
      expect(call("/nonexistent")[2].body.read).to include("frontend/pages/nonexistent.html")
    end

    it "includes instructions for defining a route" do
      expect(call("/nonexistent")[2].body.read).to include("If you want to call backend code instead")
      expect(call("/nonexistent")[2].body.read).to include("get \"/nonexistent\" do")
    end
  end
end
