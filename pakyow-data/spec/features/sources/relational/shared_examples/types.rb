RSpec.shared_examples :source_types do
  describe "source types" do
    before do
      local_connection_type, local_connection_string = connection_type, connection_string

      Pakyow.after :configure do
        config.data.connections.public_send(local_connection_type)[:default] = local_connection_string
      end
    end

    include_context "app"

    context "defining a primary key" do
      context "primary key attribute is defined" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts, primary_id: false, timestamps: false do
              primary_key :foo
              attribute :foo, :integer
            end
          end
        end

        it "behaves as a primary key" do
          data.posts.create(foo: 1)

          expect {
            data.posts.create(foo: 1)
          }.to raise_error(Pakyow::Data::UniqueViolation)

          expect(data.posts.count).to eq(1)
        end

        it "auto increments" do
          expect(data.posts.create.one.foo).to eq(1)
          expect(data.posts.create.one.foo).to eq(2)
        end
      end

      context "primary key attribute is undefined" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts, primary_id: false, timestamps: false do
              attribute :foo, :integer
            end
          end
        end

        it "does not behave as a primary key" do
          data.posts.create(foo: 1)

          expect {
            data.posts.create(foo: 1)
          }.to_not raise_error(Pakyow::Data::UniqueViolation)

          expect(data.posts.count).to eq(2)
        end
      end

      context "primary key is not an integer" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts, primary_id: false, timestamps: false do
              primary_key :foo
              attribute :foo, :string
            end
          end
        end

        it "behaves as a primary key" do
          data.posts.create(foo: "bar")

          expect {
            data.posts.create(foo: "bar")
          }.to raise_error(Pakyow::Data::UniqueViolation)

          expect(data.posts.count).to eq(1)
        end
      end
    end

    context "defining a primary id key" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts, primary_id: false, timestamps: false do
            primary_id
          end
        end
      end

      it "behaves as a primary key" do
        data.posts.create
        data.posts.create

        expect(data.posts.count).to eq(2)

        expect(data.posts.to_a[0][:id]).to eq(1)
        expect(data.posts.to_a[1][:id]).to eq(2)

        expect {
          data.posts.create(id: 1)
        }.to raise_error(Pakyow::Data::UniqueViolation)
      end
    end

    context "defining a primary uuid key" do
      it "will be supported in the future"
    end

    context "defining timestamp fields" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts, primary_id: false, timestamps: false do
            primary_id
            timestamps
            attribute :title, :string
          end
        end
      end

      it "defines a created_at field" do
        expect(data.posts.create.one.to_h.keys).to include(:created_at)
      end

      it "defines an updated_at field" do
        expect(data.posts.create.one.to_h.keys).to include(:updated_at)
      end

      context "record is created" do
        it "sets the created_at value" do
          expect(data.posts.create.one[:created_at]).to be_instance_of(Time)
        end

        it "sets the updated_at value" do
          expect(data.posts.create.one[:updated_at]).to be_instance_of(Time)
        end
      end

      context "record is updated" do
        it "updates the updated_at value" do
          post = data.posts.create.one; sleep 1
          data.posts.update(title: "foo")
          expect(data.posts.one[:updated_at]).to be > post[:updated_at]
        end

        it "does not update the created_at value" do
          post = data.posts.create.one
          data.posts.update(title: "foo")
          expect(data.posts.one[:created_at]).to eq(post[:created_at])
        end
      end

      context "timestamp fields are specified" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts, primary_id: false, timestamps: false do
              primary_id
              timestamps create: :custom_created_at, update: :custom_updated_at
              attribute :title, :string
              attribute :custom_created_at, :datetime
              attribute :custom_updated_at, :datetime
            end
          end
        end

        it "uses the specified fields" do
          post = data.posts.create.one
          expect(post[:custom_created_at]).to be_instance_of(Time)
          expect(post[:custom_updated_at]).to be_instance_of(Time)
        end
      end
    end

    context "defining an attribute" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts, primary_id: false, timestamps: false do
            primary_id
            attribute :attr, :string
          end
        end
      end

      it "can be null" do
        expect(data.posts.create.one[:attr]).to be(nil)
      end

      it "does not have a default value" do
        expect(data.posts.create.one[:attr]).to be(nil)
      end

      context "with a default value" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts, primary_id: false, timestamps: false do
              primary_id
              attribute :attr1, :string, default: "foo"
              attribute :attr2, :string
            end
          end
        end

        it "uses the default when creating and a value is not provided" do
          expect(data.posts.create(attr2: "baz").one[:attr1]).to eq("foo")
        end

        it "does not use the default when creating and a value is provided" do
          expect(data.posts.create(attr1: "bar").one[:attr1]).to eq("bar")
        end

        it "does not use the default when updating and a value is not provided" do
          post = data.posts.create(attr1: "bar").one
          expect(post[:attr1]).to eq("bar")
          expect(data.posts.by_id(post.id).update(attr2: "baz").one[:attr1]).to eq("bar")
        end
      end

      context "with a not-null restriction" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts, primary_id: false, timestamps: false do
              primary_id
              attribute :attr, :string, required: true
            end
          end
        end

        it "cannot be null" do
          expect {
            data.posts.create(attr: nil)
          }.to raise_error(Pakyow::Data::NotNullViolation)
        end

        it "allows a value" do
          expect(data.posts.create(attr: "foo").one[:attr]).to eq("foo")
        end
      end

      describe "types" do
        context "type is string" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts, primary_id: false, timestamps: false do
                primary_id
                attribute :attr, :string
              end
            end
          end

          it "defines the attribute" do
            expect(data.posts.create(attr: "foo").one[:attr]).to eq("foo")
          end
        end

        context "type is boolean" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts, primary_id: false, timestamps: false do
                primary_id
                attribute :attr, :boolean
              end
            end
          end

          it "defines the attribute" do
            expect(data.posts.create(attr: true).one[:attr]).to eq(true)
          end
        end

        context "type is date" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts, primary_id: false, timestamps: false do
                primary_id
                attribute :attr, :date
              end
            end
          end

          it "defines the attribute" do
            expect(data.posts.create(attr: Date.today).one[:attr]).to eq(Date.today)
          end
        end

        context "type is time" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts, primary_id: false, timestamps: false do
                primary_id
                attribute :attr, :time
              end
            end
          end

          it "defines the attribute" do
            time = Time.now
            expect(data.posts.create(attr: time).one[:attr].to_i).to eq(time.to_i)
          end
        end

        context "type is datetime" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts, primary_id: false, timestamps: false do
                primary_id
                attribute :attr, :datetime
              end
            end
          end

          it "defines the attribute" do
            datetime = Time.now
            expect(data.posts.create(attr: datetime).one[:attr].to_i).to eq(datetime.to_i)
          end
        end

        context "type is integer" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts, primary_id: false, timestamps: false do
                primary_id
                attribute :attr, :integer
              end
            end
          end

          it "defines the attribute" do
            expect(data.posts.create(attr: 1).one[:attr]).to eq(1)
          end
        end

        context "type is float" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts, primary_id: false, timestamps: false do
                primary_id
                attribute :attr, :float
              end
            end
          end

          it "defines the attribute" do
            expect(data.posts.create(attr: 1.1).one[:attr]).to eq(1.1)
          end
        end

        context "type is decimal" do
          before do
            require "bigdecimal"
          end

          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts, primary_id: false, timestamps: false do
                primary_id
                attribute :attr, :decimal
              end
            end
          end

          it "defines the attribute" do
            expect(data.posts.create(attr: BigDecimal(1.12, 3)).one[:attr]).to eq(1.12)
          end

          context "size is defined" do
            let :app_definition do
              Proc.new do
                instance_exec(&$data_app_boilerplate)

                source :posts, primary_id: false, timestamps: false do
                  primary_id
                  attribute :attr, :decimal, size: [10, 1]
                end
              end
            end

            it "defines the attribute with the defined size" do
              expect(data.posts.create(attr: BigDecimal(1.16, 2)).one[:attr]).to eq(1.2)
            end
          end
        end
      end
    end
  end
end
