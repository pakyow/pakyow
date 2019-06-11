RSpec.describe "reflected state" do
  include_context "reflectable app"
  include_context "mirror"

  context "no scope" do
    let :frontend_test_case do
      "state/no_scope"
    end

    it "does not discover any scopes" do
      expect(scopes).to be_empty
    end
  end

  context "non-form scope" do
    let :frontend_test_case do
      "state/non_form_scope"
    end

    it "discovers the correct scopes" do
      expect(scopes.count).to eq(1)
      expect(scopes[0].name).to eq(:post)
    end
  end

  context "scope defined on a single form" do
    let :frontend_test_case do
      "state/single_form_scope"
    end

    it "discovers the correct scopes" do
      expect(scopes.count).to eq(1)
      expect(scopes[0].name).to eq(:post)
    end
  end

  context "scope defined across multiple forms" do
    let :frontend_test_case do
      "state/distributed_form_scope"
    end

    it "discovers the correct scopes" do
      expect(scopes.count).to eq(1)
      expect(scopes[0].name).to eq(:post)
    end
  end
end
