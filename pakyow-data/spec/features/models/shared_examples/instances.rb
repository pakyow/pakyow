RSpec.shared_examples :model_instances do
  describe "creating instances" do
    before do
      Pakyow.config.connections.sql[:default] = "sqlite://"
    end

    include_context "testable app"

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        model :posts do
          primary_id
          has_many :comments

          queries do
            def query
              where(id: 1)
            end
          end
        end

        model :comments do
          primary_id
        end
      end
    end

    let :data do
      Pakyow.apps.first.data
    end

    describe "#all" do
      it "returns model instances" do
        data.posts.create({})
        expect(data.posts.all[0]).to be_instance_of(Test::Posts)
      end
    end

    describe "#one" do
      it "returns model instances" do
        data.posts.create({})
        expect(data.posts.one).to be_instance_of(Test::Posts)
      end
    end

    describe "#each" do
      it "yields model instances" do
        data.posts.create({})
        data.posts.each do |post|
          expect(post).to be_instance_of(Test::Posts)
        end
      end
    end

    describe "#by_*" do
      it "returns model instances" do
        post = data.posts.create({})
        expect(data.posts.by_id(post[:id]).one).to be_instance_of(Test::Posts)
      end
    end

    describe "#with_*" do
      it "returns model instances" do
        post = data.posts.create({})
        data.comments.create(post_id: post[:id])
        expect(data.posts.with_comments.first).to be_instance_of(Test::Posts)
      end

      it "returns model instances for the associated data" do
        post = data.posts.create({})
        data.comments.create(post_id: post[:id])
        expect(data.posts.with_comments.first[:comments][0]).to be_instance_of(Test::Comments)
      end
    end

    describe "#create" do
      it "returns a model instance" do
        post = data.posts.create({})
        expect(post).to be_instance_of(Test::Posts)
      end
    end

    describe "custom query" do
      it "returns model instances" do
        data.posts.create({})
        expect(data.posts.query.all[0]).to be_instance_of(Test::Posts)
      end
    end
  end

  describe "a model instance" do
    before do
      Pakyow.config.connections.sql[:default] = "sqlite://"
    end

    include_context "testable app"

    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        model :posts do
          primary_id

          def foo
            "foo_#{values[:id]}"
          end
        end
      end
    end

    let :data do
      Pakyow.apps.first.data
    end

    describe "a defined method" do
      it "is callable" do
        post = data.posts.create({})
        expect(post.foo).to eq("foo_1")
      end
    end

    describe "#values" do
      it "returns the values" do
        post = data.posts.create({})
        expect(post.values).to eq({ id: 1 })
      end
    end

    describe "hash-style lookup" do
      it "returns an attribute value" do
        post = data.posts.create({})
        expect(post[:id]).to eq(1)
        expect(post["id"]).to eq(1)
      end
    end

    describe "method-style lookup" do
      it "returns an attribute value" do
        post = data.posts.create({})
        expect(post.id).to eq(1)
      end
    end

    describe "attempting to change a value" do
      it "fails" do
        post = data.posts.create({})
        expect { post.values[:id] = 2 }.to raise_error(FrozenError)
      end
    end
  end
end
