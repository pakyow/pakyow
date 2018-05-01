RSpec.shared_examples :source_sql_table do
  describe "the table name used for the dataset" do
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
          attribute :title
        end
      end
    end

    it "defaults to the source name" do
      expect(data.posts.source.class.dataset_table).to eq(:posts)

      expect {
        data.posts.create(title: "foo")
      }.to_not raise_error

      expect(data.posts.one.title).to eq("foo")
    end

    context "table is set explicitly" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            table :foo

            primary_id
            attribute :title
          end
        end
      end

      it "uses to the explicitly set name" do
        expect(data.posts.source.class.dataset_table).to eq(:foo)

        expect {
          data.posts.create(title: "foo")
        }.to_not raise_error

        expect(data.posts.one.title).to eq("foo")
      end
    end
  end
end
