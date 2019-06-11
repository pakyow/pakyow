RSpec.describe "reflected attributes" do
  include_context "reflectable app"
  include_context "mirror"

  context "non-form scope" do
    let :frontend_test_case do
      "state/non_form_scope"
    end

    it "does not discover any attributes" do
      expect(scope(:post).attributes).to be_empty
    end
  end

  context "scope defined on a single form" do
    let :frontend_test_case do
      "state/single_form_scope"
    end

    it "discovers the correct attributes" do
      expect(scope(:post).attributes.count).to eq(2)
      expect(scope(:post).attributes[0].name).to eq(:title)
      expect(scope(:post).attributes[1].name).to eq(:body)
    end
  end

  context "scope defined across multiple forms" do
    let :frontend_test_case do
      "state/distributed_form_scope"
    end

    it "discovers the correct attributes" do
      expect(scope(:post).attributes.count).to eq(3)
      expect(scope(:post).attributes[0].name).to eq(:title)
      expect(scope(:post).attributes[1].name).to eq(:body)
      expect(scope(:post).attributes[2].name).to eq(:published_at)
    end
  end

  context "scoped form contains another scope" do
    let :frontend_test_case do
      "state/scope_within_form"
    end

    it "discovers the correct attributes" do
      expect(scope(:post).attributes.count).to eq(2)
      expect(scope(:post).attributes[0].name).to eq(:title)
      expect(scope(:post).attributes[1].name).to eq(:body)

      expect(scope(:user, parent: scope(:post)).attributes.count).to eq(1)
      expect(scope(:user, parent: scope(:post)).attributes[0].name).to eq(:name)
    end
  end

  context "scoped form contains a flattened scope" do
    let :frontend_test_case do
      "state/multipart_scope_within_form"
    end

    it "discovers the correct attributes" do
      expect(scope(:post).attributes.count).to eq(2)
      expect(scope(:post).attributes[0].name).to eq(:title)
      expect(scope(:post).attributes[1].name).to eq(:body)

      expect(scope(:user, parent: scope(:post)).attributes.count).to eq(1)
      expect(scope(:user, parent: scope(:post)).attributes[0].name).to eq(:name)
    end
  end

  context "field for attribute is required" do
    let :frontend_test_case do
      "attributes/required"
    end

    before do
      expect(scope(:post).attributes.count).to eq(2)
    end

    it "creates a required attribute" do
      expect(scope(:post).attributes[0].required?).to be(true)
    end

    it "does not create required attributes for others" do
      expect(scope(:post).attributes[1].required?).to be(false)
    end
  end

  context "prop within form isn't a field" do
    let :frontend_test_case do
      "state/form_prop_not_field"
    end

    it "ignores the prop" do
      expect(scope(:post).attributes).to be_empty
    end
  end

  describe "ignored attributes" do
    let :frontend_test_case do
      "attributes/ignored"
    end

    it "ignores `id`" do
      expect(scope(:post).attributes).to be_empty
    end
  end
end
