RSpec.shared_examples :source_associations_dependent do
  describe "deleting an object that contains dependent objects" do
    before do
      data.comments.create(post: data.posts.create({}).one)
    end

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

    shared_examples :raise do
      it "raises an error" do
        expect {
          data.posts.delete
        }.to raise_error(Pakyow::Data::ConstraintViolation)
      end

      it "does not delete the data" do
        begin
          data.posts.delete
        rescue
        end

        expect(data.posts.count).to eq(1)
      end

      describe "error message" do
        context "one dependent" do
          it "is worded properly" do
            expect {
              data.posts.delete
            }.to raise_error do |error|
              expect(error.to_s).to eq(
                "Cannot delete posts because of 1 dependent comment"
              )
            end
          end
        end

        context "multiple dependents" do
          before do
            data.comments.create(post: data.posts.one)
          end

          it "is worded properly" do
            expect {
              data.posts.delete
            }.to raise_error do |error|
              expect(error.to_s).to eq(
                "Cannot delete posts because of 2 dependent comments"
              )
            end
          end
        end
      end
    end

    include_examples :raise

    context "dependent is set to `raise`" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            has_many :comments, dependent: :raise
          end

          source :comments do
            primary_id
          end
        end
      end

      include_examples :raise
    end

    context "dependent is set to `delete`" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            has_many :comments, dependent: :delete
          end

          source :comments do
            primary_id
          end
        end
      end

      it "deletes the data" do
        data.posts.delete
        expect(data.posts.count).to eq(0)
      end

      it "deletes the dependent data" do
        data.posts.delete
        expect(data.comments.count).to eq(0)
      end

      it "does not delete non-dependent data" do
        data.comments.create(post: data.posts.create({}).one)
        data.posts.by_id(1).delete
        expect(data.comments.count).to eq(1)
      end

      context "dependent data errors on delete" do
        before do
          Test::Sources::Comments.class_eval do
            def delete
              raise RuntimeError
            end
          end
        end

        it "does not delete the data" do
          begin
            data.posts.delete
          rescue
          end

          expect(data.posts.count).to eq(1)
        end

        it "does not delete the dependent data" do
          begin
            data.posts.delete
          rescue
          end

          expect(data.comments.count).to eq(1)
        end
      end
    end

    context "dependent is set to `nullify`" do
      let :app_definition do
        Proc.new do
          instance_exec(&$data_app_boilerplate)

          source :posts do
            primary_id
            has_many :comments, dependent: :nullify
          end

          source :comments do
            primary_id
          end
        end
      end

      it "deletes the data" do
        data.posts.delete
        expect(data.posts.count).to eq(0)
      end

      it "nullifies the related column on the dependent data" do
        data.posts.delete
        expect(data.comments.count).to eq(1)
        expect(data.comments.one[:post_id]).to be(nil)
      end

      it "does not nullify non-dependent data" do
        data.comments.create(post: data.posts.create({}).one)

        data.posts.by_id(1).delete
        expect(data.comments.count).to eq(2)

        comments = data.comments.to_a.sort { |a, b|
          a[:id] <=> b[:id]
        }

        expect(comments[0][:post_id]).to be(nil)
        expect(comments[1][:post_id]).to_not be(nil)
      end

      context "dependent data errors on delete" do
        before do
          Test::Sources::Comments.class_eval do
            def update(*)
              raise RuntimeError
            end
          end
        end

        it "does not delete the data" do
          begin
            data.posts.delete
          rescue
          end

          expect(data.posts.count).to eq(1)
        end

        it "does not nullify the dependent data" do
          begin
            data.posts.delete
          rescue
          end

          expect(data.comments.count).to eq(1)
          expect(data.comments.to_a[0][:post_id]).not_to be(nil)
        end
      end
    end
  end

  describe "deleting an object that does not contain dependent objects" do
    before do
      data.posts.create({})
    end

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

    it "does not raise an error" do
      data.posts.delete
    end

    it "deletes the data" do
      data.posts.delete
      expect(data.posts.count).to eq(0)
    end
  end
end
