RSpec.describe "single exposure: root dataset limit" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "endpoints/exposures/single-scope/root-dataset-limit"
  end

  before do
    expect(controllers.count).to eq(1)
  end

  it "defines a reflected controller for the view route" do
    expect(controller(:root)).to_not be(nil)
    expect(controller(:root).path_to_self).to eq("/")
    expect(controller(:root).ancestors).to include(Pakyow::Reflection::Extension::Controller)
    expect(controller(:root).routes.values.flatten.count).to eq(1)
  end

  it "defines a route for the view" do
    expect(controller(:root).routes[:get][0].name).to eq(:default)
    expect(controller(:root).routes[:get][0].path).to eq("/")
  end

  describe "behavior" do
    before do
      data.posts.create(title: "one")
      data.posts.create(title: "two")
      data.posts.create(title: "three")
    end

    it "presents data for the dataset" do
      response_body = call("/")[2]

      expect(response_body).to include_sans_whitespace(
        <<~HTML
          <article data-b="post" data-id="1">
            <h1 data-b="title">one</h1>
          </article>

          <article data-b="post" data-id="2">
            <h1 data-b="title">two</h1>
          </article>
        HTML
      )

      expect(response_body).not_to include_sans_whitespace(
        <<~HTML
          <article data-b="post" data-id="3">
            <h1 data-b="title">three</h1>
          </article>
        HTML
      )
    end
  end
end
