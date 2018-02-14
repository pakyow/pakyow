RSpec.describe "presenting a view that defines an anchor endpoint with an existing href" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)

      resources :posts, "/posts" do
        list do
          render "/presentation/endpoints/anchor/existing_href"
        end
      end
    }
  end

  context "defined endpoint is not found, but current endpoint matches the href" do
    it "receives an active class" do
      expect(call("/posts")[2].body.read).to include_sans_whitespace(
        <<~HTML
          <a href="/posts" class="active"></a>
        HTML
      )
    end
  end
end
