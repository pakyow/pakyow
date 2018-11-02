require_relative "./dependent"

RSpec.shared_examples :source_associations_has_many do
  describe "has_many" do
    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts do
          primary_id
          has_many :comments
        end

        source :comments do
          primary_id
        end
      end
    end

    it "creates a has_many relationship" do
      post = data.posts.create({}).one
      data.comments.create(post: post)
      expect(data.posts.including(:comments).one[:comments].count).to eq(1)
    end

    it "allows the result to be fetched multiple times" do
      post = data.posts.create({}).one
      data.comments.create(post: post)
      result = data.comments.including(:post)
      expect(result.one[:post][:id]).to eq(1)
      expect(result.to_a[0][:post][:id]).to eq(1)
    end

    it "creates a belongs_to relationship on the associated source" do
      post = data.posts.create({}).one
      data.comments.create(post: post)
      expect(data.comments.including(:post).one[:post][:id]).to eq(1)
    end

    context "belongs_to relationship already exists on the associated source" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            has_many :comments
          end

          source :comments do
            primary_id
            belongs_to :post
          end
        end
      end

      it "does not create another belongs_to relationship on the associated source" do
        expect(data.comments.source.class.associations[:belongs_to].count).to eq(1)
      end
    end

    describe "extending an association" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            has_many :comments, query: :ordered
          end

          source :comments do
            primary_id
            attribute :order

            def ordered
              order { order.asc }
            end
          end
        end
      end

      it "can be extended" do
        post = data.posts.create({}).one
        data.comments.create(post: post, order: "3")
        data.comments.create(post: post, order: "1")
        data.comments.create(post: post, order: "2")
        expect(data.posts.including(:comments).one[:comments].count).to eq(3)
        expect(data.posts.including(:comments).one[:comments][0][:order]).to eq("1")
        expect(data.posts.including(:comments).one[:comments][1][:order]).to eq("2")
        expect(data.posts.including(:comments).one[:comments][2][:order]).to eq("3")
      end
    end

    describe "aliasing an association" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            has_many :notes, source: :comments
          end

          source :comments do
            primary_id
          end
        end
      end

      it "creates an aliased has_many relationship" do
        post = data.posts.create({}).one
        data.comments.create(post: post)
        expect(data.posts.including(:notes).one[:notes].count).to eq(1)
      end
    end

    describe "providing an aliased name for the reciprocal relationship" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            has_many :comments, as: :owner
          end

          source :comments do
            primary_id
          end
        end
      end

      it "creates a belongs_to relationship on the associated source" do
        post = data.posts.create({}).one
        data.comments.create(owner: post)
        expect(data.comments.including(:owner).one[:owner][:id]).to eq(1)
      end
    end

    include_examples :source_associations_dependent
  end
end
