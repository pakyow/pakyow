RSpec.shared_examples :source_limiting do
  describe "limiting datasets" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after "configure" do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "app"

    let :app_init do
      Proc.new do
        source :posts do
        end
      end
    end

    before do
      data.posts.create
      data.posts.create
      data.posts.create
    end

    it "limits" do
      expect(data.posts.limit(2).count).to eq(2)
    end

    it "limits with non-integer values" do
      expect(data.posts.limit("1").count).to eq(1)
    end
  end
end
