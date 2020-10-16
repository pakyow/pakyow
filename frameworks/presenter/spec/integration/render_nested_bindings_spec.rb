require "pakyow/support/deep_freeze"

RSpec.describe "rendering nested bindings from a presenter" do
  using Pakyow::Support::DeepFreeze

  include_context "app"

  let :doc do
    StringDoc.new(html)
  end

  let :html do
    <<~HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="utf-8">
      </head>

      <body>
        <article binding="post">
          <h1 binding="title">title goes here</h1>

          <div binding="comment">
            <p binding="body">body goes here</p>
          </div>
        </article>
      </body>
      </html>
    HTML
  end

  let :view do
    Pakyow::Presenter::View.from_object(doc).tap do |view|
      presenter_class.attach(view)
    end
  end

  let :presenter do
    presenter_class.new(view, app: app)
  end

  let :presenter_class do
    app.isolated(:Presenter) do
      render :post do
        present(
          [
            { title: "foo", comments: [{body: "foo comment"}] }
          ]
        )
      end

      render :post, :comment do
        attributes[:class] << :red
      end
    end
  end

  it "renders the nested binding correctly" do
    expect(presenter.to_html).to eq_sans_whitespace(
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
        </head>

        <body>
          <article data-b="post">
            <h1 data-b="title">foo</h1>

            <div data-b="comment" class="red">
              <p data-b="body">foo comment</p>
            </div>
          </article>
        </body>
        </html>
      HTML
    )
  end
end
