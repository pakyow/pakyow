RSpec.describe "versioning via defined logic" do
  let :presenter_class do
    Class.new(Pakyow::Presenter::ViewPresenter)
  end

  let :presenter do
    presenter_class.new(view)
  end

  context "logic defined for a binding" do
    let :view do
      Pakyow::Presenter::View.new(
        <<~HTML
          <div binding="post" version="default">
            default

            <h1 binding="title"></h1>
          </div>

          <div binding="post" version="two">
            two

            <h1 binding="title"></h1>
          </div>
        HTML
      )
    end

    before do
      presenter_class.version :post do |view, post|
        view.use(post[:version])
      end
    end

    context "binding is presented" do
      it "calls the versioning logic" do
        presenter.find(:post).present(version: :two)
        expect(presenter.to_s).to include("two")
      end
    end

    context "binding is not presented" do
      it "does not call the versioning logic" do
        presenter.find(:post).bind(version: :two)
        expect(presenter.to_s).to_not include("two")
      end
    end
  end

  context "logic defined for a nested binding" do
    let :view do
      Pakyow::Presenter::View.new(
        <<~HTML
          <div binding="post">
            <div binding="comment" version="default">
              default

              <h1 binding="title"></h1>
            </div>

            <div binding="comment" version="two">
              two

              <h1 binding="title"></h1>
            </div>
          </div>
        HTML
      )
    end

    before do
      presenter_class.version :comment do |view, comment|
        view.use(comment[:version])
      end
    end

    context "binding is presented" do
      it "calls the versioning logic" do
        presenter.find(:post).present(comments: [ { version: :two } ])
        expect(presenter.to_s).to include("two")
      end
    end
  end

  context "logic defined for a channeled binding" do
    let :view do
      Pakyow::Presenter::View.new(
        <<~HTML
          <div binding="post" version="default">
            default

            <h1 binding="title"></h1>
          </div>

          <div binding="post" version="two">
            two

            <h1 binding="title"></h1>
          </div>

          <div binding="post:foo" version="default">
            channeled default

            <h1 binding="title"></h1>
          </div>

          <div binding="post:foo" version="two">
            channeled two

            <h1 binding="title"></h1>
          </div>
        HTML
      )
    end

    before do
      presenter_class.version :post, channel: :foo do |view, post|
        view.use(post[:version])
      end
    end

    context "channeled binding is presented" do
      it "calls the versioning logic" do
        presenter.find(:post, channel: :foo).present(version: :two)
        expect(presenter.to_s).to include("channeled two")
      end
    end

    context "channeled binding is not presented" do
      it "does not call the versioning logic" do
        presenter.find(:post).bind(version: :two)
        expect(presenter.to_s).to_not include("channeled two")
        expect(presenter.to_s).to_not include("two")
      end
    end
  end
end
