RSpec.describe "presenting views that define endpoints" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      resources :posts, "/posts" do
        list   do; end
        show   do; end
        remove do; end
      end
    }
  end

  let :presenter do
    Pakyow::Presenter::Presenter.new(view, endpoints: Pakyow.apps[0].endpoints, current_endpoint: current_endpoint)
  end

  let :current_endpoint do
    {}
  end

  context "anchor node defines an endpoint" do
    let :view do
      Pakyow::Presenter::View.new("<a href=\"#\" endpoint=\"posts#list\"></a>")
    end

    it "sets the href" do
      expect(presenter.to_s).to eq("<a href=\"/posts\"></a>")
    end

    context "endpoint is current" do
      let :current_endpoint do
        { path: "/posts" }
      end

      it "receives an active class" do
        expect(presenter.to_s).to eq("<a href=\"/posts\" class=\"active\"></a>")
      end
    end

    context "endpoint matches the first part of current" do
      let :current_endpoint do
        { path: "/posts/1" }
      end

      it "receives an active class" do
        expect(presenter.to_s).to eq("<a href=\"/posts\" class=\"active\"></a>")
      end
    end

    context "endpoint does not exist" do
      let :view do
        Pakyow::Presenter::View.new("<a href=\"#\" endpoint=\"posts#nonexistent\"></a>")
      end

      it "does not set the href" do
        expect(presenter.to_s).to eq("<a href=\"#\"></a>")
      end
    end

    context "endpoint node is within a binding" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">title</h1><a href=\"#\" endpoint=\"posts#list\">Back</a></div>")
      end

      it "does not set the href automatically" do
        expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">title</h1><a href=\"#\">Back</a></div>")
      end

      context "binding is bound to" do
        before do
          presenter.find(:post).present(title: "foo")
        end

        it "sets the href" do
          expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">foo</h1><a href=\"/posts\">Back</a></div>")
        end

        context "endpoint is current" do
          let :current_endpoint do
            { path: "/posts" }
          end

          it "receives an active class" do
            expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">foo</h1><a href=\"/posts\" class=\"active\">Back</a></div>")
          end
        end

        context "endpoint does not exist" do
          let :view do
            Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">title</h1><a href=\"#\" endpoint=\"posts#nonexistent\">Back</a></div>")
          end

          it "does not set the href" do
            expect(presenter.to_s).to eq("<div data-b=\"post\"><h1 data-b=\"title\">foo</h1><a href=\"#\">Back</a></div>")
          end
        end
      end
    end

    context "endpoint node is a binding prop" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"><a binding=\"title\" endpoint=\"posts#list\">title</a></div>")
      end

      it "does not set the href automatically" do
        expect(presenter.to_s).to eq("<div data-b=\"post\"><a data-b=\"title\">title</a></div>")
      end

      context "binding is bound to" do
        before do
          presenter.find(:post).present(title: "foo")
        end

        it "sets the href" do
          expect(presenter.to_s).to eq("<div data-b=\"post\"><a data-b=\"title\" href=\"/posts\">foo</a></div>")
        end

        context "endpoint is current" do
          let :current_endpoint do
            { path: "/posts" }
          end

          it "receives an active class" do
            expect(presenter.to_s).to eq("<div data-b=\"post\"><a data-b=\"title\" href=\"/posts\" class=\"active\">foo</a></div>")
          end
        end

        context "endpoint does not exist" do
          let :view do
            Pakyow::Presenter::View.new("<div binding=\"post\"><a binding=\"title\" endpoint=\"posts#nonexistent\">foo</a></div>")
          end

          it "does not set the href" do
            expect(presenter.to_s).to eq("<div data-b=\"post\"><a data-b=\"title\">foo</a></div>")
          end
        end

        context "binder exists" do
          let :post_binder do
            Pakyow::Presenter::Binder.make :post do
              def title
                object[:title].to_s.reverse
              end
            end
          end

          let :presenter do
            Pakyow::Presenter::Presenter.new(view, endpoints: Pakyow.apps[0].endpoints, current_endpoint: current_endpoint, binders: [post_binder])
          end

          it "still sets the endpoint href" do
            expect(presenter.to_s).to eq("<div data-b=\"post\"><a data-b=\"title\" href=\"/posts\">oof</a></div>")
          end

          context "binder sets the href" do
            let :post_binder do
              Pakyow::Presenter::Binder.make :post do
                def title
                  part :content do
                    object[:title].to_s.reverse
                  end

                  part :href do
                    "overridden"
                  end
                end
              end
            end

            it "overrides the endpoint href" do
              expect(presenter.to_s).to eq("<div data-b=\"post\"><a data-b=\"title\" href=\"overridden\">oof</a></div>")
            end
          end
        end
      end
    end

    context "endpoint node defines an href" do
      let :view do
        Pakyow::Presenter::View.new("<a href=\"/posts\" endpoint=\"posts#nonexistent\"></a>")
      end

      context "defined endpoint is not found, but current endpoint matches the href" do
        let :current_endpoint do
          { path: "/posts" }
        end

        it "receives an active class" do
          expect(presenter.to_s).to eq("<a href=\"/posts\" class=\"active\"></a>")
        end
      end
    end
  end

  context "anchor node defines a contextual endpoint" do
    let :view do
      Pakyow::Presenter::View.new("<a href=\"#\" endpoint=\"posts#show\"></a>")
    end

    let :current_endpoint do
      { params: { post_id: 1 } }
    end

    it "builds the action using request params as context" do
      expect(presenter.to_s).to eq("<a href=\"/posts/1\"></a>")
    end

    context "endpoint node is within a binding" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"><h1 binding=\"title\">title</h1><a href=\"#\" endpoint=\"posts#show\">View</a></div>")
      end

      before do
        presenter.find(:post).bind(id: 3, title: "foo")
      end

      it "builds the action using binding as context" do
        expect(presenter.to_s).to eq("<div data-b=\"post\" data-id=\"3\"><h1 data-b=\"title\">foo</h1><a href=\"/posts/3\">View</a></div>")
      end
    end

    context "endpoint node is a binding prop" do
      let :view do
        Pakyow::Presenter::View.new("<div binding=\"post\"><a binding=\"title\" endpoint=\"posts#show\">title</a></div>")
      end

      before do
        presenter.find(:post).bind(id: 5, title: "foo")
      end

      it "builds the action using binding as context" do
        expect(presenter.to_s).to eq("<div data-b=\"post\" data-id=\"5\"><a data-b=\"title\" href=\"/posts/5\">foo</a></div>")
      end
    end
  end

  context "an endpoint node has a child action node" do
    let :view do
      Pakyow::Presenter::View.new("<div endpoint=\"posts#list\"><a href=\"#\" endpoint-action></a></div>")
    end

    it "sets the href on the action node" do
      expect(presenter.to_s).to eq("<div><a href=\"/posts\"></a></div>")
    end

    context "endpoint is current" do
      let :current_endpoint do
        { path: "/posts" }
      end

      it "adds an active class to the endpoint node" do
        expect(presenter.to_s).to eq("<div class=\"active\"><a href=\"/posts\"></a></div>")
      end
    end
  end

  context "node defines a delete endpoint" do
    let :view do
      Pakyow::Presenter::View.new("<button endpoint=\"posts#remove\">delete</button>")
    end

    let :current_endpoint do
      { params: { post_id: 1 } }
    end

    it "wraps the node in a submittable form" do
      expect(presenter.to_s).to eq("<form action=\"/posts/1\" method=\"post\" data-ui=\"confirm\">\n  <input type=\"hidden\" name=\"_method\">\n\n  <button>delete</button>\n</form>\n")
    end
  end

  context "form node defines an endpoint" do
    context "endpoint is get" do
      it "sets the action"
      it "sets the method"
    end

    context "endpoint is post" do
      it "sets the action"
      it "sets the method"
    end

    context "endpoint is not get or post" do
      it "sets the action"
      it "sets the method"
      it "creates the method input"
    end

    context "endpoint does not exist" do
      it "does nothing"
    end

    context "endpoint node is within a binding" do
      it "does not set the href automatically"

      context "binding is bound to" do
        it "sets the href"

        context "endpoint is current" do
          it "adds an active class"
        end

        context "endpoint does not exist" do
          it "does nothing"
        end
      end
    end
  end

  context "form node defines a contextual endpoint" do
    it "builds the action using request params as context"

    context "endpoint node is within a binding" do
      it "builds the action using binding as context"
    end
  end
end
