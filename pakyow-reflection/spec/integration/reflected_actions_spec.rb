RSpec.describe "reflected actions" do
  include_context "reflectable app"
  include_context "mirror"

  context "scoped form" do
    let :frontend_test_case do
      "actions/form"
    end

    before do
      expect(scopes.count).to eq(1)
      expect(scope(:post).actions.count).to eq(1)
    end

    it "discovers a create action" do
      expect(action(:post, :create)).to_not be(nil)
    end

    describe "action" do
      it "defines the view path" do
        expect(action(:post, :create).view_path).to eq("/")
      end

      it "defines the channel" do
        expect(action(:post, :create).channel).to eq([:form])
      end

      it "defines the attributes" do
        attributes = action(:post, :create).attributes
        expect(attributes.count).to eq(1)
        expect(attributes[0].name).to eq(:title)
        expect(attributes[0].type).to eq(:string)
      end
    end
  end

  context "scoped form defines a channel" do
    let :frontend_test_case do
      "actions/channeled_form"
    end

    before do
      expect(scopes.count).to eq(1)
      expect(scope(:post).actions.count).to eq(1)
    end

    it "discovers a create action with the proper channel" do
      expect(action(:post, :create).channel).to eq([:form, :foo])
    end
  end

  context "scoped form is within another scope" do
    let :frontend_test_case do
      "actions/form_within_scope"
    end

    before do
      expect(scopes.count).to eq(2)
      expect(scope(:post).actions).to be_empty
      expect(scope(:comment, parent: scope(:post)).actions.count).to eq(1)
    end

    it "discovers a create action in the scope with a parent" do
      expect(scope(:comment, parent: scope(:post)).parent).to be(scope(:post))
      expect(scope(:comment, parent: scope(:post)).actions[0].name).to eq(:create)
    end
  end

  context "scoped form contains nested data" do
    let :frontend_test_case do
      "actions/form_with_nested_data"
    end

    before do
      expect(scopes.count).to eq(2)
      expect(scope(:user).actions.count).to eq(1)
      expect(scope(:link, parent: scope(:user)).actions.count).to eq(0)
    end

    it "discovers a create action with the nested data" do
      expect(scope(:user).actions[0].nested.count).to eq(1)
      expect(scope(:user).actions[0].nested[0].name).to eq(:link)
      expect(scope(:user).actions[0].nested[0].attributes.count).to eq(1)
      expect(scope(:user).actions[0].nested[0].attributes[0].name).to eq(:url)
      expect(scope(:user).actions[0].nested[0].nested.count).to eq(0)
    end
  end

  context "scoped form contains deeply nested data" do
    let :frontend_test_case do
      "actions/form_with_deeply_nested_data"
    end

    before do
      expect(scopes.count).to eq(3)
      expect(scope(:user).actions.count).to eq(1)
      expect(scope(:link, parent: scope(:user)).actions.count).to eq(0)
      expect(scope(:url, parent: scope(:link, parent: scope(:user))).actions.count).to eq(0)
    end

    it "discovers a create action with the deeply nested data" do
      expect(scope(:user).actions[0].nested.count).to eq(1)
      expect(scope(:user).actions[0].nested[0].name).to eq(:link)
      expect(scope(:user).actions[0].nested[0].attributes.count).to eq(1)
      expect(scope(:user).actions[0].nested[0].attributes[0].name).to eq(:enabled)
      expect(scope(:user).actions[0].nested[0].nested.count).to eq(1)
      expect(scope(:user).actions[0].nested[0].nested[0].name).to eq(:url)
      expect(scope(:user).actions[0].nested[0].nested[0].attributes.count).to eq(1)
      expect(scope(:user).actions[0].nested[0].nested[0].attributes[0].name).to eq(:value)
      expect(scope(:user).actions[0].nested[0].nested[0].nested.count).to eq(0)
    end
  end

  context "scoped form has an explicit endpoint" do
    before do
      expect(scopes.count).to eq(1)
    end

    context "explicit endpoint is create" do
      let :frontend_test_case do
        "actions/form_with_explicit_create_endpoint"
      end

      before do
        expect(scopes.count).to eq(1)
        expect(scope(:post).actions.count).to eq(1)
      end

      it "discovers a create action" do
        expect(action(:post, :create)).to_not be(nil)
      end
    end

    context "explicit endpoint is update" do
      let :frontend_test_case do
        "actions/form_with_explicit_update_endpoint"
      end

      before do
        expect(scopes.count).to eq(1)
        expect(scope(:post).actions.count).to eq(1)
      end

      it "discovers an update action" do
        expect(action(:post, :update)).to_not be(nil)
      end
    end

    context "explicit endpoint is delete" do
      let :frontend_test_case do
        "actions/form_with_explicit_delete_endpoint"
      end

      before do
        expect(scopes.count).to eq(1)
        expect(scope(:post).actions.count).to eq(1)
      end

      it "discovers a delete action" do
        expect(action(:post, :delete)).to_not be(nil)
      end
    end

    context "explicit endpoint is not create, update, or delete" do
      let :frontend_test_case do
        "actions/form_with_explicit_endpoint"
      end

      before do
        expect(scopes.count).to eq(1)
      end

      it "does not discover an action" do
        expect(scope(:post).actions).to be_empty
      end
    end
  end

  context "scoped form has an explicit endpoint for another scope" do
    before do
      expect(scopes.count).to eq(1)
    end

    let :frontend_test_case do
      "actions/form_with_explicit_create_endpoint_for_other_scope"
    end

    before do
      expect(scopes.count).to eq(1)
    end

    it "does not discover an action" do
      expect(scope(:post).actions).to be_empty
    end
  end

  context "scoped form at the edit view path" do
    context "binding matches the resource" do
      let :frontend_test_case do
        "actions/form_in_edit_path"
      end

      before do
        expect(scopes.count).to eq(1)
        expect(scope(:post).actions.count).to eq(1)
      end

      it "discovers an update action" do
        expect(action(:post, :update)).to_not be(nil)
      end
    end

    context "binding does not match the resource" do
      let :frontend_test_case do
        "actions/form_in_edit_path_for_other_scope"
      end

      before do
        expect(scopes.count).to eq(1)
        expect(scope(:message).actions.count).to eq(1)
      end

      it "discovers a create action" do
        expect(action(:message, :create)).to_not be(nil)
      end
    end
  end

  context "scoped form at the show view path" do
    context "binding matches the resource" do
      let :frontend_test_case do
        "actions/form_in_show_path"
      end

      before do
        expect(scopes.count).to eq(1)
        expect(scope(:post).actions.count).to eq(1)
      end

      it "discovers an update action" do
        expect(action(:post, :update)).to_not be(nil)
      end
    end

    context "binding does not match the resource" do
      let :frontend_test_case do
        "actions/form_in_show_path_for_other_scope"
      end

      before do
        expect(scopes.count).to eq(1)
        expect(scope(:message).actions.count).to eq(1)
      end

      it "discovers a create action" do
        expect(action(:message, :create)).to_not be(nil)
      end
    end
  end

  context "multiple forms for the same scope" do
    let :frontend_test_case do
      "actions/multiple_forms"
    end

    before do
      expect(scopes.count).to eq(1)
      expect(scope(:post).actions.count).to eq(3)
    end

    it "discovers each action" do
      expect(scope(:post).actions[0].name).to eq(:create)
      expect(scope(:post).actions[0].view_path).to eq("/")

      expect(scope(:post).actions[1].name).to eq(:update)
      expect(scope(:post).actions[1].view_path).to eq("/posts/edit")

      expect(scope(:post).actions[2].name).to eq(:create)
      expect(scope(:post).actions[2].view_path).to eq("/foo")
    end
  end

  context "multiple forms for the same scope with different parents" do
    let :frontend_test_case do
      "actions/multiple_forms_different_parents"
    end

    before do
      expect(scopes.count).to eq(4)
    end

    it "discovers each action" do
      expect(scope(:message).actions).to be_empty
      expect(scope(:comment, parent: scope(:message)).actions.count).to eq(1)
      expect(scope(:comment, parent: scope(:message)).actions[0].name).to eq(:create)

      expect(scope(:post).actions).to be_empty
      expect(scope(:comment, parent: scope(:post)).actions.count).to eq(1)
      expect(scope(:comment, parent: scope(:post)).actions[0].name).to eq(:create)
    end
  end

  context "link with a naked delete endpoint" do
    let :frontend_test_case do
      "actions/delete_link"
    end

    before do
      expect(scopes.count).to eq(1)
    end

    it "discovers a delete action" do
      expect(action(:post, :delete)).to_not be(nil)
    end
  end

  context "link with a delete endpoint within a scope" do
    let :frontend_test_case do
      "actions/delete_link_within_scope"
    end

    before do
      expect(scopes.count).to eq(1)
    end

    it "discovers a delete action" do
      expect(action(:post, :delete)).to_not be(nil)
    end
  end
end
