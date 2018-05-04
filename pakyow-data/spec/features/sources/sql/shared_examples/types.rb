RSpec.shared_examples :source_sql_types do
  describe "sql-specific types" do
    let :data do
      Pakyow.apps.first.data
    end

    before do
      Pakyow.config.data.connections.public_send(connection_type)[:default] = connection_string
    end

    include_context "testable app"

    context "type is text" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            attribute :attr, :text
          end
        end
      end

      it "defines the attribute" do
        string = str = "0" * 1000
        expect(data.posts.create(attr: string).one[:attr]).to eq(string)
      end
    end

    context "type is file" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            attribute :attr, :file
          end
        end
      end

      it "defines the attribute" do
        random_bytes = Random.new.bytes(10)
        expect(data.posts.create(attr: random_bytes).one[:attr]).to eq(random_bytes)
      end
    end
  end
end
