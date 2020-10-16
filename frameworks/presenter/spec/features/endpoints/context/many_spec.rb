RSpec.describe "presenting a view with an endpoint that requires many levels of context" do
  include_context "app"

  context "context is defined on an object associated with the presented object" do
    let :app_def do
      Proc.new do
        resource :docs, "/docs", param: :slug do
          show

          resource :guides, "/guides", param: :slug do
            show

            resource :sections, "/sections", param: :slug do
              show
            end
          end
        end

        presenter "/presentation/endpoints/context/top-level-many" do
          render :section do
            present(guide: { slug: "bar", doc: { slug: "foo" } }, slug: "baz")
          end
        end
      end
    end

    it "sets up the endpoint with the associated object's context" do
      expect(call("/presentation/endpoints/context/top-level-many")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="section">
            <a href="/docs/foo/guides/bar/sections/baz" data-e="docs_guides_sections_show"></a>
          </div>
        HTML
      )
    end
  end
end
