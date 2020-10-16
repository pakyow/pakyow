RSpec.describe "overriding reflected exposures" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "endpoints/exposures/overriding"
  end

  let :reflected_app_def do
    Proc.new do
      controller :root do
        default do
          reflect

          expose "post", data.posts.by_id(1)
        end
      end
    end
  end

  before do
    data.posts.create(title: "foo")
    data.posts.create(title: "bar")
  end

  it "overrides as expected" do
    body = call("/")[2]

    expect(body).to include_sans_whitespace(
      <<~HTML
        <article data-b="post" data-id="1">
          <h1 data-b="title">foo</h1>
        </article>
      HTML
    )

    expect(body).not_to include("bar")
  end
end
