RSpec.describe "automatic form setup" do
  include_context "testable app"

  context "rendering a form for creating" do
    context "object is exposed for the form" do
      let :app_definition do
        Proc.new {
          instance_exec(&$forms_app_boilerplate)

          resources :posts, "/posts" do
            new do
              expose "post:form", { title: "foo" }
              render "/form"
            end

            create do
            end
          end
        }
      end

      it "sets up the form" do
        expect_any_instance_of(
          Pakyow::Forms::FormPresenter
        ).to receive(:create).with(title: "foo")

        response = call("/posts/new")
        expect(response[0]).to eq(200)
      end
    end

    context "no object is exposed for the form" do
      let :app_definition do
        Proc.new {
          instance_exec(&$forms_app_boilerplate)

          resources :posts, "/posts" do
            new do
              render "/form"
            end

            create do
            end
          end
        }
      end

      it "sets up the form" do
        expect_any_instance_of(
          Pakyow::Forms::FormPresenter
        ).to receive(:create)

        response = call("/posts/new")
        expect(response[0]).to eq(200)
      end
    end
  end

  context "rendering a form for updating" do
    context "object is provided" do
      let :app_definition do
        Proc.new {
          instance_exec(&$forms_app_boilerplate)

          resources :posts, "/posts" do
            edit do
              expose "post:form", { id: params[:id], title: "foo" }
              render "/form"
            end

            update do
            end
          end
        }
      end

      it "sets up the form" do
        expect_any_instance_of(
          Pakyow::Forms::FormPresenter
        ).to receive(:update).with(id: "1", title: "foo")

        response = call("/posts/1/edit")
        expect(response[0]).to eq(200)
      end
    end

    context "no object is provided" do
      let :app_definition do
        Proc.new {
          instance_exec(&$forms_app_boilerplate)

          resources :posts, "/posts" do
            edit do
              render "/form"
            end

            update do
            end
          end
        }
      end

      it "does not set up the form" do
        expect_any_instance_of(
          Pakyow::Forms::FormPresenter
        ).not_to receive(:update)

        response = call("/posts/1/edit")
        expect(response[0]).to eq(200)
      end
    end
  end
end
