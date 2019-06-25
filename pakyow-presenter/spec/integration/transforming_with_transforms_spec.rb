require "pakyow/support/deep_freeze"

RSpec.describe "transforming a presenter that has future transforms" do
  using Pakyow::Support::DeepFreeze

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
    Class.new(Pakyow::Presenter::Presenter) do
      render :post do
        present(
          [
            { title: "foo" },
            { title: "bar" },
            { title: "baz" }
          ]
        )
      end

      render :post do
        attributes[:class] << :red
      end
    end
  end

  let :app do
    Class.new(Pakyow::App) {
      isolate(Pakyow::Presenter::Binder)
    }.new(:test)
  end

  before do
    Pakyow.send(:init_global_logger)
  end

  it "applies the future transforms to each node" do
    expect(presenter.to_html).to eq_sans_whitespace(
      <<~HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="utf-8">
        </head>

        <body>
          <article data-b="post" class="red">
            <h1 data-b="title">foo</h1>
          </article>

          <article data-b="post" class="red">
            <h1 data-b="title">bar</h1>
          </article>

          <article data-b="post" class="red">
            <h1 data-b="title">baz</h1>
          </article>
        </body>
        </html>
      HTML
    )
  end

  context "transform conditionally operates on the node" do
    let :presenter_class do
      Class.new(Pakyow::Presenter::Presenter) do
        render :post do
          present(
            [
              { title: "foo" },
              { title: "bar" },
              { title: "baz" }
            ]
          )
        end

        render :post do
          if find(:title).text == "bar"
            attributes[:class] << :red
          end
        end
      end
    end

    it "does not change future nodes" do
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
            </article>

            <article data-b="post" class="red">
              <h1 data-b="title">bar</h1>
            </article>

            <article data-b="post">
              <h1 data-b="title">baz</h1>
            </article>
          </body>
          </html>
        HTML
      )
    end
  end
end
