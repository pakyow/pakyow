RSpec.describe "reflected graph: nested scope contains an endpoint with broader context" do
  include_context "reflectable app"
  include_context "mirror"

  let :frontend_test_case do
    "state/nested_scope_contains_endpoint_with_broader_context"
  end

  let :reflected_app_def do
    Proc.new do
      resource :guides, "/guides", param: :slug do
        resource :sections, "/sections", param: :slug do
          show
        end
      end

      source :sections do
        attribute :slug
      end
    end
  end

  context "scope is related to the broader endpoint object" do
    let :existing_app_def do
      Proc.new do
        source :guides do
          has_many :sections
          attribute :slug
        end
      end
    end

    it "includes the related scope" do
      section_exposure = mirror.endpoints[0].exposures[0].children[0]
      expect(section_exposure.binding).to eq(:section)
      expect(section_exposure.children).to_not be_empty
      expect(section_exposure.children[0].scope.name).to be(:guide)
    end
  end

  context "scope is unrelated to the broader endpoint object" do
    let :existing_app_def do
      Proc.new do
        source :guides do
          attribute :slug
        end
      end
    end

    it "does not try to include the related scope" do
      section_exposure = mirror.endpoints[0].exposures[0].children[0]
      expect(section_exposure.binding).to eq(:section)
      expect(section_exposure.children).to be_empty
    end
  end
end
