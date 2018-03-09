RSpec.shared_examples :model_associations do
  describe "associating models" do
    before do
      Pakyow.config.data.connections.sql[:default] = connection_string
    end

    include_context "testable app"

    let :data do
      Pakyow.apps.first.data
    end

    describe "has_many" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          model :post do
            primary_id
            has_many :comments
          end

          model :comment do
            primary_id
          end
        end
      end

      it "creates a has_many relationship" do
        post = data.posts.create({})
        data.comments.create(post_id: post[:id])
        expect(data.posts.with_comments.first[:comments].count).to eq(1)
      end

      it "creates a belongs_to relationship on the associated model" do
        post = data.posts.create({})
        data.comments.create(post_id: post[:id])
        expect(data.comments.with_post.first[:post][:id]).to eq(1)
      end

      describe "specifying the associated data when updating" do
        it "can be specified with an id" do
          post = data.posts.create({})
          data.comments.create({})
          data.comments.update(post_id: post[:id])
          expect(data.posts.with_comments.first[:comments].count).to eq(1)
        end

        it "can be specified with the object" do
          post = data.posts.create({})
          data.comments.create({})
          data.comments.update(post: post)
          expect(data.posts.with_comments.first[:comments].count).to eq(1)
        end
      end

      describe "extending an association" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            model :post do
              primary_id
              has_many :comments, view: :ordered
            end

            model :comment do
              primary_id
              attribute :order

              queries do
                def ordered
                  order { order.asc }
                end
              end
            end
          end
        end

        it "can be extended" do
          post = data.posts.create({})
          data.comments.create(post_id: post[:id], order: "3")
          data.comments.create(post_id: post[:id], order: "1")
          data.comments.create(post_id: post[:id], order: "2")
          expect(data.posts.with_comments.first[:comments].count).to eq(3)
          expect(data.posts.with_comments.first[:comments][0][:order]).to eq("1")
          expect(data.posts.with_comments.first[:comments][1][:order]).to eq("2")
          expect(data.posts.with_comments.first[:comments][2][:order]).to eq("3")
        end
      end

      describe "aliasing an association" do
        it "needs to be defined"
      end

      describe "overriding an association" do
        it "needs to be defined"
      end
    end

    describe "has_one" do
      it "needs to be defined"
    end

    describe "belongs_to" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          model :post do
            primary_id
          end

          model :comment do
            primary_id
            belongs_to :post
          end
        end
      end

      it "creates a belongs_to relationship" do
        post = data.posts.create({})
        data.comments.create(post_id: post[:id])
        expect(data.comments.with_post.first[:post][:id]).to eq(1)
      end

      describe "the foreign key" do
        it "has a default" do
          data.comments.create({})
          expect(data.comments.first.keys).to include(:post_id)
        end

        context "specifying the foreign key" do
          it "needs to be defined"
        end
      end

      describe "specifying the associated data when creating" do
        it "can be specified with an id" do
          post = data.posts.create({})
          data.comments.create(post_id: post[:id])
          expect(data.comments.first[:post_id]).to eq(post[:id])
        end

        it "can be specified with the object" do
          post = data.posts.create({})
          data.comments.create(post: post)
          expect(data.comments.first[:post_id]).to eq(post[:id])
        end
      end

      describe "specifying the associated data when updating" do
        it "can be specified with an id" do
          post = data.posts.create({})
          data.comments.create({})
          data.comments.update(post_id: post[:id])
          expect(data.comments.first[:post_id]).to eq(post[:id])
        end

        it "can be specified with the object" do
          post = data.posts.create({})
          data.comments.create({})
          data.comments.update(post: post)
          expect(data.comments.first[:post_id]).to eq(post[:id])
        end
      end

      describe "aliasing an association" do
        it "needs to be defined"
      end

      describe "extending an association" do
        it "needs to be defined"
      end

      describe "overriding an association" do
        it "needs to be defined"
      end
    end

    describe "has_many_through" do
      it "needs to be defined"
    end

    describe "has_one_through" do
      it "needs to be defined"
    end
  end
end
