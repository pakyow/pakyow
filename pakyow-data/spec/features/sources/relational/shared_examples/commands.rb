RSpec.shared_examples :source_commands do
  describe "built-in source commands" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "testable app"

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts do
          primary_id
          attribute :title, :string
        end
      end
    end

    describe "create" do
      it "creates a record" do
        data.posts.create({})
        expect(data.posts.count).to eq(1)
      end

      it "returns a single result" do
        expect(data.posts.create({}).one).to be_instance_of(Pakyow::Data::Object)
      end

      context "value is nil" do
        it "creates with the nil value" do
          expect(data.posts.create(title: nil).one).to be_instance_of(Pakyow::Data::Object)
        end
      end

      context "passing no values" do
        it "creates an empty record" do
          expect(data.posts.create.one).to be_instance_of(Pakyow::Data::Object)
        end
      end

      context "passing an unknown value" do
        it "raises an unknown attribute error" do
          expect {
            data.posts.create(foo: "bar")
          }.to raise_error(Pakyow::Data::UnknownAttribute) do |error|
            expect(error.message).to eq("Unknown attribute foo for posts")
          end
        end
      end

      context "passing the wrong type of value" do
        it "coerces the value" do
          expect(data.posts.create(title: 1).one.title).to eq("1")
        end

        context "attribute type is strict" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                primary_id
                attribute :title, Pakyow::Data::Types::Strict::String
              end
            end
          end

          it "raises a type mismatch error" do
            expect {
              data.posts.create(title: 1)
            }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
              expect(error.cause).to be_instance_of(Dry::Types::ConstraintError)
            end
          end
        end
      end

      context "called with a block" do
        it "yields the result to the block" do
          yielded = nil
          data.posts.create do |post|
            yielded = post
          end

          expect(yielded).to be_instance_of(Pakyow::Data::Proxy)
        end
      end
    end

    describe "update" do
      before do
        data.posts.create(title: "foo")
        data.posts.create(title: "bar")
        @result = data.posts.update(title: "baz").to_a
      end

      it "updates all matching records" do
        expect(data.posts.count).to eq(2)
        expect(data.posts.to_a[0][:title]).to eq("baz")
        expect(data.posts.to_a[1][:title]).to eq("baz")
      end

      it "returns the updated results" do
        expect(@result).to be_instance_of(Array)
        expect(@result.count).to eq(2)
        expect(@result[0][:title]).to eq("baz")
        expect(@result[1][:title]).to eq("baz")
      end

      context "value is nil" do
        it "updates with the nil value" do
          expect(data.posts.count).to eq(2)
          expect(data.posts.to_a[0][:title]).to eq("baz")
          expect(data.posts.to_a[1][:title]).to eq("baz")

          data.posts.update(title: nil).to_a
          expect(data.posts.to_a[0][:title]).to eq(nil)
          expect(data.posts.to_a[1][:title]).to eq(nil)
        end
      end

      context "updating without values" do
        it "does not fail" do
          expect {
            data.posts.update({})
          }.not_to raise_error
        end

        it "does not change any values" do
          expect {
            data.posts.update({})
          }.not_to change {
            data.posts.to_a.map(&:values)
          }
        end

        it "returns the results" do
          result = data.posts.update({}).to_a
          expect(result).to be_instance_of(Array)
          expect(result.count).to eq(2)
        end
      end

      context "passing no value" do
        it "does not fail" do
          expect {
            data.posts.update
          }.not_to raise_error
        end

        it "does not change any values" do
          expect {
            data.posts.update
          }.not_to change {
            data.posts.to_a.map(&:values)
          }
        end

        it "returns the results" do
          result = data.posts.update.to_a
          expect(result).to be_instance_of(Array)
          expect(result.count).to eq(2)
        end
      end

      context "passing an unknown value" do
        it "raises an unknown attribute error" do
          expect {
            data.posts.update(foo: "bar")
          }.to raise_error(Pakyow::Data::UnknownAttribute) do |error|
            expect(error.message).to eq("Unknown attribute foo for posts")
          end
        end
      end

      context "passing the wrong type of value" do
        it "coerces the value" do
          expect(data.posts.update(title: 1).one.title).to eq("1")
        end

        context "attribute type is strict" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                primary_id
                attribute :title, Pakyow::Data::Types::Strict::String
              end
            end
          end

          it "raises a type mismatch error" do
            expect {
              data.posts.update(title: 1)
            }.to raise_error(Pakyow::Data::TypeMismatch) do |error|
              expect(error.cause).to be_instance_of(Dry::Types::ConstraintError)
            end
          end
        end
      end

      context "called with a block" do
        it "yields the result to the block" do
          yielded = nil
          data.posts.update do |post|
            yielded = post
          end

          expect(yielded).to be_instance_of(Pakyow::Data::Proxy)
        end
      end
    end

    describe "delete" do
      before do
        data.posts.create(title: "foo")
        data.posts.create(title: "bar")
        @result = data.posts.delete.to_a
      end

      it "deletes all matching records" do
        expect(data.posts.count).to eq(0)
      end

      it "returns multiple results" do
        expect(@result).to be_instance_of(Array)
        expect(@result.count).to eq(2)
        expect(@result[0][:title]).to eq("foo")
        expect(@result[1][:title]).to eq("bar")
      end
    end
  end

  describe "custom source commands" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "testable app"

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts do
          primary_id
          attribute :title
          has_many :comments

          command :create_with_default_comment, performs_create: true do |values|
            command(:create).call(values) do |post|
              container.source(:comment).command(:create).call(body: "default comment", post: post.one)
            end
          end
        end

        source :comments do
          primary_id
          attribute :body
        end
      end
    end

    it "calls the command" do
      post = data.posts.create_with_default_comment(title: "foo").including(:comments).one
      expect(post.comments.length).to eq(1)
      expect(post.comments.first.body).to eq("default comment")
    end
  end
end
