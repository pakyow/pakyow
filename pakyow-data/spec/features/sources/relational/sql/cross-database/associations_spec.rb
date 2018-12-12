require_relative "../../shared_examples/associations"

RSpec.describe "cross connection associations" do
  let :connection_type do
    :sql
  end

  let :default_connection_string do
    "postgres://localhost/pakyow-test"
  end

  let :other_connection_string do
    "postgres://localhost/pakyow-other"
  end

  before :all do
    unless system("psql -lqt | cut -d \\| -f 1 | grep -qw pakyow-test")
      system "createdb pakyow-test > /dev/null", out: File::NULL, err: File::NULL
      system "psql pakyow-test -c 'CREATE SCHEMA public' > /dev/null", out: File::NULL, err: File::NULL
    end

    unless system("psql -lqt | cut -d \\| -f 1 | grep -qw pakyow-other")
      system "createdb pakyow-other > /dev/null", out: File::NULL, err: File::NULL
      system "psql pakyow-other -c 'CREATE SCHEMA public' > /dev/null", out: File::NULL, err: File::NULL
    end
  end

  before do
    local_connection_type, local_default_connection_string, local_other_connection_string = connection_type, default_connection_string, other_connection_string

    Pakyow.after :configure do
      config.data.connections.public_send(local_connection_type)[:default] = local_default_connection_string
      config.data.connections.public_send(local_connection_type)[:other] = local_other_connection_string
    end
  end

  include_context "testable app"

  describe "belongs_to" do
    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts, connection: :default do
          primary_id

          query do
            order { id.asc }
          end
        end

        source :comments, connection: :other do
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

  describe "has_one" do
    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts, connection: :default do
          primary_id
          has_one :comment

          query do
            order { id.asc }
          end
        end

        source :comments, connection: :other do
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
  end

  describe "has_many" do
    let :app_definition do
      Proc.new do
        instance_exec(&$data_app_boilerplate)

        source :posts, connection: :default do
          primary_id
          has_many :comments

          query do
            order { id.asc }
          end
        end

        source :comments, connection: :other do
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
  end
end
