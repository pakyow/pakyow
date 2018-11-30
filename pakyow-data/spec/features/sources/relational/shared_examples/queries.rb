RSpec.shared_examples :source_queries do
  describe "built-in source queries" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "testable app"

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

    it "responds to `all`" do
      expect(data.posts.all).to be_instance_of(Pakyow::Data::Proxy)
    end

    describe "by_attribute queries" do
      it "defines a query for each attribute" do
        post = data.posts.create(title: "foo")
        expect(data.posts.by_id(1).count).to eq(1)
        expect(data.posts.by_title("foo").count).to eq(1)
        expect(data.posts.by_title("bar").count).to eq(0)
      end
    end
  end

  describe "custom source queries" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "testable app"

    let :data do
      Pakyow.apps.first.data
    end

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts do
          primary_id
          attribute :title, :string

          def title_is_foo
            where(title: "foo")
          end

          def only_id
            select(:id)
          end
        end
      end
    end

    it "exposes the query" do
      post = data.posts.create(title: "foo")
      post = data.posts.create(title: "bar")
      expect(data.posts.title_is_foo.count).to eq(1)
    end

    it "has access to dataset methods that conflict with enumerable methods" do
      data.posts.create(title: "foo")
      expect(data.posts.only_id.one.values.keys).to eq([:id])
    end

    describe "queries that include associated data" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id

            has_many :comments

            def including_comments
              including(:comments)
            end
          end

          source :comments do
            primary_id
          end
        end
      end

      it "returns the results" do
        data.posts.create(comments: data.comments.create({}))
        expect(data.posts.including_comments.one.comments.first).to be_instance_of(Pakyow::Data::Object)
      end
    end
  end

  describe "calling dataset methods externally" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "testable app"

    let :data do
      Pakyow.apps.first.data
    end

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts do
          primary_id
        end
      end
    end

    it "does not allow them to be called" do
      expect {
        data.posts.order
      }.to raise_error
    end
  end
end
