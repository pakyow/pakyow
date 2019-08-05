RSpec.describe "presenting a view with an endpoint that requires context" do
  include_context "app"

  let :app_def do
    Proc.new do
      resource :guides, "/guides", param: :slug do
        show

        resource :sections, "/sections", param: :slug do
          show
        end
      end
    end
  end

  context "context is defined on the presented object" do
    let :app_init do
      Proc.new do
        presenter "/presentation/endpoints/context/top-level" do
          render :section do
            present(guide_slug: "foo", slug: "bar")
          end
        end
      end
    end

    it "sets up the endpoint with the presented object's context" do
      expect(call("/presentation/endpoints/context/top-level")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="section">
            <a href="/guides/foo/sections/bar" data-e="guides_sections_show"></a>
          </div>
        HTML
      )
    end

    context "context is also defined on a parent scope" do
      let :app_init do
        Proc.new do
          presenter "/presentation/endpoints/context/nested" do
            render :guide do
              present(slug: "baz", section: { slug: "bar", guide_slug: "foo" })
            end
          end
        end
      end

      it "sets up the endpoint with the presented object's context" do
        expect(call("/presentation/endpoints/context/nested")[2]).to include_sans_whitespace(
          <<~HTML
            <div data-b="guide">
              <div data-b="section">
                <a href="/guides/foo/sections/bar" data-e="guides_sections_show"></a>
              </div>
          HTML
        )
      end
    end

    context "context is also defined on the current url" do
      let :app_def do
        Proc.new do
          resource :guides, "/guides", param: :slug do
            show do
              render "/presentation/endpoints/context/top-level"
            end

            resource :sections, "/sections", param: :slug do
              show
            end
          end
        end
      end

      let :app_init do
        Proc.new do
          presenter "/presentation/endpoints/context/top-level" do
            render :section do
              present(slug: "bar", guide_slug: "foo")
            end
          end
        end
      end

      it "sets up the endpoint with the presented object's context" do
        expect(call("/guides/baz")[2]).to include_sans_whitespace(
          <<~HTML
            <div data-b="section">
              <a href="/guides/foo/sections/bar" data-e="guides_sections_show"></a>
            </div>
          HTML
        )
      end
    end
  end

  context "context is defined on an object associated with the presented object" do
    let :app_init do
      Proc.new do
        presenter "/presentation/endpoints/context/top-level" do
          render :section do
            present(guide: { slug: "foo" }, slug: "bar")
          end
        end
      end
    end

    it "sets up the endpoint with the associated object's context" do
      expect(call("/presentation/endpoints/context/top-level")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="section">
            <a href="/guides/foo/sections/bar" data-e="guides_sections_show"></a>
          </div>
        HTML
      )
    end

    context "context is also defined on a parent scope" do
      let :app_init do
        Proc.new do
          presenter "/presentation/endpoints/context/nested" do
            render :guide do
              present(slug: "baz", section: { slug: "bar", guide: { slug: "foo" } })
            end
          end
        end
      end

      it "sets up the endpoint with the presented object's context" do
        expect(call("/presentation/endpoints/context/nested")[2]).to include_sans_whitespace(
          <<~HTML
            <div data-b="guide">
              <div data-b="section">
                <a href="/guides/foo/sections/bar" data-e="guides_sections_show"></a>
              </div>
          HTML
        )
      end
    end

    context "context is also defined on the current url" do
      let :app_def do
        Proc.new do
          resource :guides, "/guides", param: :slug do
            show do
              render "/presentation/endpoints/context/top-level"
            end

            resource :sections, "/sections", param: :slug do
              show
            end
          end
        end
      end

      let :app_init do
        Proc.new do
          presenter "/presentation/endpoints/context/top-level" do
            render :section do
              present(slug: "bar", guide: { slug: "foo" })
            end
          end
        end
      end

      it "sets up the endpoint with the presented object's context" do
        expect(call("/guides/baz")[2]).to include_sans_whitespace(
          <<~HTML
            <div data-b="section">
              <a href="/guides/foo/sections/bar" data-e="guides_sections_show"></a>
            </div>
          HTML
        )
      end
    end
  end

  context "context is defined on a parent scope" do
    let :app_init do
      Proc.new do
        presenter "/presentation/endpoints/context/nested" do
          render :guide do
            present(slug: "foo", section: { slug: "bar" })
          end
        end
      end
    end

    it "sets up the endpoint with context from the the parent scope" do
      expect(call("/presentation/endpoints/context/nested")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="guide">
            <div data-b="section">
              <a href="/guides/foo/sections/bar" data-e="guides_sections_show"></a>
            </div>
        HTML
      )
    end
  end

  context "context is defined on the current url" do
    let :app_def do
      Proc.new do
        resource :guides, "/guides", param: :slug do
          show do
            render "/presentation/endpoints/context/top-level"
          end

          resource :sections, "/sections", param: :slug do
            show
          end
        end
      end
    end

    let :app_init do
      Proc.new do
        presenter "/presentation/endpoints/context/top-level" do
          render :section do
            present(slug: "bar")
          end
        end
      end
    end

    it "sets up the endpoint with context from the current url" do
      expect(call("/guides/foo")[2]).to include_sans_whitespace(
        <<~HTML
          <div data-b="section">
            <a href="/guides/foo/sections/bar" data-e="guides_sections_show"></a>
          </div>
        HTML
      )
    end
  end
end
