RSpec.shared_examples :source_schema do
  describe "source schema" do
    before do
      Pakyow.config.data.connections.public_send(connection_type)[:default] = connection_string
    end

    include_context "testable app"

    let :data do
      Pakyow.apps.first.data
    end

    describe "table name" do
      it "defaults to the source name"

      context "custom table name specified" do
        it "needs to be defined"
      end
    end

    context "defining a primary key" do
      context "primary key attribute is defined" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_key :foo
              attribute :foo, :integer
            end
          end
        end

        it "defines the primary key" do
          data.posts.create(foo: 1)

          expect {
            data.posts.create(foo: 1)
            pp data.posts.to_a
          }.to raise_error(Pakyow::Data::UniqueConstraintError)

          expect(data.posts.count).to eq(1)
        end
      end

      context "primary key attribute is undefined" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
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

          source :posts do
            primary_id
          end
        end
      end

      it "defines the primary key" do
        data.posts.create({})
        data.posts.create({})

        expect(data.posts.count).to eq(2)

        expect(data.posts.to_a[0][:id]).to eq(1)
        expect(data.posts.to_a[1][:id]).to eq(2)

        expect {
          data.posts.create(id: 1)
        }.to raise_error(Pakyow::Data::UniqueConstraintError)
      end
    end

    context "defining a primary uuid key" do
      it "needs to be defined"
    end

    context "defining timestamp fields" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            timestamps
            attribute :title, :string
          end
        end
      end

      it "defines a created_at field" do
        expect(data.posts.create({}).one.to_h.keys).to include(:created_at)
      end

      it "defines an updated_at field" do
        expect(data.posts.create({}).one.to_h.keys).to include(:updated_at)
      end

      context "record is created" do
        it "sets the created_at value" do
          expect(data.posts.create({}).one[:created_at]).to be_instance_of(Time)
        end

        it "sets the updated_at value" do
          expect(data.posts.create({}).one[:updated_at]).to be_instance_of(Time)
        end
      end

      context "record is updated" do
        it "updates the updated_at value" do
          post = data.posts.create({}).one; sleep 1
          data.posts.update(title: "foo")
          expect(data.posts.one[:updated_at]).to be > post[:updated_at]
        end

        it "does not update the created_at value" do
          post = data.posts.create({}).one
          data.posts.update(title: "foo")
          expect(data.posts.one[:created_at]).to eq(post[:created_at])
        end
      end

      context "timestamp fields are specified" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id
              timestamps create: :custom_created_at, update: :custom_updated_at
              attribute :title, :string
              attribute :custom_created_at, :datetime
              attribute :custom_updated_at, :datetime
            end
          end
        end

        it "uses the specified fields" do
          post = data.posts.create({}).one
          expect(post[:custom_created_at]).to be_instance_of(Time)
          expect(post[:custom_updated_at]).to be_instance_of(Time)
        end
      end
    end

    context "defining an attribute" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            attribute :attr, :string
          end
        end
      end

      it "can be null" do
        expect(data.posts.create({}).one[:attr]).to be(nil)
      end

      it "does not have a default value" do
        expect(data.posts.create({}).one[:attr]).to be(nil)
      end

      xcontext "with a default value" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id
              attribute :attr, :string, default: "foo"
            end
          end
        end

        it "uses the default" do
          expect(data.posts.create({}).one[:attr]).to eq("foo")
        end
      end

      xcontext "with a not-null restriction" do
        let :app_definition do
          Proc.new do
            instance_exec(&$data_app_boilerplate)

            source :posts do
              primary_id
              attribute :attr, :string, nullable: false
            end
          end
        end

        it "cannot be null" do
          expect {
            data.posts.create(attr: nil)
          }.to raise_error { |error|
            expect([ROM::SQL::NotNullConstraintError, ROM::SQL::DatabaseError]).to include(error.class)
          }
        end

        it "allows a value" do
          expect(data.posts.create(attr: "foo")[:attr]).to eq("foo")
        end
      end

      describe "types" do
        context "type is string" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
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

              source :posts do
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

              source :posts do
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

              source :posts do
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

              source :posts do
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

              source :posts do
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

              source :posts do
                primary_id
                attribute :attr, :float
              end
            end
          end

          it "defines the attribute" do
            expect(data.posts.create(attr: 1.1).one[:attr]).to eq(1.1)
          end
        end

        xcontext "type is decimal" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                primary_id
                attribute :attr, :decimal
              end
            end
          end

          it "defines the attribute" do
            expect(data.posts.create(attr: 1.1).one[:attr]).to eq(1.1)
          end
        end

        xcontext "type is blob" do
          let :app_definition do
            Proc.new do
              instance_exec(&$data_app_boilerplate)

              source :posts do
                primary_id
                attribute :attr, :blob
              end
            end
          end

          it "defines the attribute" do
            random_bytes = Random.new.bytes(10)
            expect(data.posts.create(attr: random_bytes).one[:attr]).to eq(random_bytes)
          end
        end
      end
    end
  end
end
