RSpec.shared_examples :source_sql_literal do
  describe "using sql literals" do
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

    let :app_init do
      Proc.new do
        source :posts do
          primary_id

          def query
            where(build("foo = ?", "bar"))
          end
        end
      end
    end

    it "builds the query correctly" do
      expect(data.posts.source.query.sql).to eq("SELECT * FROM `posts` WHERE (foo = 'bar')")
    end
  end
end
