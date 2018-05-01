RSpec.shared_examples :source_sql_raw do
  describe "accessing raw sql" do
    let :data do
      Pakyow.apps.first.data
    end

    before do
      Pakyow.config.data.connections.public_send(connection_type)[:default] = connection_string
    end

    include_context "testable app"

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

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
