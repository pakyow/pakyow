RSpec.describe "setting up a form via presenter" do
  let :presenter do
    Pakyow::Presenter::Presenter.new(view)
  end

  let :view do
    Pakyow::Presenter::View.new(
      <<~HTML
        <form binding=\"post\">
          <input binding=\"title\" type="text">
        </form>
      HTML
    )
  end

  let :form do
    presenter.form(:post)
  end

  describe "setting up the form for creating an object" do
    let :object do
      { title: "foo" }
    end

    it "sets the form method" do
      form.create(object)
      expect(form.attrs[:method]).to eq("post")
    end

    it "binds the values" do
      form.create(object)
      expect(form.find(:title).attrs[:value]).to eq("foo")
    end

    it "does not create the method override field" do
      form.create(object)
      expect(presenter.to_s).not_to include("<input type=\"hidden\" name=\"_method\"")
    end

    context "matching route is found" do
      include_context "testable app"

      let :app_definition do
        Proc.new {
          resources :posts, "/posts" do
            create do; end
          end
        }
      end

      let :presenter do
        Pakyow::Presenter::Presenter.new(view).tap do |presenter|
          presenter.install_endpoints(Pakyow.apps[0].endpoints)
        end
      end

      it "sets the form action" do
        form.create(object)
        expect(form.attrs[:action]).to eq("/posts")
      end
    end

    context "matching route is not found" do
      it "does not set the form action" do
        form.create(object)
        expect(form.attrs[:action]).to be_empty
      end
    end

    context "block is given" do
      it "yields form to the block" do
        expect { |b| form.create(object, &b) }.to yield_with_args(form)
      end
    end
  end

  describe "setting up the form for creating, without an object" do
    it "sets the form method" do
      form.create
      expect(form.attrs[:method]).to eq("post")
    end

    it "does not create the method override field" do
      form.create
      expect(presenter.to_s).not_to include("<input type=\"hidden\" name=\"_method\"")
    end

    context "matching route is found" do
      include_context "testable app"

      let :app_definition do
        Proc.new {
          resources :posts, "/posts" do
            create do; end
          end
        }
      end

      let :presenter do
        Pakyow::Presenter::Presenter.new(view).tap do |presenter|
          presenter.install_endpoints(Pakyow.apps[0].endpoints)
        end
      end

      it "sets the form action" do
        form.create
        expect(form.attrs[:action]).to eq("/posts")
      end
    end

    context "matching route is not found" do
      it "does not set the form action" do
        form.create
        expect(form.attrs[:action]).to be_empty
      end
    end

    context "block is given" do
      it "yields form to the block" do
        expect { |b| form.create(&b) }.to yield_with_args(form)
      end
    end
  end

  describe "setting up the form for updating an object" do
    let :object do
      { id: 1, title: "bar" }
    end

    it "sets the form method" do
      form.update(object)
      expect(form.attrs[:method]).to eq("post")
    end

    it "creates the method override field" do
      form.update(object)
      expect(presenter.to_s).to include("<input type=\"hidden\" name=\"_method\" value=\"patch\">")
    end

    it "binds the values" do
      form.update(object)
      expect(form.find(:title).attrs[:value]).to eq("bar")
    end

    context "matching route is found" do
      include_context "testable app"

      let :app_definition do
        Proc.new {
          resources :posts, "/posts" do
            update do; end
          end
        }
      end

      let :presenter do
        Pakyow::Presenter::Presenter.new(view).tap do |presenter|
          presenter.install_endpoints(Pakyow.apps[0].endpoints)
        end
      end

      it "sets the form action" do
        form.update(object)
        expect(form.attrs[:action]).to eq("/posts/1")
      end
    end

    context "matching route is not found" do
      it "does not set the form action" do
        form.create(object)
        expect(form.attrs[:action]).to be_empty
      end
    end

    context "block is given" do
      it "yields form to the block" do
        expect { |b| form.update(object, &b) }.to yield_with_args(form)
      end
    end
  end

  describe "setting up the form for replacing an object" do
    let :object do
      { id: 1, title: "bar" }
    end

    it "sets the form method" do
      form.replace(object)
      expect(form.attrs[:method]).to eq("post")
    end

    it "creates the method override field" do
      form.replace(object)
      expect(presenter.to_s).to include("<input type=\"hidden\" name=\"_method\" value=\"put\">")
    end

    it "binds the values" do
      form.replace(object)
      expect(form.find(:title).attrs[:value]).to eq("bar")
    end

    context "matching route is found" do
      include_context "testable app"

      let :app_definition do
        Proc.new {
          resources :posts, "/posts" do
            replace do; end
          end
        }
      end

      let :presenter do
        Pakyow::Presenter::Presenter.new(view).tap do |presenter|
          presenter.install_endpoints(Pakyow.apps[0].endpoints)
        end
      end

      it "sets the form action" do
        form.replace(object)
        expect(form.attrs[:action]).to eq("/posts/1")
      end
    end

    context "matching route is not found" do
      it "does not set the form action" do
        form.create(object)
        expect(form.attrs[:action]).to be_empty
      end
    end

    context "block is given" do
      it "yields form to the block" do
        expect { |b| form.replace(object, &b) }.to yield_with_args(form)
      end
    end
  end

  describe "setting up the form for deleting an object" do
    let :object do
      { id: 1, title: "bar" }
    end

    it "sets the form method" do
      form.delete(object)
      expect(form.attrs[:method]).to eq("post")
    end

    it "creates the method override field" do
      form.delete(object)
      expect(presenter.to_s).to include("<input type=\"hidden\" name=\"_method\" value=\"delete\">")
    end

    it "binds the values" do
      form.delete(object)
      expect(form.find(:title).attrs[:value]).to eq("bar")
    end

    context "matching route is found" do
      include_context "testable app"

      let :app_definition do
        Proc.new {
          resources :posts, "/posts" do
            delete do; end
          end
        }
      end

      let :presenter do
        Pakyow::Presenter::Presenter.new(view).tap do |presenter|
          presenter.install_endpoints(Pakyow.apps[0].endpoints)
        end
      end

      it "sets the form action" do
        form.delete(object)
        expect(form.attrs[:action]).to eq("/posts/1")
      end
    end

    context "matching route is not found" do
      it "does not set the form action" do
        form.create(object)
        expect(form.attrs[:action]).to be_empty
      end
    end

    context "block is given" do
      it "yields form to the block" do
        expect { |b| form.delete(object, &b) }.to yield_with_args(form)
      end
    end
  end
end
