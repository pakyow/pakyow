RSpec.describe "submitting valid form data via ui" do
  include_context "app"

  let :app_init do
    Proc.new do
      resource :post, "/posts" do
        disable_protection :csrf

        new do; end

        create do
          verify do
            required :post do
              required :title
            end
          end

          res.body << "created #{params[:post][:title]} #{ui?}"
        end
      end
    end
  end

  it "calls the route in a normal way" do
    call("/posts", method: :post, params: { post: { title: "foo" } }, Pakyow::UI::Helpers::UI_REQUEST_HEADER => "true").tap do |result|
      expect(result[0]).to be(200)
      expect(result[2].join).to eq("created foo true")
    end
  end
end
