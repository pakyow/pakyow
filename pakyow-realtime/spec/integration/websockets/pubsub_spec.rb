require_relative '../support/int_helper'

Pakyow::App.define do
  routes do
    post 'sub' do
      socket.subscribe(params[:channel])
    end

    post 'pub' do
      socket.push({ msg: params[:msg] }, params[:channel])
    end
  end
end

describe 'pub/sub with SimpleRegistry' do
  let :registry do
    Pakyow::Realtime::SimpleRegistry.instance
  end

  include_examples :pubsub
end

if redis_available?
  describe 'pub/sub with RedisRegistry' do
    let :registry do
      Pakyow::Realtime::RedisRegistry.instance
    end

    include_examples :pubsub
  end
end
