RSpec.describe "single exposure: root dataset query versioned" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "endpoints/exposures/single-scope/root-dataset-query-versioned"
  end

  let :reflected_app_def do
    Proc.new do
      source :posts do
        def red
          where(build("title like '%red%'"))
        end
      end
    end
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
      data.posts.create(title: "red")
      data.posts.create(title: "blue")
      data.posts.create(title: "green")
      data.posts.create(title: "reddish")
    end

    it "presents data for the dataset" do
      expect(call("/")[2]).to include_sans_whitespace(
        <<~HTML
          <article data-b="post" data-id="1">
            <h1 data-b="title">red</h1>
          </article>

          <article data-b="post" data-id="4">
            <h1 data-b="title">reddish</h1>
          </article>
        HTML
      )
    end
  end
end
