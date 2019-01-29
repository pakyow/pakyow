RSpec.describe "reflected graph" do
  include_context "reflectable app"
  include_context "mirror"

  context "scope defined on a single form" do
    let :frontend_test_case do
      "state/single_form_scope"
    end

    before do
      expect(scopes.count).to eq(1)
    end

    it "does not discover any relationships" do
      expect(scope(:post).children).to be_empty
    end
  end

  context "scope defined on a form nested within another scope" do
    let :frontend_test_case do
      "state/nested_form_scope"
    end

    before do
      expect(scopes.count).to eq(2)
    end

    it "discovers the correct children" do
      expect(scope(:post).children).to eq([scope(:comment, parent: scope(:post))])
      expect(scope(:comment, parent: scope(:post)).children).to eq([])
    end

    it "discovers the correct parents" do
      expect(scope(:post).parent).to be(nil)
      expect(scope(:comment, parent: scope(:post)).parent).to eq(scope(:post))
    end
  end

  context "scope defined on a form nested within multiple scopes" do
    let :frontend_test_case do
      "state/multiple_nested_form_scope"
    end

    before do
      expect(scopes.count).to eq(4)
    end

    it "discovers the correct children" do
      expect(scope(:post).children).to eq([scope(:comment, parent: scope(:post))])
      expect(scope(:message).children).to eq([scope(:comment, parent: scope(:message))])

      expect(scope(:comment, parent: scope(:post)).children).to eq([])
      expect(scope(:comment, parent: scope(:message)).children).to eq([])
    end

    it "discovers the correct parents" do
      expect(scope(:post).parent).to be_nil
      expect(scope(:message).parent).to be_nil
      expect(scope(:comment, parent: scope(:post)).parent).to eq(scope(:post))
      expect(scope(:comment, parent: scope(:message)).parent).to eq(scope(:message))
    end
  end

  context "scoped form contains another scope" do
    let :frontend_test_case do
      "state/scope_within_form"
    end

    before do
      expect(scopes.count).to eq(2)
    end

    it "discovers the correct children" do
      expect(scope(:post).children).to eq([scope(:user, parent: scope(:post))])
      expect(scope(:user, parent: scope(:post)).children).to be_empty
    end

    it "discovers the correct parents" do
      expect(scope(:post).parent).to be(nil)
      expect(scope(:user, parent: scope(:post)).parent).to be(scope(:post))
    end
  end

  context "scoped form has a reciprocal form to its parent" do
    let :frontend_test_case do
      "state/reciprocal_form_scopes"
    end

    before do
      expect(scopes.count).to eq(4)
    end

    it "discovers the correct children" do
      expect(scope(:post).children).to eq([scope(:comment, parent: scope(:post))])
      expect(scope(:post, parent: scope(:comment)).children).to be_empty

      expect(scope(:comment).children).to eq([scope(:post, parent: scope(:comment))])
      expect(scope(:comment, parent: scope(:post)).children).to be_empty
    end

    it "discovers the correct parents" do
      expect(scope(:post, parent: scope(:comment)).parent).to be(scope(:comment))
      expect(scope(:post).parent).to be(nil)

      expect(scope(:comment, parent: scope(:post)).parent).to be(scope(:post))
      expect(scope(:comment).parent).to be(nil)
    end
  end
end
