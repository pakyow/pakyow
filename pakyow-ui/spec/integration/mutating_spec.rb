require_relative 'support/int_helper'

describe 'performing mutations' do
  before do
    class Post
      def self.create(params)
        params[:created] = true
        params
      end

      def self.all
        []
      end

      def self.find(id)
        { id: id }
      end
    end

    Pakyow::App.mutable :post do
      model Post

      action :create do |object|
        Post.create(object)
      end

      query :all do
        Post.all
      end

      query :find do |id|
        Post.find(id.to_i)
      end
    end

    Pakyow::App.mutators :post do
      mutator :list do |view, data|
        PerformedMutations.perform(:list, view, data)
      end

      mutator :present do |view, data|
        PerformedMutations.perform(:present, view, data)
      end
    end

    Pakyow::App.routes :post do
      get '/posts' do
        presenter.path = '/posts'
        view.scope(:post).mutate(:list, with: data(:post).all)
      end

      get '/posts/show' do
        presenter.path = '/posts'
        view.scope(:post)[0].mutate(:present, with: data(:post).find(1))
      end

      get '/posts/subscribe' do
        presenter.path = '/posts'
        view.scope(:post).mutate(:list, with: data(:post).all).subscribe
      end

      get '/posts/:post_id/subscribe' do
        presenter.path = '/posts'
        view.scope(:post).mutate(:present, with: data(:post).find(params[:post_id])).subscribe
      end

      get '/posts/mutate' do
        data(:post).create({ id: 2 })
      end
    end

    Pakyow::App.stage(:test)
  end

  after do
    PerformedMutations.reset
  end

  let :performed do
    PerformedMutations.performed
  end

  describe 'when the data is from mutables' do
    context 'and the mutation exists' do
      context 'and mutating a collection' do
        it 'calls the mutation for scope with name' do
          Pakyow.app.process(Rack::MockRequest.env_for('/posts'))
          expect(performed.keys).to include :list

          data = performed[:list][:data]
          expect(data).to eq(Post.all)
        end
      end

      context 'and mutating a view' do
        it 'calls the mutation for scope with name' do
          Pakyow.app.process(Rack::MockRequest.env_for('/posts/show'))
          expect(performed.keys).to include :present

          data = performed[:present][:data]
          expect(data).to eq(Post.find(1))
        end
      end
    end

    context 'and the mutation is subscribed' do
      before do
        Pakyow.app.process(Rack::MockRequest.env_for('/posts/subscribe'))
        Pakyow.app.process(Rack::MockRequest.env_for("/posts/#{post_id}/subscribe"))
        PerformedMutations.reset
      end

      let :post_id do
        1
      end

      it 'calls the mutation again when a related mutation occurs' do
        Pakyow.app.process(Rack::MockRequest.env_for('/posts/mutate'))

        data = performed[:list][:data]
        expect(data).to eq(Post.all)

        data = performed[:present][:data]
        expect(data).to eq(Post.find(post_id))
      end

      #TODO make sure we test that it doesn't call the mutation again
      # if the mutation wasn't subscribed in the first place

      #TODO make sure only mutators for the mutated scope are called again
    end
  end
end
