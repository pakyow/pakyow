require_relative "./dependent"

RSpec.shared_examples :source_associations_has_many do
  describe "has_many" do
    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts do
          primary_id
          has_many :comments

          query do
            order { id.asc }
          end
        end

        source :comments do
          primary_id

          query do
            order { id.asc }
          end
        end

        source :replies do
          primary_id

          query do
            order { id.asc }
          end
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

    describe "specifying associated belongs_to data when creating" do
      before do
        data.comments.create({})
        data.comments.create({})
        data.comments.create({})
        data.comments.create({})
        post
      end

      shared_examples :association_tests do
        it "associates the specified data" do
          expect(data.comments.to_a[0][:post_id]).to eq(post[:id])
          expect(data.comments.to_a[1][:post_id]).to eq(post[:id])
          expect(data.comments.to_a[2][:post_id]).to eq(post[:id])
        end

        it "does not associate unspecified data" do
          expect(data.comments.to_a[3][:post_id]).to eq(nil)
        end
      end

      context "specified as an array of ids" do
        let :post do
          data.posts.create(comments: data.comments.to_a.map(&:id).take(3)).one
        end

        include_examples :association_tests
      end

      context "specified as an array of objects" do
        let :post do
          data.posts.create(comments: data.comments.to_a.take(3)).one
        end

        include_examples :association_tests
      end

      context "specified as a dataset" do
        let :post do
          data.posts.create(comments: data.comments.by_id(data.comments.to_a.map(&:id).take(3))).one
        end

        include_examples :association_tests

        context "dataset is not for the correct source" do
          before do
            data.replies.create({})
            data.replies.create({})
          end

          it "does not associate the data" do
            expect(data.posts.count).to eq(1)

            begin
              data.posts.create(comments: data.replies)
            rescue
            end

            expect(data.posts.count).to eq(1)
          end

          it "raises an error" do
            expect {
              data.posts.create(comments: data.replies)
            }.to raise_error(Pakyow::Data::ConstraintViolation)
          end

          describe "error message" do
            it "is worded properly" do
              expect {
                data.posts.create(comments: data.replies)
              }.to raise_error do |error|
                expect(error.to_s).to eq(
                  "Cannot associate replies as comments"
                )
              end
            end
          end
        end
      end
    end

    describe "specifying associated belongs_to data when updating" do
      before do
        data.comments.create({})
        data.comments.create({})
        data.comments.create({})
        data.comments.create({})
        data.posts.create(comments: data.comments.create({}))
        post
      end

      shared_examples :association_tests do
        it "associates the specified data" do
          expect(data.comments.to_a[0][:post_id]).to eq(post[:id])
          expect(data.comments.to_a[1][:post_id]).to eq(post[:id])
          expect(data.comments.to_a[2][:post_id]).to eq(post[:id])
        end

        it "does not associate unspecified data" do
          expect(data.comments.to_a[3][:post_id]).to eq(nil)
        end

        it "disassociates data that is no longer associated" do
          expect(data.comments.to_a[4][:post_id]).to eq(nil)
        end
      end

      context "specified as an array of ids" do
        let :post do
          data.posts.by_id(1).update(comments: data.comments.to_a.map(&:id).take(3)).one
        end

        include_examples :association_tests
      end

      context "specified as an array of objects" do
        let :post do
          data.posts.by_id(1).update(comments: data.comments.to_a.take(3)).one
        end

        include_examples :association_tests
      end

      context "specified as a dataset" do
        let :post do
          data.posts.by_id(1).update(comments: data.comments.by_id(data.comments.to_a.map(&:id).take(3))).one
        end

        include_examples :association_tests

        context "dataset is not for the correct source" do
          before do
            data.replies.create({})
            data.replies.create({})
            data.comments.update(post_id: nil)
          end

          it "does not associate the data" do
            begin
              data.posts.update(comments: data.replies)
            rescue
            end

            expect(data.comments.one[:post_id]).to eq(nil)
          end

          it "raises an error" do
            expect {
              data.posts.update(comments: data.replies)
            }.to raise_error(Pakyow::Data::ConstraintViolation)
          end

          describe "error message" do
            it "is worded properly" do
              expect {
                data.posts.update(comments: data.replies)
              }.to raise_error do |error|
                expect(error.to_s).to eq(
                  "Cannot associate replies as comments"
                )
              end
            end
          end
        end
      end

      context "multiple objects are updated" do
        let :post do
          data.posts.update(comments: data.comments.by_id(data.comments.to_a.map(&:id).take(3))).one
        end

        include_examples :association_tests
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
