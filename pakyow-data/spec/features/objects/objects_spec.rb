RSpec.describe "data objects" do
  let :data do
    Pakyow.apps.first.data
  end

  before do
    Pakyow.after :configure do
      config.data.connections.sql[:default] = "sqlite::memory"
    end
  end

  include_context "testable app"

  context "querying for data" do
    context "when a data object is defined for the source" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          object :post do
          end

          object :comment do
          end

          source :posts do
            primary_id
            has_many :comments

            def query
              where(id: 1)
            end
          end

          source :comments do
            primary_id
          end
        end
      end

      describe "#all" do
        it "returns specific data object instances" do
          data.posts.create({})
          expect(data.posts.to_a[0]).to be_instance_of(Test::Objects::Post)
        end
      end

      describe "#one" do
        it "returns specific data object instances" do
          data.posts.create({})
          expect(data.posts.one).to be_instance_of(Test::Objects::Post)
        end
      end

      describe "#each" do
        it "yields specific data object instances" do
          data.posts.create({})
          data.posts.each do |post|
            expect(post).to be_instance_of(Test::Objects::Post)
          end
        end
      end

      describe "#by_*" do
        it "returns specific data object instances" do
          post = data.posts.create({}).one
          expect(data.posts.by_id(post[:id]).one).to be_instance_of(Test::Objects::Post)
        end
      end

      describe "#including" do
        it "returns specific data object instances" do
          post = data.posts.create({}).one
          data.comments.create(post_id: post[:id])
          expect(data.posts.including(:comments).one).to be_instance_of(Test::Objects::Post)
        end

        it "returns specific data object instances for the associated data" do
          post = data.posts.create({}).one
          data.comments.create(post_id: post[:id])
          expect(data.posts.including(:comments).one[:comments][0]).to be_instance_of(Test::Objects::Comment)
        end
      end

      describe "custom query" do
        it "returns specific data object instances" do
          data.posts.create({})
          expect(data.posts.query.to_a[0]).to be_instance_of(Test::Objects::Post)
        end
      end
    end

    context "when no data object is defined for the source" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          object :foo do
          end

          source :posts do
            primary_id
            has_many :comments

            def query
              where(id: 1)
            end
          end

          source :comments do
            primary_id
          end
        end
      end

      describe "#all" do
        it "returns general data object instances" do
          data.posts.create({})
          expect(data.posts.to_a[0]).to be_instance_of(Pakyow::Data::Object)
        end
      end

      describe "#one" do
        it "returns general data object instances" do
          data.posts.create({})
          expect(data.posts.one).to be_instance_of(Pakyow::Data::Object)
        end
      end

      describe "#each" do
        it "yields general data object instances" do
          data.posts.create({})
          data.posts.each do |post|
            expect(post).to be_instance_of(Pakyow::Data::Object)
          end
        end
      end

      describe "#by_*" do
        it "returns general data object instances" do
          post = data.posts.create({}).one
          expect(data.posts.by_id(post[:id]).one).to be_instance_of(Pakyow::Data::Object)
        end
      end

      describe "#including" do
        it "returns general data object instances" do
          post = data.posts.create({}).one
          data.comments.create(post_id: post[:id])
          expect(data.posts.including(:comments).one).to be_instance_of(Pakyow::Data::Object)
        end

        it "returns general data object instances for the associated data" do
          post = data.posts.create({}).one
          data.comments.create(post_id: post[:id])
          expect(data.posts.including(:comments).one[:comments][0]).to be_instance_of(Pakyow::Data::Object)
        end
      end

      describe "custom query" do
        it "returns general data object instances" do
          data.posts.create({})
          expect(data.posts.query.to_a[0]).to be_instance_of(Pakyow::Data::Object)
        end
      end
    end
  end

  context "creating data" do
    context "when a data object is defined for the source" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          object :post do
          end

          source :posts do
            primary_id
          end
        end
      end

      it "returns a general data object instance" do
        post = data.posts.create({}).one
        expect(post).to be_instance_of(Test::Objects::Post)
      end
    end

    context "when no data object is defined for the source" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          object :foo do
          end

          source :posts do
            primary_id
          end
        end
      end

      it "returns a general data object instance" do
        post = data.posts.create({}).one
        expect(post).to be_instance_of(Pakyow::Data::Object)
      end
    end
  end

  describe "the data object" do
    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        object :post do
          def foo
            "foo_#{values[:id]}"
          end
        end

        source :posts do
          primary_id
        end
      end
    end

    describe "a defined method" do
      it "is callable" do
        post = data.posts.create({}).one
        expect(post.foo).to eq("foo_1")
      end
    end

    describe "#values" do
      it "returns the values" do
        post = data.posts.create({}).one
        expect(post.values).to eq({ id: 1 })
      end
    end

    describe "hash-style lookup" do
      it "returns an attribute value" do
        post = data.posts.create({}).one
        expect(post[:id]).to eq(1)
        expect(post["id"]).to eq(1)
      end

      it "calls a value method" do
        post = data.posts.create({}).one
        expect(post[:foo]).to eq("foo_1")
        expect(post["foo"]).to eq("foo_1")
      end
    end

    describe "method-style lookup" do
      it "returns an attribute value" do
        post = data.posts.create({}).one
        expect(post.id).to eq(1)
      end

      it "calls a value method" do
        post = data.posts.create({}).one
        expect(post.foo).to eq("foo_1")
      end
    end

    describe "attempting to change a value" do
      it "fails" do
        post = data.posts.create({}).one
        expect { post.values[:id] = 2 }.to raise_error(RuntimeError)
      end
    end
  end
end
