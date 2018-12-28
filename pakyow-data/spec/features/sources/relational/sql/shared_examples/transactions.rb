RSpec.shared_examples :source_sql_transactions do
  describe "using source transactions for sql adapters" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "app"

    let :data do
      Pakyow.apps.first.data
    end

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts do
          primary_id
          attribute :title, :string
        end
      end
    end

    describe "using a transaction" do
      it "wraps queries in a transaction" do
        expect(data.posts.source.class.container.connection.adapter.connection).to receive(:transaction)

        data.posts.transaction do
          data.posts.create(title: "foo")
          data.posts.create(title: "bar")
          data.posts.create(title: "baz")
        end
      end

      it "executes the transaction" do
        expect(data.posts.count).to eq(0)

        data.posts.transaction do
          data.posts.create(title: "foo")
          data.posts.create(title: "bar")
          data.posts.create(title: "baz")
        end

        expect(data.posts.count).to eq(3)
      end
    end

    describe "rolling back a transaction" do
      context "exception occurs" do
        it "rolls back" do
          expect(data.posts.count).to eq(0)

          begin
            data.posts.transaction do
              data.posts.create(title: "foo")
              raise
              data.posts.create(title: "bar")
              data.posts.create(title: "baz")
            end
          rescue RuntimeError
          end

          expect(data.posts.count).to eq(0)
        end

        it "reraises" do
          expect {
            data.posts.transaction do
              raise
            end
          }.to raise_error(RuntimeError)
        end
      end

      context "rollback occurs" do
        it "rolls back" do
          expect(data.posts.count).to eq(0)

          data.posts.transaction do
            data.posts.create(title: "foo")
            raise Pakyow::Data::Rollback
            data.posts.create(title: "bar")
            data.posts.create(title: "baz")
          end

          expect(data.posts.count).to eq(0)
        end

        it "does not reraise" do
          expect {
            data.posts.transaction do
              raise Pakyow::Data::Rollback
            end
          }.not_to raise_error
        end
      end
    end
  end
end
