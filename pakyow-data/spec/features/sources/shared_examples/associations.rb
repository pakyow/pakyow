RSpec.shared_examples :source_associations do
  describe "associating sources" do
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
        data.comments.create(post_id: post[:id])
        expect(data.posts.including(:comments).one[:comments].count).to eq(1)
      end

      it "creates a belongs_to relationship on the associated source" do
        post = data.posts.create({}).one
        data.comments.create(post_id: post[:id])
        expect(data.comments.including(:post).one[:post][:id]).to eq(1)
      end

      it "allows the result to be fetched multiple times" do
        post = data.posts.create({}).one
        data.comments.create(post_id: post[:id])
        result = data.comments.including(:post)
        expect(result.one[:post][:id]).to eq(1)
        expect(result.to_a[0][:post][:id]).to eq(1)
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
          data.comments.create(post_id: post[:id], order: "3")
          data.comments.create(post_id: post[:id], order: "1")
          data.comments.create(post_id: post[:id], order: "2")
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
    end

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
        data.comments.create(post_id: post[:id])
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
              has_many :comments, as: :owner
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

    describe "has_one" do
      it "will be supported in the future"
    end

    describe "has_many :through" do
      it "will be supported in the future"
    end

    describe "has_one :through" do
      it "will be supported in the future"
    end

    describe "many_to_many" do
      it "will be supported in the future"
    end
  end
end
