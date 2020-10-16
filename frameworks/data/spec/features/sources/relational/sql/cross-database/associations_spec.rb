require_relative "../../shared_examples/associations"

RSpec.describe "cross connection associations" do
  shared_examples "cross database associations" do
    before do
      context = self

      Pakyow.after "configure" do
        config.data.connections.public_send(context.connection_type)[:default] = context.connection_string_default
        config.data.connections.public_send(context.connection_type)[:two] = context.connection_string_two
        config.data.connections.public_send(context.connection_type)[:three] = context.connection_string_three
      end
    end

    include_context "app"

    describe "belongs_to" do
      let :app_def do
        Proc.new do
          source :posts, connection: :default do
            query do
              order(id: :asc)
            end
          end

          source :comments, connection: :two do
            belongs_to :post

            query do
              order(id: :asc)
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

    describe "has_one" do
      let :app_def do
        Proc.new do
          source :posts, connection: :default do
            has_one :comment

            query do
              order(id: :asc)
            end
          end

          source :comments, connection: :two do
            query do
              order(id: :asc)
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
    end

    describe "has_one :through" do
      let :app_def do
        Proc.new do
          source :posts, connection: :default do
            has_one :comment, through: :related

            query do
              order(id: :asc)
            end
          end

          source :comments, connection: :two do
            query do
              order(id: :asc)
            end
          end

          source :relateds, connection: :three do
            query do
              order(id: :asc)
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
    end

    describe "has_many" do
      let :app_def do
        Proc.new do
          source :posts, connection: :default do
            has_many :comments

            query do
              order(id: :asc)
            end
          end

          source :comments, connection: :two do
            query do
              order(id: :asc)
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
    end

    describe "has_many :through" do
      let :app_def do
        Proc.new do
          source :posts, connection: :default do
            has_many :comments, through: :relateds

            query do
              order(id: :asc)
            end
          end

          source :comments, connection: :two do
            query do
              order(id: :asc)
            end
          end

          source :relateds, connection: :three do
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
    end
  end

  context "connections are for the same database type" do
    let :connection_type do
      :sql
    end

    let :connection_string_default do
      ENV["DATABASE_URL__POSTGRES"]
    end

    let :connection_string_two do
      ENV["DATABASE_URL__POSTGRES_2"]
    end

    let :connection_string_three do
      ENV["DATABASE_URL__POSTGRES_3"]
    end

    include_examples "cross database associations"
  end

  context "connections are for different database types" do
    let :connection_type do
      :sql
    end

    let :connection_string_default do
      ENV["DATABASE_URL__POSTGRES"]
    end

    let :connection_string_two do
      ENV["DATABASE_URL__MYSQL"]
    end

    let :connection_string_three do
      "sqlite://#{File.expand_path("../test.db", __FILE__)}"
    end

    include_examples "cross database associations"
  end
end
