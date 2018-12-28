RSpec.describe "setting up a form explicitly via presenter" do
  include_context "app"

  let :presenter do
    Pakyow.apps.first.class.const_get(:Presenter).new(view)
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

  let :endpoint do
    Pakyow::Connection::Endpoint.new("/", {})
  end

  describe "setting up the form for creating an object" do
    let :object do
      { title: "foo" }
    end

    it "does not setup the endpoint" do
      form.create(object)
      expect(presenter.to_s).to include('<form data-b="post" data-c="form">')
    end

    it "binds the values" do
      form.create(object)
      expect(form.find(:title).attrs[:value]).to eq("foo")
    end

    context "matching route is found" do
      include_context "app"

      let :app_init do
        Proc.new {
          resource :posts, "/posts" do
            create do; end
          end
        }
      end

      let :presenter do
        Pakyow.apps.first.class.const_get(:Presenter).new(view).tap do |presenter|
          presenter.install_endpoints(Pakyow.apps[0].endpoints, current_endpoint: endpoint)
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
    it "does not setup the endpoint" do
      form.create
      expect(presenter.to_s).to include('<form data-b="post" data-c="form">')
    end

    context "matching route is found" do
      include_context "app"

      let :app_init do
        Proc.new {
          resource :posts, "/posts" do
            create do; end
          end
        }
      end

      let :presenter do
        Pakyow.apps.first.class.const_get(:Presenter).new(view).tap do |presenter|
          presenter.install_endpoints(Pakyow.apps[0].endpoints, current_endpoint: endpoint)
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

    it "does not setup the endpoint" do
      form.update(object)
      expect(presenter.to_s).to include('<form data-b="post" data-c="form" data-id="1">')
    end

    it "binds the values" do
      form.update(object)
      expect(form.find(:title).attrs[:value]).to eq("bar")
    end

    context "matching route is found" do
      include_context "app"

      let :app_init do
        Proc.new {
          resource :posts, "/posts" do
            update do; end
          end
        }
      end

      let :presenter do
        Pakyow.apps.first.class.const_get(:Presenter).new(view).tap do |presenter|
          presenter.install_endpoints(Pakyow.apps[0].endpoints, current_endpoint: endpoint)
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

    it "does not setup the endpoint" do
      form.replace(object)
      expect(presenter.to_s).to include('<form data-b="post" data-c="form" data-id="1">')
    end

    it "binds the values" do
      form.replace(object)
      expect(form.find(:title).attrs[:value]).to eq("bar")
    end

    context "matching route is found" do
      include_context "app"

      let :app_init do
        Proc.new {
          resource :posts, "/posts" do
            replace do; end
          end
        }
      end

      let :presenter do
        Pakyow.apps.first.class.const_get(:Presenter).new(view).tap do |presenter|
          presenter.install_endpoints(Pakyow.apps[0].endpoints, current_endpoint: endpoint)
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

    it "does not setup the endpoint" do
      form.delete(object)
      expect(presenter.to_s).to include('<form data-b="post" data-c="form" data-id="1">')
    end

    it "binds the values" do
      form.delete(object)
      expect(form.find(:title).attrs[:value]).to eq("bar")
    end

    context "matching route is found" do
      include_context "app"

      let :app_init do
        Proc.new {
          resource :posts, "/posts" do
            delete do; end
          end
        }
      end

      let :presenter do
        Pakyow.apps.first.class.const_get(:Presenter).new(view).tap do |presenter|
          presenter.install_endpoints(Pakyow.apps[0].endpoints, current_endpoint: endpoint)
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

  describe "setting up the form multiple times" do
    let :object do
      { title: "foo" }
    end

    context "matching route is found" do
      include_context "app"

      let :app_init do
        Proc.new {
          resource :posts, "/posts" do
            create do; end
            update do; end
            delete do; end
          end
        }
      end

      let :presenter do
        Pakyow.apps.first.class.const_get(:Presenter).new(view).tap do |presenter|
          presenter.install_endpoints(Pakyow.apps[0].endpoints, current_endpoint: endpoint)
        end
      end

      before do
        form.create(object)
        form.update(object)
        form.delete(object)
      end

      it "sets the form action" do
        expect(form.attrs[:action]).to eq("/posts")
      end

      it "reuses the method override" do
        expect(presenter.to_s).to include('<input type="hidden" name="_method" value="delete">')
        expect(presenter.to_s).to_not include('<input type="hidden" name="_method" value="patch">')
      end
    end
  end
end
