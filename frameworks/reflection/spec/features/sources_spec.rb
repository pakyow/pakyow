RSpec.describe "reflected sources" do
  include_context "reflectable app"

  let :posts do
    Pakyow.apps.first.sources.each.to_a[0]
  end

  let :comments do
    Pakyow.apps.first.sources.each.to_a[1]
  end

  let :frontend_test_case do
    "sources"
  end

  it "defines a source for each discovered scope" do
    expect(posts.ancestors).to include(Pakyow::Data::Sources::Relational)
    expect(comments.ancestors).to include(Pakyow::Data::Sources::Relational)
  end

  describe "reflected source" do
    it "uses the sql adapter" do
      expect(
        posts.adapter
      ).to eq(:sql)
    end

    it "uses the configured connection" do
      expect(
        posts.connection
      ).to eq(Pakyow.apps.first.config.reflection.data.connection)
    end
  end

  context "source already exists" do
    it "extends the existing source"

    context "attribute already exists" do
      it "does not override the existing attribute"
    end

    context "association already exists" do
      it "does not override the existing association"
    end
  end
end
