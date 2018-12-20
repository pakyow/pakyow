require_relative "./associations/belongs_to"
require_relative "./associations/has_many"
require_relative "./associations/has_many_through"
require_relative "./associations/has_one"
require_relative "./associations/has_one_through"
require_relative "./associations/many_to_many"
require_relative "./associations/one_to_one"

RSpec.shared_examples :source_associations do
  describe "associating sources" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "testable app"

    describe "belongs_to" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id

            query do
              order { id.asc }
            end
          end

          source :comments do
            primary_id
            belongs_to :post

            query do
              order { id.asc }
            end
          end
        end
      end

      it_behaves_like :source_associations_belongs_to do
        let :target_source do
          :comments
        end

        let :associated_source do
          :posts
        end

        let :association_name do
          :post
        end
      end

      describe "aliased association" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id

              query do
                order { id.asc }
              end
            end

            source :comments do
              primary_id
              belongs_to :owner, source: :posts

              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_belongs_to do
          let :target_source do
            :comments
          end

          let :associated_source do
            :posts
          end

          let :association_name do
            :owner
          end
        end
      end

      describe "belonging to multiple different sources" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id

              query do
                order { id.asc }
              end
            end

            source :messages do
              primary_id

              query do
                order { id.asc }
              end
            end

            source :comments do
              primary_id
              belongs_to :post
              belongs_to :message

              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_belongs_to do
          let :target_source do
            :comments
          end

          let :associated_source do
            :posts
          end

          let :association_name do
            :post
          end
        end

        it_behaves_like :source_associations_belongs_to do
          let :target_source do
            :comments
          end

          let :associated_source do
            :messages
          end

          let :association_name do
            :message
          end
        end
      end

      describe "belonging to the same source multiple times" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id

              query do
                order { id.asc }
              end
            end

            source :comments do
              primary_id
              belongs_to :post
              belongs_to :owner, source: :posts
              belongs_to :yolo, source: :posts

              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_belongs_to do
          let :target_source do
            :comments
          end

          let :associated_source do
            :posts
          end

          let :association_name do
            :post
          end
        end

        it_behaves_like :source_associations_belongs_to do
          let :target_source do
            :comments
          end

          let :associated_source do
            :posts
          end

          let :association_name do
            :owner
          end
        end

        it_behaves_like :source_associations_belongs_to do
          let :target_source do
            :comments
          end

          let :associated_source do
            :posts
          end

          let :association_name do
            :yolo
          end
        end
      end

      describe "association with a specific query" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id

              query do
                order { id.asc }
              end

              def id_gt_one
                where { id > 1 }
              end
            end

            source :comments do
              primary_id
              belongs_to :post, query: :id_gt_one

              query do
                order { id.asc }
              end
            end
          end
        end

        before do
          data.comments.create(
            post: data.posts.create
          )

          data.comments.create(
            post: data.posts.create
          )
        end

        it "applies the query to the included source" do
          comments = data.comments.including(:post)
          expect(comments[0].post).to be(nil)
          expect(comments[1].post).to_not be(nil)
        end
      end

      describe "edge cases around definition" do
        context "association is specified as plural" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                primary_id
              end

              source :comments do
                primary_id
                belongs_to :posts
              end
            end
          end

          it "treats it as singular" do
            data.comments.create(post: data.posts.create)
            expect(data.comments.one.post_id).to_not be(nil)
          end
        end

        context "association source does not exist" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :comments do
                primary_id
                belongs_to :posts
              end
            end
          end

          it "raises an error that puts the app in rescue mode" do
            expect(Pakyow.app(:test).call({})[2].join).to include("Unknown source `posts` for association: comments belongs_to post")
          end
        end
      end

      describe "association with the source having a custom primary key" do
        let :app_definition do
          slugs = 100.times.to_a.map(&:to_s)

          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts, primary_id: false do
              primary_key :slug
              attribute :slug, :string, default: -> {
                # Ensures the ids are in a predictable sort order.
                #
                slugs.shift
              }

              query do
                order { slug.asc }
              end
            end

            source :comments do
              primary_id
              belongs_to :post

              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_belongs_to do
          let :target_source do
            :comments
          end

          let :associated_source do
            :posts
          end

          let :association_name do
            :post
          end
        end
      end

      describe "association with a custom foreign key" do
        it "will be supported in the future"
      end
    end

    describe "has_one" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            has_one :comment

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
        end
      end

      it_behaves_like :source_associations_has_one do
        let :target_source do
          :posts
        end

        let :associated_source do
          :comments
        end

        let :association_name do
          :comment
        end

        let :associated_as do
          :post
        end
      end

      describe "dependent: delete" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id
              has_one :comment, dependent: :delete

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
          end
        end

        it_behaves_like :source_associations_has_one, dependents: :delete do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :comment
          end

          let :associated_as do
            :post
          end
        end
      end

      describe "dependent: nullify" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id
              has_one :comment, dependent: :nullify

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
          end
        end

        it_behaves_like :source_associations_has_one, dependents: :nullify do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :comment
          end

          let :associated_as do
            :post
          end
        end
      end

      describe "reciprocal association" do
        it_behaves_like :source_associations_belongs_to do
          let :target_source do
            :comments
          end

          let :associated_source do
            :posts
          end

          let :association_name do
            :post
          end
        end

        context "reciprocal association already exists" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                primary_id
                has_one :comment, dependent: :nullify
              end

              source :comments do
                primary_id
                belongs_to :post, query: :foo

                def foo
                  self
                end
              end
            end
          end

          it "does not create a duplicate association" do
            expect(data.comments.source.class.associations[:belongs_to].count).to eq(1)
          end

          it "does not override the existing association" do
            expect(data.comments.source.class.associations[:belongs_to][0].query).to eq(:foo)
          end
        end
      end

      describe "aliased association" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id
              has_one :unmentionable, source: :comments

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
          end
        end

        it_behaves_like :source_associations_has_one do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :unmentionable
          end

          let :associated_as do
            :post
          end
        end
      end

      describe "aliased name for the reciprocal association" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id
              has_one :comment, as: :owner

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
          end
        end

        describe "reciprocal association" do
          it_behaves_like :source_associations_belongs_to do
            let :target_source do
              :comments
            end

            let :associated_source do
              :posts
            end

            let :association_name do
              :owner
            end
          end
        end

        context "reciprocal association already exists" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                primary_id
                has_one :comment, as: :owner
              end

              source :comments do
                primary_id
                belongs_to :owner, source: :posts, query: :foo

                def foo
                  self
                end
              end
            end
          end

          it "does not create a duplicate association" do
            expect(data.comments.source.class.associations[:belongs_to].count).to eq(1)
          end

          it "does not override the existing association" do
            expect(data.comments.source.class.associations[:belongs_to][0].query).to eq(:foo)
          end
        end
      end

      describe "association with a specific query" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id
              has_one :comment, query: :id_gt_one

              query do
                order { id.asc }
              end
            end

            source :comments do
              primary_id

              query do
                order { id.asc }
              end

              def id_gt_one
                where { id > 1 }
              end
            end
          end
        end

        before do
          data.posts.create(
            comment: data.comments.create
          )

          data.posts.create(
            comment: data.comments.create
          )
        end

        it "applies the query to the included source" do
          posts = data.posts.including(:comment)
          expect(posts[0].comment).to be(nil)
          expect(posts[1].comment).to_not be(nil)
        end
      end

      describe "edge cases around definition" do
        context "association is specified as plural" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                primary_id
                has_one :comments
              end

              source :comments do
                primary_id
              end
            end
          end

          it "treats it as singular" do
            data.posts.create(comment: data.comments.create)
            expect(data.comments.one.post_id).to_not be(nil)
          end
        end

        context "association source does not exist" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                primary_id
                has_one :comment
              end
            end
          end

          it "raises an error that puts the app in rescue mode" do
            expect(Pakyow.app(:test).call({})[2].join).to include("Unknown source `comments` for association: posts has_one comment")
          end
        end
      end

      describe "association with the source having a custom primary key" do
        let :app_definition do
          slugs = 100.times.to_a.map(&:to_s)

          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts, primary_id: false do
              primary_key :slug

              attribute :slug, :string, default: -> {
                # Ensures the ids are in a predictable sort order.
                #
                slugs.shift
              }

              has_one :comment

              query do
                order { slug.asc }
              end
            end

            source :comments do
              primary_id

              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_has_one do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :comment
          end

          let :associated_as do
            :post
          end
        end

        describe "reciprocal association" do
          it_behaves_like :source_associations_belongs_to do
            let :target_source do
              :comments
            end

            let :associated_source do
              :posts
            end

            let :association_name do
              :post
            end
          end
        end
      end
    end

    describe "has_one :through" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            has_one :comment, through: :related

            query do
              order { id.asc }
            end
          end

          source :comments do
            query do
              order { id.asc }
            end
          end

          source :relateds do
            query do
              order { id.asc }
            end
          end
        end
      end

      it_behaves_like :source_associations_has_one_through do
        let :target_source do
          :posts
        end

        let :associated_source do
          :comments
        end

        let :joining_source do
          :relateds
        end

        let :association_name do
          :comment
        end

        let :associated_as do
          :post
        end
      end

      describe "dependent: delete" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_one :comment, through: :related, dependent: :delete

              query do
                order { id.asc }
              end
            end

            source :comments do
              query do
                order { id.asc }
              end
            end

            source :relateds do
              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_has_one_through, dependents: :delete do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :joining_source do
            :relateds
          end

          let :association_name do
            :comment
          end

          let :associated_as do
            :post
          end
        end
      end

      describe "dependent: nullify" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_one :comment, through: :related, dependent: :nullify

              query do
                order { id.asc }
              end
            end

            source :comments do
              query do
                order { id.asc }
              end
            end

            source :relateds do
              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_has_one_through, dependents: :nullify do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :joining_source do
            :relateds
          end

          let :association_name do
            :comment
          end

          let :associated_as do
            :post
          end
        end
      end

      describe "reciprocal association" do
        it_behaves_like :source_associations_has_one_through do
          let :target_source do
            :comments
          end

          let :associated_source do
            :posts
          end

          let :joining_source do
            :relateds
          end

          let :association_name do
            :post
          end

          let :associated_as do
            :comment
          end
        end
      end

      describe "aliased association" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_one :unmentionable, through: :relateds, source: :comments

              query do
                order { id.asc }
              end
            end

            source :comments do
              query do
                order { id.asc }
              end
            end

            source :relateds do
              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_has_one_through do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :joining_source do
            :relateds
          end

          let :association_name do
            :unmentionable
          end

          let :associated_as do
            :post
          end
        end
      end

      describe "aliased name for the reciprocal association" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_one :comment, through: :related, as: :owners

              query do
                order { id.asc }
              end
            end

            source :comments do
              query do
                order { id.asc }
              end
            end

            source :relateds do
              query do
                order { id.asc }
              end
            end
          end
        end

        describe "reciprocal association" do
          it_behaves_like :source_associations_has_one_through do
            let :target_source do
              :comments
            end

            let :associated_source do
              :posts
            end

            let :joining_source do
              :relateds
            end

            let :association_name do
              :owner
            end

            let :associated_as do
              :comment
            end
          end
        end
      end

      describe "association with a specific query" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_one :comment, through: :related, query: :id_gt_one

              query do
                order { id.asc }
              end
            end

            source :comments do
              query do
                order { id.asc }
              end

              def id_gt_one
                where { id > 1 }
              end
            end

            source :relateds do
              query do
                order { id.asc }
              end
            end
          end
        end

        before do
          data.posts.create(
            comment: data.comments.create
          )

          data.posts.create(
            comment: data.comments.create
          )
        end

        it "applies the query to the included source" do
          expect(data.posts.including(:comment).one.comment).to be(nil)
        end
      end

      describe "edge cases around definition" do
        context "through association is specified as plural" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                has_one :comment, through: :relateds
              end

              source :comments do
              end

              source :relateds do
              end
            end
          end

          it "treats it as singular" do
            data.posts.create(comment: data.comments.create)
            expect(data.posts.including(:comment).one.comment).to_not be(nil)
          end
        end

        context "through association source does not exist" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                has_one :comment, through: :related
              end

              source :comments do
              end
            end
          end

          it "raises an error that puts the app in rescue mode" do
            expect(Pakyow.app(:test).call({})[2].join).to include("Unknown source `relateds` for association: posts has_one comment")
          end
        end
      end

      describe "association with the source having a custom primary key" do
        let :app_definition do
          slugs = 100.times.to_a.map(&:to_s)

          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts, primary_id: false do
              primary_key :slug

              attribute :slug, :string, default: -> {
                # Ensures the ids are in a predictable sort order.
                #
                slugs.shift
              }

              has_one :comment, through: :related

              query do
                order { slug.asc }
              end
            end

            source :comments do
              primary_id

              query do
                order { id.asc }
              end
            end

            source :relateds do
              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_has_one_through do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :joining_source do
            :relateds
          end

          let :association_name do
            :comment
          end

          let :associated_as do
            :post
          end
        end

        describe "reciprocal association" do
          it_behaves_like :source_associations_has_one_through do
            let :target_source do
              :comments
            end

            let :associated_source do
              :posts
            end

            let :joining_source do
              :relateds
            end

            let :association_name do
              :post
            end

            let :associated_as do
              :comment
            end
          end
        end
      end

      describe "association with the joining source having a custom primary key" do
        let :app_definition do
          slugs = 100.times.to_a.map(&:to_s)

          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_one :comment, through: :related

              query do
                order { id.asc }
              end
            end

            source :comments do
              query do
                order { id.asc }
              end
            end

            source :relateds, primary_id: false do
              primary_key :slug

              attribute :slug, :string, default: -> {
                # Ensures the ids are in a predictable sort order.
                #
                slugs.shift
              }

              query do
                order { slug.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_has_one_through do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :joining_source do
            :relateds
          end

          let :association_name do
            :comment
          end

          let :associated_as do
            :post
          end
        end

        describe "reciprocal association" do
          it_behaves_like :source_associations_has_one_through do
            let :target_source do
              :comments
            end

            let :associated_source do
              :posts
            end

            let :joining_source do
              :relateds
            end

            let :association_name do
              :post
            end

            let :associated_as do
              :comment
            end
          end
        end
      end
    end

    describe "one_to_one" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            has_one :comment

            query do
              order { id.asc }
            end
          end

          source :comments do
            has_one :post

            query do
              order { id.asc }
            end
          end
        end
      end

      it_behaves_like :source_associations_one_to_one do
        let :target_source do
          :posts
        end

        let :associated_source do
          :comments
        end

        let :association_name do
          :comment
        end

        let :associated_as do
          :post
        end
      end

      describe "dependent: delete" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_one :comment, dependent: :delete

              query do
                order { id.asc }
              end
            end

            source :comments do
              has_one :post, dependent: :delete

              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_one_to_one, dependents: :delete do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :comment
          end

          let :associated_as do
            :post
          end
        end
      end

      describe "dependent: nullify" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_one :comment, dependent: :nullify

              query do
                order { id.asc }
              end
            end

            source :comments do
              has_one :post, dependent: :nullify

              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_one_to_one, dependents: :nullify do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :comment
          end

          let :associated_as do
            :post
          end
        end
      end

      describe "reciprocal association" do
        it_behaves_like :source_associations_one_to_one do
          let :target_source do
            :comments
          end

          let :associated_source do
            :posts
          end

          let :association_name do
            :post
          end

          let :associated_as do
            :comment
          end
        end
      end

      describe "aliased association" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_one :unmentionable, source: :comments

              query do
                order { id.asc }
              end
            end

            source :comments do
              has_one :post, as: :unmentionable

              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_one_to_one do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :unmentionable
          end

          let :associated_as do
            :post
          end
        end
      end

      describe "aliased name for the reciprocal association" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_one :comment, as: :owner

              query do
                order { id.asc }
              end
            end

            source :comments do
              has_one :owner, source: :posts

              query do
                order { id.asc }
              end
            end
          end
        end

        describe "reciprocal association" do
          it_behaves_like :source_associations_one_to_one do
            let :target_source do
              :comments
            end

            let :associated_source do
              :posts
            end

            let :association_name do
              :owner
            end

            let :associated_as do
              :comment
            end
          end
        end
      end

      describe "association with a specific query" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_one :comment, query: :id_gt_one

              query do
                order { id.asc }
              end
            end

            source :comments do
              has_one :post

              query do
                order { id.asc }
              end

              def id_gt_one
                where { id > 1 }
              end
            end
          end
        end

        before do
          data.posts.create(
            comment: data.comments.create
          )

          data.posts.create(
            comment: data.comments.create
          )
        end

        it "applies the query to the included source" do
          expect(data.posts.including(:comment).one.comment).to be(nil)
        end
      end

      describe "association with the source having a custom primary key" do
        let :app_definition do
          slugs = 100.times.to_a.map(&:to_s)

          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts, primary_id: false do
              primary_key :slug

              attribute :slug, :string, default: -> {
                # Ensures the ids are in a predictable sort order.
                #
                slugs.shift
              }

              has_one :comment

              query do
                order { slug.asc }
              end
            end

            source :comments do
              has_one :post

              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_one_to_one do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :comment
          end

          let :associated_as do
            :post
          end
        end

        describe "reciprocal association" do
          it_behaves_like :source_associations_one_to_one do
            let :target_source do
              :comments
            end

            let :associated_source do
              :posts
            end

            let :association_name do
              :post
            end

            let :associated_as do
              :comment
            end
          end
        end
      end
    end

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
        end
      end

      it_behaves_like :source_associations_has_many do
        let :target_source do
          :posts
        end

        let :associated_source do
          :comments
        end

        let :association_name do
          :comments
        end

        let :associated_as do
          :post
        end
      end

      describe "dependent: delete" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id
              has_many :comments, dependent: :delete

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
          end
        end

        it_behaves_like :source_associations_has_many, dependents: :delete do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :comments
          end

          let :associated_as do
            :post
          end
        end
      end

      describe "dependent: nullify" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id
              has_many :comments, dependent: :nullify

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
          end
        end

        it_behaves_like :source_associations_has_many, dependents: :nullify do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :comments
          end

          let :associated_as do
            :post
          end
        end
      end

      describe "reciprocal association" do
        it_behaves_like :source_associations_belongs_to do
          let :target_source do
            :comments
          end

          let :associated_source do
            :posts
          end

          let :association_name do
            :post
          end
        end

        context "reciprocal association already exists" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                primary_id
                has_many :comments, dependent: :nullify
              end

              source :comments do
                primary_id
                belongs_to :post, query: :foo

                def foo
                  self
                end
              end
            end
          end

          it "does not create a duplicate association" do
            expect(data.comments.source.class.associations[:belongs_to].count).to eq(1)
          end

          it "does not override the existing association" do
            expect(data.comments.source.class.associations[:belongs_to][0].query).to eq(:foo)
          end
        end
      end

      describe "aliased association" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id
              has_many :unmentionables, source: :comments

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
          end
        end

        it_behaves_like :source_associations_has_many do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :unmentionables
          end

          let :associated_as do
            :post
          end
        end
      end

      describe "aliased name for the reciprocal association" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id
              has_many :comments, as: :owner

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
          end
        end

        describe "reciprocal association" do
          it_behaves_like :source_associations_belongs_to do
            let :target_source do
              :comments
            end

            let :associated_source do
              :posts
            end

            let :association_name do
              :owner
            end
          end

          context "reciprocal association already exists" do
            let :app_definition do
              Proc.new do
                instance_exec(&$data_app_boilerplate)

                source :posts do
                  primary_id
                  has_many :comments, as: :owner
                end

                source :comments do
                  primary_id
                  belongs_to :owner, source: :comments, query: :foo

                  def foo
                    self
                  end
                end
              end
            end

            it "does not create a duplicate association" do
              expect(data.comments.source.class.associations[:belongs_to].count).to eq(1)
            end

            it "does not override the existing association" do
              expect(data.comments.source.class.associations[:belongs_to][0].query).to eq(:foo)
            end
          end
        end
      end

      describe "association with a specific query" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id
              has_many :comments, query: :id_gt_one

              query do
                order { id.asc }
              end
            end

            source :comments do
              primary_id

              query do
                order { id.asc }
              end

              def id_gt_one
                where { id > 1 }
              end
            end
          end
        end

        before do
          data.posts.create(
            comments: data.comments.create
          )

          data.posts.create(
            comments: data.comments.create
          )
        end

        it "applies the query to the included source" do
          posts = data.posts.including(:comments)
          expect(posts[0].comments.count).to be(0)
          expect(posts[1].comments.count).to be(1)
        end
      end

      describe "edge cases around definition" do
        context "association is specified as singular" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                primary_id
                has_many :comment
              end

              source :comments do
                primary_id
              end
            end
          end

          it "treats it as plural" do
            data.posts.create(comments: data.comments.create)
            expect(data.comments.one.post_id).to_not be(nil)
          end
        end

        context "association source does not exist" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                primary_id
                has_many :comments
              end
            end
          end

          it "raises an error that puts the app in rescue mode" do
            expect(Pakyow.app(:test).call({})[2].join).to include("Unknown source `comments` for association: posts has_many comments")
          end
        end
      end

      describe "association with the source having a custom primary key" do
        let :app_definition do
          slugs = 100.times.to_a.map(&:to_s)

          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts, primary_id: false do
              primary_key :slug

              attribute :slug, :string, default: -> {
                # Ensures the ids are in a predictable sort order.
                #
                slugs.shift
              }

              has_many :comments

              query do
                order { slug.asc }
              end
            end

            source :comments do
              primary_id

              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_has_many do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :comments
          end

          let :associated_as do
            :post
          end
        end

        describe "reciprocal association" do
          it_behaves_like :source_associations_belongs_to do
            let :target_source do
              :comments
            end

            let :associated_source do
              :posts
            end

            let :association_name do
              :post
            end
          end
        end
      end
    end

    describe "has_many :through" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            has_many :comments, through: :relateds

            query do
              order { id.asc }
            end
          end

          source :comments do
            query do
              order { id.asc }
            end
          end

          source :relateds do
            query do
              order { id.asc }
            end
          end
        end
      end

      it_behaves_like :source_associations_has_many_through do
        let :target_source do
          :posts
        end

        let :associated_source do
          :comments
        end

        let :joining_source do
          :relateds
        end

        let :association_name do
          :comments
        end

        let :associated_as do
          :posts
        end
      end

      describe "dependent: delete" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_many :comments, through: :relateds, dependent: :delete

              query do
                order { id.asc }
              end
            end

            source :comments do
              query do
                order { id.asc }
              end
            end

            source :relateds do
              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_has_many_through, dependents: :delete do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :joining_source do
            :relateds
          end

          let :association_name do
            :comments
          end

          let :associated_as do
            :posts
          end
        end
      end

      describe "dependent: nullify" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_many :comments, through: :relateds, dependent: :nullify

              query do
                order { id.asc }
              end
            end

            source :comments do
              query do
                order { id.asc }
              end
            end

            source :relateds do
              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_has_many_through, dependents: :nullify do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :joining_source do
            :relateds
          end

          let :association_name do
            :comments
          end

          let :associated_as do
            :posts
          end
        end
      end

      describe "reciprocal association" do
        it_behaves_like :source_associations_has_many_through do
          let :target_source do
            :comments
          end

          let :associated_source do
            :posts
          end

          let :joining_source do
            :relateds
          end

          let :association_name do
            :posts
          end

          let :associated_as do
            :comments
          end
        end
      end

      describe "aliased association" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_many :unmentionables, through: :relateds, source: :comments

              query do
                order { id.asc }
              end
            end

            source :comments do
              query do
                order { id.asc }
              end
            end

            source :relateds do
              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_has_many_through do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :joining_source do
            :relateds
          end

          let :association_name do
            :unmentionables
          end

          let :associated_as do
            :posts
          end
        end
      end

      describe "aliased name for the reciprocal association" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_many :comments, through: :relateds, as: :owners

              query do
                order { id.asc }
              end
            end

            source :comments do
              query do
                order { id.asc }
              end
            end

            source :relateds do
              query do
                order { id.asc }
              end
            end
          end
        end

        describe "reciprocal association" do
          it_behaves_like :source_associations_has_many_through do
            let :target_source do
              :comments
            end

            let :associated_source do
              :posts
            end

            let :joining_source do
              :relateds
            end

            let :association_name do
              :owners
            end

            let :associated_as do
              :comments
            end
          end
        end
      end

      describe "association with a specific query" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_many :comments, through: :relateds, query: :id_gt_one

              query do
                order { id.asc }
              end
            end

            source :comments do
              query do
                order { id.asc }
              end

              def id_gt_one
                where { id > 1 }
              end
            end

            source :relateds do
              query do
                order { id.asc }
              end
            end
          end
        end

        before do
          data.posts.create(
            comments: data.comments.create
          )

          data.posts.create(
            comments: data.comments.create
          )
        end

        it "applies the query to the included source" do
          posts = data.posts.including(:comments)
          expect(posts[0].comments.count).to be(0)
          expect(posts[1].comments.count).to be(1)
        end
      end

      describe "edge cases around definition" do
        context "through association is specified as singular" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                has_many :comments, through: :related
              end

              source :comments do
              end

              source :relateds do
              end
            end
          end

          it "treats it as plural" do
            data.posts.create(comments: data.comments.create)
            expect(data.posts.including(:comments).one.comments.first).to_not be(nil)
          end
        end

        context "through association source does not exist" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                has_many :comments, through: :relateds
              end

              source :comments do
              end
            end
          end

          it "raises an error that puts the app in rescue mode" do
            expect(Pakyow.app(:test).call({})[2].join).to include("Unknown source `relateds` for association: posts has_many comments")
          end
        end
      end

      describe "association with the source having a custom primary key" do
        let :app_definition do
          slugs = 100.times.to_a.map(&:to_s)

          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts, primary_id: false do
              primary_key :slug

              attribute :slug, :string, default: -> {
                # Ensures the ids are in a predictable sort order.
                #
                slugs.shift
              }

              has_many :comments, through: :relateds

              query do
                order { slug.asc }
              end
            end

            source :comments do
              query do
                order { id.asc }
              end
            end

            source :relateds do
              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_has_many_through do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :joining_source do
            :relateds
          end

          let :association_name do
            :comments
          end

          let :associated_as do
            :posts
          end
        end

        describe "reciprocal association" do
          it_behaves_like :source_associations_has_many_through do
            let :target_source do
              :comments
            end

            let :associated_source do
              :posts
            end

            let :joining_source do
              :relateds
            end

            let :association_name do
              :posts
            end

            let :associated_as do
              :comments
            end
          end
        end
      end

      describe "association with the joining source having a custom primary key" do
        let :app_definition do
          slugs = 100.times.to_a.map(&:to_s)

          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_many :comments, through: :relateds

              query do
                order { id.asc }
              end
            end

            source :comments do
              query do
                order { id.asc }
              end
            end

            source :relateds, primary_id: false do
              primary_key :slug

              attribute :slug, :string, default: -> {
                # Ensures the ids are in a predictable sort order.
                #
                slugs.shift
              }

              query do
                order { slug.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_has_many_through do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :joining_source do
            :relateds
          end

          let :association_name do
            :comments
          end

          let :associated_as do
            :posts
          end
        end

        describe "reciprocal association" do
          it_behaves_like :source_associations_has_many_through do
            let :target_source do
              :comments
            end

            let :associated_source do
              :posts
            end

            let :joining_source do
              :relateds
            end

            let :association_name do
              :posts
            end

            let :associated_as do
              :comments
            end
          end
        end
      end
    end

    describe "many_to_many" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            has_many :comments

            query do
              order { id.asc }
            end
          end

          source :comments do
            has_many :posts

            query do
              order { id.asc }
            end
          end
        end
      end

      it_behaves_like :source_associations_many_to_many do
        let :target_source do
          :posts
        end

        let :associated_source do
          :comments
        end

        let :association_name do
          :comments
        end

        let :associated_as do
          :posts
        end
      end

      describe "dependent: delete" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_many :comments, dependent: :delete

              query do
                order { id.asc }
              end
            end

            source :comments do
              has_many :posts, dependent: :delete

              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_many_to_many, dependents: :delete do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :comments
          end

          let :associated_as do
            :posts
          end
        end
      end

      describe "dependent: nullify" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_many :comments, dependent: :nullify

              query do
                order { id.asc }
              end
            end

            source :comments do
              has_many :posts, dependent: :nullify

              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_many_to_many, dependents: :nullify do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :comments
          end

          let :associated_as do
            :posts
          end
        end
      end

      describe "reciprocal association" do
        it_behaves_like :source_associations_many_to_many do
          let :target_source do
            :comments
          end

          let :associated_source do
            :posts
          end

          let :association_name do
            :posts
          end

          let :associated_as do
            :comments
          end
        end
      end

      describe "aliased association" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_many :unmentionables, source: :comments

              query do
                order { id.asc }
              end
            end

            source :comments do
              has_many :posts, as: :unmentionables

              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_many_to_many do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :unmentionables
          end

          let :associated_as do
            :posts
          end
        end
      end

      describe "aliased name for the reciprocal association" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_many :comments, as: :owners

              query do
                order { id.asc }
              end
            end

            source :comments do
              has_many :owners, source: :posts

              query do
                order { id.asc }
              end
            end
          end
        end

        describe "reciprocal association" do
          it_behaves_like :source_associations_many_to_many do
            let :target_source do
              :comments
            end

            let :associated_source do
              :posts
            end

            let :association_name do
              :owners
            end

            let :associated_as do
              :comments
            end
          end
        end
      end

      describe "association with a specific query" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              has_many :comments, query: :id_gt_one

              query do
                order { id.asc }
              end
            end

            source :comments do
              has_many :posts

              query do
                order { id.asc }
              end

              def id_gt_one
                where { id > 1 }
              end
            end
          end
        end

        before do
          data.posts.create(
            comments: data.comments.create
          )

          data.posts.create(
            comments: data.comments.create
          )
        end

        it "applies the query to the included source" do
          posts = data.posts.including(:comments)
          expect(posts[0].comments.count).to be(0)
          expect(posts[1].comments.count).to be(1)
        end
      end

      describe "association with the source having a custom primary key" do
        let :app_definition do
          slugs = 100.times.to_a.map(&:to_s)

          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts, primary_id: false do
              primary_key :slug

              attribute :slug, :string, default: -> {
                # Ensures the ids are in a predictable sort order.
                #
                slugs.shift
              }

              has_many :comments

              query do
                order { slug.asc }
              end
            end

            source :comments do
              has_many :posts

              query do
                order { id.asc }
              end
            end
          end
        end

        it_behaves_like :source_associations_many_to_many do
          let :target_source do
            :posts
          end

          let :associated_source do
            :comments
          end

          let :association_name do
            :comments
          end

          let :associated_as do
            :posts
          end
        end

        describe "reciprocal association" do
          it_behaves_like :source_associations_many_to_many do
            let :target_source do
              :comments
            end

            let :associated_source do
              :posts
            end

            let :association_name do
              :posts
            end

            let :associated_as do
              :comments
            end
          end
        end
      end
    end
  end
end
