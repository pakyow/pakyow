RSpec.describe "presenting form errors" do
  include_context "testable app"

  xcontext "rendering a form for creating" do
    context "form contains an error binding" do
      context "errors do not exist" do
        let :app_definition do
          Proc.new {
            instance_exec(&$forms_app_boilerplate)

            resources :posts, "/posts" do
              new do
                render "/form/with-errors"
              end

              create do
              end
            end
          }
        end

        it "removes the error view" do
          response = call("/posts/new")
          expect(response[0]).to eq(200)

          doc = Oga.parse_xml(response[2].body.read)
          doc.css("script").remove
          expect(doc.at_css("form").at_css(".errors")).to be(nil)
        end
      end

      context "errors exist" do
        let :app_definition do
          Proc.new {
            instance_exec(&$forms_app_boilerplate)

            resources :posts, "/posts" do
              disable_protection :csrf

              new do
              end

              create do
                handle Pakyow::InvalidData, as: :bad_request do
                  render "/form/with-errors"
                end

                verify do
                  required :post do
                    required :title
                  end
                end
              end
            end
          }
        end

        it "presents the errors" do
          response = call("/posts", method: :post, params: { post: {} })
          expect(response[0]).to eq(400)
          fail "hook this up"
        end
      end
    end

    context "form does not contain an error binding" do
      it "renders the form without errors"
    end
  end

  context "rendering a form for updating" do
    it "needs definition"
  end
end
