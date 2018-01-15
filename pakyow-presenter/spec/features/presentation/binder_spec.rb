RSpec.describe "binding data via presenter, with a binder" do
  let :post_binder do
    Pakyow::Presenter::Binder.make :post do
      def title
        object[:title].to_s.reverse
      end
    end
  end

  let :comment_binder do
    Pakyow::Presenter::Binder.make :comment do
      def body
        "comment: #{object[:body]}"
      end
    end
  end

  let :presenter do
    Pakyow::Presenter::Presenter.new(view, embed_templates: false, binders: [post_binder, comment_binder])
  end

  let :view do
    Pakyow::Presenter::View.new("<div@post><h1@title>title goes here</h1><p@body>body goes here</p></div>")
  end

  let :post_presenter do
    presenter.find(:post)
  end

  it "uses the binder, falling back to the object when binder does not support a value" do
    post_presenter.present(title: "foo", body: "bar")
    expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">oof</h1><p data-p=\"body\">bar</p></div>")
  end

  context "binder defines parts" do
    let :post_binder do
      Pakyow::Presenter::Binder.make :post do
        def title
          part :content do
            object[:title].to_s.reverse
          end

          part :style do
            { color: "red" }
          end
        end
      end
    end

    it "binds each part" do
      post_presenter.present(title: "foo", body: "bar")
      expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\" style=\"color:red\">oof</h1><p data-p=\"body\">bar</p></div>")
    end

    context "view includes parts" do
      let :post_binder do
        Pakyow::Presenter::Binder.make :post do
          def title
            part :content do
              object[:title].to_s.reverse
            end

            part :style do
              { color: "red" }
            end

            part :title do
              "title is: #{object[:title]}"
            end
          end
        end
      end

      let :view do
        Pakyow::Presenter::View.new("<div@post><h1@title include=\"content title\">title goes here</h1><p@body>body goes here</p></div>")
      end

      it "binds only the included parts" do
        post_presenter.present(title: "foo", body: "bar")
        expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\" title=\"title is: foo\">oof</h1><p data-p=\"body\">bar</p></div>")
      end
    end

    context "view excludes parts" do
      let :post_binder do
        Pakyow::Presenter::Binder.make :post do
          def title
            part :content do
              object[:title].to_s.reverse
            end

            part :style do
              { color: "red" }
            end

            part :title do
              "title is: #{object[:title]}"
            end
          end
        end
      end

      let :view do
        Pakyow::Presenter::View.new("<div@post><h1@title exclude=\"title\">title goes here</h1><p@body>body goes here</p></div>")
      end

      it "binds only the non-excluded parts" do
        post_presenter.present(title: "foo", body: "bar")
        expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\" style=\"color:red\">oof</h1><p data-p=\"body\">bar</p></div>")
      end
    end

    context "binder defines parts, but not content" do
      let :post_binder do
        Pakyow::Presenter::Binder.make :post do
          def title
            part :style do
              { color: "red" }
            end
          end
        end
      end

      it "binds the defined parts, pulling content from object" do
        post_presenter.present(title: "foo", body: "bar")
        expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\" style=\"color:red\">foo</h1><p data-p=\"body\">bar</p></div>")
      end
    end
  end

  context "nested data has a binder" do
    let :view do
      Pakyow::Presenter::View.new("<div@post><h1@title>title goes here</h1><div@comment><p@body>comment body goes here</p></div>")
    end

    it "uses the binder" do
      post_presenter.present(title: "post", comment: { body: "comment" })
      expect(presenter.to_s).to eq("<div data-s=\"post\"><h1 data-p=\"title\">tsop</h1><div data-s=\"comment\"><p data-p=\"body\">comment: comment</p></div></div>")
    end
  end
end
