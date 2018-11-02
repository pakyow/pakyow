RSpec.shared_examples :source_associations_belongs_to do
  describe "belongs_to" do
    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts do
          primary_id
        end

        source :comments do
          primary_id
          belongs_to :post
        end
      end
    end

    it "creates a belongs_to relationship" do
      post = data.posts.create({}).one
      data.comments.create(post: post)
      expect(data.comments.including(:post).one[:post][:id]).to eq(1)
    end

    describe "the foreign key" do
      it "has a default" do
        data.comments.create({})
        expect(data.comments.one.to_h.keys).to include(:post_id)
      end

      context "specifying the foreign key" do
        it "will be supported in the future"
      end
    end

    describe "specifying the associated data when creating" do
      it "can be specified with an id" do
        post = data.posts.create({}).one
        data.comments.create(post_id: post[:id])
        expect(data.comments.one[:post_id]).to eq(post[:id])
      end

      it "can be specified with the object" do
        post = data.posts.create({}).one
        data.comments.create(post: post)
        expect(data.comments.one[:post_id]).to eq(post[:id])
      end
    end

    describe "specifying the associated data when updating" do
      it "can be specified with an id" do
        post = data.posts.create({}).one
        data.comments.create({})
        data.comments.update(post_id: post[:id])
        expect(data.comments.one[:post_id]).to eq(post[:id])
      end

      it "can be specified with the object" do
        post = data.posts.create({}).one
        data.comments.create({})
        data.comments.update(post: post)
        expect(data.comments.one[:post_id]).to eq(post[:id])
      end
    end

    describe "aliasing an association" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
          end

          source :comments do
            primary_id
            belongs_to :owner, source: :posts
          end
        end
      end

      it "creates an aliased belongs_to relationship" do
        post = data.posts.create({}).one
        data.comments.create(owner: post)
        expect(data.comments.including(:owner).one[:owner][:id]).to eq(1)
      end

      describe "the foreign key" do
        it "has a default" do
          data.comments.create({})
          expect(data.comments.one.to_h.keys).to include(:owner_id)
        end

        context "specifying the foreign key" do
          it "will be supported in the future"
        end
      end

      describe "specifying the associated data when creating" do
        it "can be specified with an id" do
          post = data.posts.create({}).one
          data.comments.create(owner_id: post[:id])
          expect(data.comments.one[:owner_id]).to eq(post[:id])
        end

        it "can be specified with the object" do
          post = data.posts.create({}).one
          data.comments.create(owner: post)
          expect(data.comments.one[:owner_id]).to eq(post[:id])
        end
      end

      describe "specifying the associated data when updating" do
        it "can be specified with an id" do
          post = data.posts.create({}).one
          data.comments.create({})
          data.comments.update(owner_id: post[:id])
          expect(data.comments.one[:owner_id]).to eq(post[:id])
        end

        it "can be specified with the object" do
          post = data.posts.create({}).one
          data.comments.create({})
          data.comments.update(owner: post)
          expect(data.comments.one[:owner_id]).to eq(post[:id])
        end
      end
    end
  end
end
