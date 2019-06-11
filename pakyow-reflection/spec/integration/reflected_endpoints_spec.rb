RSpec.describe "reflected endpoints" do
  include_context "reflectable app"
  include_context "mirror"

  context "scoped form" do
    let :frontend_test_case do
      "endpoints/form"
    end

    before do
      expect(scopes.count).to eq(1)
      expect(scope(:post).endpoints.count).to eq(2)
    end

    it "discovers each endpoint" do
      expect(endpoint(:post, "/")).to_not be(nil)
      expect(endpoint(:post, "/posts/new")).to_not be(nil)
    end

    it "discovers each endpoint's channel" do
      expect(endpoint(:post, "/").channel).to eq([:form])
      expect(endpoint(:post, "/posts/new").channel).to eq([:form])
    end
  end

  context "non-form scope" do
    let :frontend_test_case do
      "endpoints/non-form"
    end

    before do
      expect(scopes.count).to eq(1)
      expect(scope(:post).endpoints.count).to eq(2)
    end

    it "discovers each endpoint" do
      expect(endpoint(:post, "/")).to_not be(nil)
      expect(endpoint(:post, "/posts")).to_not be(nil)
    end
  end

  context "channeled scope" do
    let :frontend_test_case do
      "endpoints/channeled"
    end

    before do
      expect(scopes.count).to eq(1)
      expect(scope(:post).endpoints.count).to eq(1)
    end

    it "discovers the channel" do
      expect(endpoint(:post, "/").channel).to eq([:article, :foo])
    end
  end
end
