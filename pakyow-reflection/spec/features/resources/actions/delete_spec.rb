require_relative "./shared"

RSpec.describe "reflected resource delete action" do
  include_context "resource action"

  let :frontend_test_case do
    "resources/actions/delete"
  end

  let :values do
    {}
  end

  let :path do
    "/posts/#{deletable.one.id}"
  end

  let :method do
    :delete
  end

  let :form do
    {
      view_path: "/"
    }
  end

  let :deletable do
    data.posts.create
  end

  let :nondeletable do
    data.posts.create
  end

  before do
    deletable
    nondeletable
  end

  it "deletes the object, leaving other data unaltered" do
    expect {
      expect(response[0]).to eq(200)
    }.to change {
      data.posts.count
    }.from(2).to(1)
  end

  context "object to delete is not found" do
    it "returns 404"
  end

  context "resource is nested" do
    it "needs tests"
  end

  context "source has dependents" do
    # TODO: we raise by default; thinking of these options:
    #
    #  1) continue to raise in this case, but offer a better explanation for resolving the issue
    #  2) setup reflected associations to delete dependent data rather than raise
    #  3) delete data that's nested within the view
    #
    # 3 doesn't work for all use cases, so it's out; 1 makes reflection lose some of its magic
    #
    # 2 is the obvious choice here... unless I've missed something; could also nullify but that
    # option violates the default behavior of not keeping data around; long term though I could
    # see the desire to have an undo function everywhere, including deletes... in this case you'd
    # nullify and then keep the data around for some reasonable amount of time before cleaning
    # but really this would be implemented as soft delete, not nullification... so just delete
    #
    it "needs tests"
  end

  context "without a valid authenticity token" do
    let :authenticity_token do
      "foo:bar"
    end

    it "fails to delete" do
      expect {
        expect(response[0]).to eq(403)
      }.not_to change {
        data.posts.count
      }
    end
  end

  context "resource is already defined" do
    it "needs tests"
  end

  describe "redirecting after delete" do
    it "needs tests"
  end

  describe "skipping the reflected behavior" do
    it "needs tests"
  end

  describe "validating the action" do
    it "needs tests"
  end
end
