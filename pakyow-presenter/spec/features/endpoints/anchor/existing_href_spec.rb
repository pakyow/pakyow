RSpec.describe "presenting a view that defines an anchor endpoint with an existing href" do
  include_context "app"

  context "defined endpoint is not found, but current endpoint matches the href" do
    let :app_init do
      Proc.new do
        resource :posts, "/posts" do
          list do
            render "/presentation/endpoints/anchor/existing_href"
          end
        end
      end
    end

    it "does not receive a current class" do
      expect(call("/posts")[2]).to include_sans_whitespace(
        <<~HTML
          <a href="/posts" data-e="posts_nonexistent"></a>
        HTML
      )
    end

    context "prototype mode" do
      let :mode do
        :prototype
      end

      it "receives a current class" do
        expect(call("/presentation/endpoints/anchor/existing_href/prototype")[2]).to include_sans_whitespace(
          <<~HTML
            <a href="/presentation/endpoints/anchor/existing_href/prototype" data-e="posts_nonexistent" class="ui-current"></a>
          HTML
        )
      end
    end
  end

  context "anchor does not define an endpoint, but current endpoint matches the href" do
    let :app_init do
      Proc.new do
        resource :posts, "/posts" do
          list do
            render "/presentation/endpoints/anchor/existing_href/sans_endpoint"
          end
        end
      end
    end

    it "does not receive a current class" do
      expect(call("/posts")[2]).to include_sans_whitespace(
        <<~HTML
          <a href="/posts"></a>
        HTML
      )
    end

    context "prototype mode" do
      let :mode do
        :prototype
      end

      it "does not receive a current class" do
        expect(call("/presentation/endpoints/anchor/existing_href/sans_endpoint/prototype")[2]).to include_sans_whitespace(
          <<~HTML
            <a href="/presentation/endpoints/anchor/existing_href/sans_endpoint/prototype"></a>
          HTML
        )
      end
    end
  end
end
