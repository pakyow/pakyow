RSpec.shared_examples :model_schema do
  describe "model schema" do
    before do
      Pakyow.config.connections.sql[:default] = connection_string
    end

    include_context "testable app"

    let :data do
      Pakyow.apps.first.data
    end

    describe "table name" do
      it "defaults to the model name"

      context "custom table name specified" do
        it "needs to be defined"
      end
    end

    context "defining a primary key" do
      context "primary key attribute is defined" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            model :post do
              primary_key :foo
              attribute :foo, :integer
            end
          end
        end

        it "defines the primary key" do
          data.posts.create(foo: 1)

          expect {
            data.posts.create(foo: 1)
          }.to raise_error(ROM::SQL::UniqueConstraintError)

          expect(data.posts.count).to eq(1)
        end
      end

      context "primary key attribute is undefined" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            model :post do
              attribute :foo, :integer
            end
          end
        end

        it "does not define the primary key" do
          data.posts.create(foo: 1)

          expect {
            data.posts.create(foo: 1)
          }.to_not raise_error

          expect(data.posts.count).to eq(2)
        end
      end
    end

    context "defining a primary id key" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          model :post do
            primary_id
          end
        end
      end

      it "defines the primary key" do
        data.posts.create({})
        data.posts.create({})

        expect(data.posts.count).to eq(2)

        expect(data.posts.all[0][:id]).to eq(1)
        expect(data.posts.all[1][:id]).to eq(2)

        expect {
          data.posts.create(id: 1)
        }.to raise_error(ROM::SQL::UniqueConstraintError)
      end
    end

    context "defining a primary uuid key" do
      it "needs to be defined"
    end

    context "defining timestamp fields" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          model :post do
            primary_id
            timestamps
            attribute :title, :string
          end
        end
      end

      it "defines a created_at field" do
        expect(data.posts.create({}).keys).to include(:created_at)
      end

      it "defines an updated_at field" do
        expect(data.posts.create({}).keys).to include(:updated_at)
      end

      context "record is created" do
        it "sets the created_at value" do
          expect(data.posts.create({})[:created_at]).to be_instance_of(Time)
        end

        it "sets the updated_at value" do
          expect(data.posts.create({})[:updated_at]).to be_instance_of(Time)
        end
      end

      context "record is updated" do
        it "updates the updated_at value" do
          post = data.posts.create({}); sleep 1
          data.posts.update(title: "foo")
          expect(data.posts.first[:updated_at]).to be > post[:updated_at]
        end

        it "does not update the created_at value" do
          post = data.posts.create({})
          data.posts.update(title: "foo")
          expect(data.posts.first[:created_at]).to eq(post[:created_at])
        end
      end

      context "timestamp fields are specified" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            model :post do
              primary_id
              timestamps create: :custom_created_at, update: :custom_updated_at
              attribute :title, :string
              attribute :custom_created_at, :datetime
              attribute :custom_updated_at, :datetime
            end
          end
        end

        it "uses the specified fields" do
          post = data.posts.create({})
          expect(post[:custom_created_at]).to be_instance_of(Time)
          expect(post[:custom_updated_at]).to be_instance_of(Time)
        end
      end
    end

    context "defining an attribute" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          model :post do
            primary_id
            attribute :attr, :string
          end
        end
      end

      it "can be null" do
        expect(data.posts.create({})[:attr]).to be(nil)
      end

      it "does not have a default value" do
        expect(data.posts.create({})[:attr]).to be(nil)
      end

      context "with a default value" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            model :post do
              primary_id
              attribute :attr, :string, default: "foo"
            end
          end
        end

        it "uses the default" do
          expect(data.posts.create({})[:attr]).to eq("foo")
        end
      end

      context "with a not-null restriction" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            model :post do
              primary_id
              attribute :attr, :string, nullable: false
            end
          end
        end

        it "cannot be null" do
          expect {
            data.posts.create({})[:attr]
          }.to raise_error { |error|
            expect([ROM::SQL::NotNullConstraintError, ROM::SQL::DatabaseError]).to include(error.class)
          }
        end

        it "allows a value" do
          expect(data.posts.create(attr: "foo")[:attr]).to eq("foo")
        end
      end

      describe "types" do
        context "type is serial" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              model :post do
                primary_id
                attribute :attr, :serial
              end
            end
          end

          it "defines the attribute" do
            expect(data.posts.create(attr: 1)[:attr]).to eq(1)
          end
        end

        context "type is string" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              model :post do
                primary_id
                attribute :attr, :string
              end
            end
          end

          it "defines the attribute" do
            expect(data.posts.create(attr: "foo")[:attr]).to eq("foo")
          end
        end

        context "type is boolean" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              model :post do
                primary_id
                attribute :attr, :boolean
              end
            end
          end

          it "defines the attribute" do
            expect(data.posts.create(attr: true)[:attr]).to eq(true)
          end
        end

        context "type is date" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              model :post do
                primary_id
                attribute :attr, :date
              end
            end
          end

          it "defines the attribute" do
            expect(data.posts.create(attr: Date.today)[:attr]).to eq(Date.today)
          end
        end

        context "type is time" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              model :post do
                primary_id
                attribute :attr, :time
              end
            end
          end

          it "defines the attribute" do
            time = Time.now
            expect(data.posts.create(attr: time)[:attr].to_i).to eq(time.to_i)
          end
        end

        context "type is datetime" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              model :post do
                primary_id
                attribute :attr, :datetime
              end
            end
          end

          it "defines the attribute" do
            datetime = Time.now
            expect(data.posts.create(attr: datetime)[:attr].to_i).to eq(datetime.to_i)
          end
        end

        context "type is integer" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              model :post do
                primary_id
                attribute :attr, :integer
              end
            end
          end

          it "defines the attribute" do
            expect(data.posts.create(attr: 1)[:attr]).to eq(1)
          end
        end

        context "type is float" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              model :post do
                primary_id
                attribute :attr, :float
              end
            end
          end

          it "defines the attribute" do
            expect(data.posts.create(attr: 1.1)[:attr]).to eq(1.1)
          end
        end

        context "type is decimal" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              model :post do
                primary_id
                attribute :attr, :decimal
              end
            end
          end

          it "defines the attribute" do
            expect(data.posts.create(attr: 1.1)[:attr]).to eq(1.1)
          end
        end

        xcontext "type is blob" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              model :post do
                primary_id
                attribute :attr, :blob
              end
            end
          end

          it "defines the attribute" do
            random_bytes = Random.new.bytes(10)
            expect(data.posts.create(attr: random_bytes)[:attr]).to eq(random_bytes)
          end
        end
      end
    end

    describe "inferring the schema" do
      it "needs to be defined"
    end
  end
end
