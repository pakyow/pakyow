require_relative "./dependent"

RSpec.shared_examples :source_associations_has_one do
  describe "has_one" do
    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts do
          primary_id
          has_one :comment
        end

        source :comments do
          primary_id
        end
      end
    end

    it "creates a has_one relationship" do
      post = data.posts.create({}).one
      data.comments.create(post: post)
      expect(data.posts.including(:comment).one[:comment]).to be_instance_of(Pakyow::Data::Object)
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
            has_one :comments
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

    context "associated object already exists" do
      shared_examples :disassociate do
        it "disassociates the current object" do
          expect(data.comments.by_id(1).one.post_id).to be(nil)
        end

        it "associates the new object" do
          expect(data.comments.by_id(2).one.post_id).to eq(1)
        end

        it "does not disassociate objects unrelated to the change" do
          expect(data.comments.by_id(3).one.post_id).to eq(2)
        end
      end

      context "new associated object is created by id" do
        before do
          post = data.posts.create({}).one
          data.comments.create(post_id: post.id)
          data.comments.create(post_id: post.id)
          data.comments.create(post_id: data.posts.create({}).one.id)
        end

        include_examples :disassociate
      end

      context "new associated object is created by object" do
        before do
          post = data.posts.create({}).one
          data.comments.create(post: post)
          data.comments.create(post: post)
          data.comments.create(post: data.posts.create({}).one)
        end

        include_examples :disassociate
      end

      context "new associated object is updated by id" do
        before do
          post1 = data.posts.create({}).one
          post2 = data.posts.create({}).one
          comment1 = data.comments.create(post_id: post1.id)
          comment2 = data.comments.create(post_id: post2.id)
          comment3 = data.comments.create(post_id: post2.id)
          comment2.update(post_id: post1.id)
        end

        include_examples :disassociate
      end

      context "new associated object is updated by object" do
        before do
          post1 = data.posts.create({}).one
          post2 = data.posts.create({}).one
          comment1 = data.comments.create(post: post1)
          comment2 = data.comments.create(post: post2)
          comment3 = data.comments.create(post: post2)
          comment2.update(post: post1)
        end

        include_examples :disassociate
      end
    end

    describe "aliasing an association" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            has_one :note, source: :comments
          end

          source :comments do
            primary_id
          end
        end
      end

      it "creates an aliased has_one relationship" do
        post = data.posts.create({}).one
        data.comments.create(post: post)
        expect(data.posts.including(:note).one[:note]).to be_instance_of(Pakyow::Data::Object)
      end
    end

    describe "providing an aliased name for the reciprocal relationship" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            has_one :comments, as: :owner
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
