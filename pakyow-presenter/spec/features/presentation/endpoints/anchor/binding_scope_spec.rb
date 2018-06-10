RSpec.describe "presenting a view that defines an anchor endpoint that is a binding scope" do
  include_context "testable app"

  let :app_definition do
    Proc.new {
      instance_exec(&$presenter_app_boilerplate)
    }
  end

  it "does not set the href automatically, so the unused binding is removed" do
    expect(call("/presentation/endpoints/anchor/binding_scope")[2].body.read.strip).to eq("")
  end

  context "binding is bound to" do
    let :app_definition do
      Proc.new {
        instance_exec(&$presenter_app_boilerplate)

        resources :posts, "/posts" do
          list do
            render "/presentation/endpoints/anchor/binding_scope"
          end
        end

        presenter "/presentation/endpoints/anchor/binding_scope" do
          def perform
            find(:post).present(title: "foo")
          end
        end
      }
    end

    it "sets the href" do
      expect(call("/presentation/endpoints/anchor/binding_scope")[2].body.read).to include_sans_whitespace(
        <<~HTML
          <a data-b="post" data-e="posts_list" href="/posts">Link</a>
        HTML
      )
    end

    context "endpoint is current" do
      it "receives a current class" do
        expect(call("/posts")[2].body.read).to include_sans_whitespace(
          <<~HTML
            <a data-b="post" data-e="posts_list" href="/posts" class="current">Link</a>
          HTML
        )
      end
    end
  end
end
