RSpec.describe "single exposure: root deeply nested data" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "endpoints/exposures/single-scope/root-deeply-nested-data"
  end

  let :reflected_app_def do
    Proc.new do
      source :posts do
        belongs_to :user
      end

      source :comments do
        belongs_to :user
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
      user1 = data.users.create(name: "u1")
      user2 = data.users.create(name: "u2")
      user3 = data.users.create(name: "u3")

      post1 = data.posts.create(title: "foo", user: user1)
      post2 = data.posts.create(title: "bar", user: user3)

      data.comments.create(post: post1, body: "c1", user: user2)
      data.comments.create(post: post1, body: "c2", user: user3)
      data.comments.create(post: post2, body: "c3", user: user1)
    end

    it "presents data for the dataset" do
      expect(call("/")[2]).to include_sans_whitespace(
        <<~HTML
          <article data-b="post" data-id="1">
            <h1 data-b="title">foo</h1>

            <div data-b="user" data-id="1">
              <span data-b="name">u1</span>
            </div>

            <script type="text/template" data-b="user">
              <div data-b="user">
                <span data-b="name"></span>
              </div>
            </script>

            <article data-b="comment" data-id="1">
              <p data-b="body">c1</p>

              <div data-b="user" data-id="2">
                <span data-b="name">u2</span>
              </div>

              <script type="text/template" data-b="user">
                <div data-b="user">
                  <span data-b="name"></span>
                </div>
              </script>
            </article>

            <article data-b="comment" data-id="2">
              <p data-b="body">c2</p>

              <div data-b="user" data-id="3">
                <span data-b="name">u3</span>
              </div>

              <script type="text/template" data-b="user">
                <div data-b="user">
                  <span data-b="name"></span>
                </div>
              </script>
            </article>

            <script type="text/template" data-b="comment">
              <article data-b="comment">
                <p data-b="body"></p>

                <div data-b="user">
                  <span data-b="name"></span>
                </div>
              </article>
            </script>
          </article>

          <article data-b="post" data-id="2">
            <h1 data-b="title">bar</h1>

            <div data-b="user" data-id="3">
              <span data-b="name">u3</span>
            </div>

            <script type="text/template" data-b="user">
              <div data-b="user">
                <span data-b="name"></span>
              </div>
            </script>

            <article data-b="comment" data-id="3">
              <p data-b="body">c3</p>

              <div data-b="user" data-id="1">
                <span data-b="name">u1</span>
              </div>

              <script type="text/template" data-b="user">
                <div data-b="user">
                  <span data-b="name"></span>
                </div>
              </script>
            </article>

            <script type="text/template" data-b="comment">
              <article data-b="comment">
                <p data-b="body"></p>

                <div data-b="user">
                  <span data-b="name"></span>
                </div>
              </article>
            </script>
          </article>

          <script type="text/template" data-b="post">
            <article data-b="post">
              <h1 data-b="title"></h1>

              <div data-b="user">
                <span data-b="name"></span>
              </div>

              <article data-b="comment">
                <p data-b="body"></p>

                <div data-b="user">
                  <span data-b="name"></span>
                </div>
              </article>
            </article>
          </script>
        HTML
      )
    end
  end
end
