RSpec.shared_examples :source_default_fields do
  before do
    local_connection_type, local_connection_string = connection_type, connection_string

    Pakyow.after :configure do
      config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
    end
  end

  include_context "app"

  describe "default fields" do
    let :app_init do
      Proc.new do
        source :posts do
        end
      end
    end

    it "adds a primary id" do
      expect(data.posts.source.class.attributes.keys).to include(:id)
    end

    it "adds timestamps" do
      expect(data.posts.source.class.attributes.keys).to include(:created_at)
      expect(data.posts.source.class.attributes.keys).to include(:updated_at)
    end
  end

  describe "skipping default primary id" do
    let :app_init do
      Proc.new do
        source :posts, primary_id: false do
        end
      end
    end

    it "does not add a primary id" do
      expect(data.posts.source.class.attributes.keys).not_to include(:id)
    end
  end

  describe "skipping timestamps" do
    let :app_init do
      Proc.new do
        source :posts, timestamps: false do
        end
      end
    end

    it "does not add timestamps" do
      expect(data.posts.source.class.attributes.keys).not_to include(:created_at)
      expect(data.posts.source.class.attributes.keys).not_to include(:updated_at)
    end
  end
end
