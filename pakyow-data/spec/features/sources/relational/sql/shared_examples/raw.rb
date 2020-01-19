RSpec.shared_examples :source_sql_raw do
  describe "accessing raw sql" do
    let :data do
      Pakyow.apps.first.data
    end

    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after "configure" do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "app"

    let :app_def do
      Proc.new do
        source :posts do
          primary_id
        end
      end
    end

    it "exposes the raw sql" do
      expect(data.posts.source.sql).to include("SELECT * FROM")
      expect(data.posts.source.sql).to include("posts")
    end
  end
end
