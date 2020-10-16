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

  context "scope defined on a single form within a nested resource path" do
    let :frontend_test_case do
      "state/single_form_scope_in_nested_resource"
    end

    before do
      expect(scopes.count).to eq(2)
    end

    it "discovers the correct children" do
      expect(scope(:post).children).to eq([scope(:comment)])
      expect(scope(:comment).children).to eq([])
    end

    it "discovers the correct parents" do
      expect(scope(:post).parents.count).to eq(0)
      expect(scope(:comment).parents.count).to eq(1)
      expect(scope(:comment).parents[0]).to eq(scope(:post))
    end
  end

  context "scope defined on a single form within a nested resource path" do
    let :frontend_test_case do
      "state/single_form_scope_in_wrapped_nested_resource"
    end

    before do
      expect(scopes.count).to eq(2)
    end

    it "discovers the correct children" do
      expect(scope(:post).children).to eq([scope(:comment)])
      expect(scope(:comment).children).to eq([])
    end

    it "discovers the correct parents" do
      expect(scope(:post).parents.count).to eq(0)
      expect(scope(:comment).parents.count).to eq(1)
      expect(scope(:comment).parents[0]).to eq(scope(:post))
    end
  end

  context "scope defined on a single form within a nested resource path, along with the parent scope" do
    let :frontend_test_case do
      "state/single_form_scope_in_wrapped_nested_resource_with_parent_scope"
    end

    before do
      expect(scopes.count).to eq(2)
    end

    it "discovers the correct children" do
      expect(scope(:post).children).to eq([scope(:comment)])
      expect(scope(:comment).children).to eq([])
    end

    it "discovers the correct parents" do
      expect(scope(:comment).parents.count).to eq(1)
      expect(scope(:comment).parents[0]).to eq(scope(:post))
    end

    it "does not cause the parent to have a self-referential association" do
      expect(scope(:post).parents.count).to eq(0)
    end
  end

  context "scope defined on a single form within a nested resource path that is not part of the resource path" do
    let :frontend_test_case do
      "state/single_form_scope_in_wrapped_nested_resource_not_resource_path"
    end

    before do
      expect(scopes.count).to eq(3)
    end

    it "does not define the scope as a child of the parent" do
      expect(scope(:post).children).to eq([scope(:comment)])
    end

    it "does not define the scope as a parent of the child" do
      expect(scope(:user).parents).to eq([])
    end
  end

  context "scope defined on a single form on a top-level resource path" do
    let :frontend_test_case do
      "state/single_form_scope_in_top_level_resource"
    end

    before do
      expect(scopes.count).to eq(2)
    end

    it "does not define the scope as a child of the parent" do
      expect(scope(:post).children).to eq([])
    end

    it "does not define the scope as a parent of the child" do
      expect(scope(:comment).parents).to eq([])
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
      expect(scope(:post).children).to eq([scope(:comment)])
      expect(scope(:comment).children).to eq([])
    end

    it "discovers the correct parents" do
      expect(scope(:post).parents.count).to eq(0)
      expect(scope(:comment).parents.count).to eq(1)
      expect(scope(:comment).parents[0]).to eq(scope(:post))
    end
  end

  context "scope defined on a form nested within multiple scopes" do
    let :frontend_test_case do
      "state/multiple_nested_form_scope"
    end

    before do
      expect(scopes.count).to eq(3)
    end

    it "discovers the correct children" do
      expect(scope(:post).children).to eq([scope(:comment)])
      expect(scope(:message).children).to eq([scope(:comment)])

      expect(scope(:comment).children).to eq([])
      expect(scope(:comment).children).to eq([])
    end

    it "discovers the correct parents" do
      expect(scope(:post).parents.count).to eq(0)
      expect(scope(:message).parents.count).to eq(0)
      expect(scope(:comment).parents.count).to eq(2)
      expect(scope(:comment).parents).to include(scope(:post))
      expect(scope(:comment).parents).to include(scope(:message))
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
      expect(scope(:post).children).to eq([scope(:user)])
      expect(scope(:user).children).to be_empty
    end

    it "discovers the correct parents" do
      expect(scope(:post).parents.count).to eq(0)
      expect(scope(:user).parents.count).to eq(1)
      expect(scope(:user).parents[0]).to be(scope(:post))
    end
  end

  context "scoped form has a reciprocal form to its parent" do
    let :frontend_test_case do
      "state/reciprocal_form_scopes"
    end

    before do
      expect(scopes.count).to eq(2)
    end

    it "discovers the correct children" do
      expect(scope(:post).children).to eq([scope(:comment)])
      expect(scope(:comment).children).to eq([scope(:post)])
    end

    it "discovers the correct parents" do
      expect(scope(:post).parents.count).to eq(1)
      expect(scope(:post).parents[0]).to be(scope(:comment))

      expect(scope(:comment).parents.count).to eq(1)
      expect(scope(:comment).parents[0]).to be(scope(:post))
    end
  end

  context "nested scope defined on a non-form node" do
    before do
      expect(scopes.count).to eq(2)
    end

    let :frontend_test_case do
      "state/nested_non_form_scope"
    end

    it "discovers the correct children" do
      expect(scope(:post).children).to eq([scope(:comment)])
      expect(scope(:comment).children).to eq([])
    end

    it "discovers the correct parents" do
      expect(scope(:post).parents.count).to eq(0)
      expect(scope(:comment).parents.count).to eq(1)
      expect(scope(:comment).parents[0]).to eq(scope(:post))
    end
  end

  context "nested scope defined on a form node without fields" do
    before do
      expect(scopes.count).to eq(1)
    end

    let :frontend_test_case do
      "state/nested_form_scope_without_fields"
    end

    it "discovers the correct children" do
      expect(scope(:post).children).to eq([])
    end

    it "discovers the correct parents" do
      expect(scope(:post).parents.count).to eq(0)
    end
  end
end
