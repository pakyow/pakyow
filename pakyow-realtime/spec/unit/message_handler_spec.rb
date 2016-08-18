require 'spec_helper'
require 'pakyow/realtime/message_handler'

describe Pakyow::Realtime do
  describe '::handler' do
    let :name do
      :handler
    end

    let :block do
      -> {}
    end

    it 'is a convenience method for MessageHandler::register' do
      expect(Pakyow::Realtime::MessageHandler).to receive(:register).with(name)
      Pakyow::Realtime.handler(name, &block)
    end
  end
end

describe Pakyow::Realtime::MessageHandler do
  describe '::handle' do
    let :id do
      (rand * 100).to_i
    end

    let :name do
      :handler
    end

    let :message do
      {
        'id' => id,
        'action' => name
      }
    end

    let :session do
      {}
    end

    let :block do
      -> (message, session, meta) {}
    end

    context 'and the required values are passed in the message' do
      context 'and the handler is registered' do
        before do
          Pakyow::Realtime::MessageHandler.register(name, &block)
        end

        after do
          Pakyow::Realtime::MessageHandler.reset
        end

        it 'calls the handler block' do
          expect(block).to receive(:call)
          Pakyow::Realtime::MessageHandler.handle(message, session)
        end

        it 'calls the handler block with message, session, and meta' do
          expect(block).to receive(:call).with(message, session, id: id)
          Pakyow::Realtime::MessageHandler.handle(message, session)
        end
      end

      context 'and the handler is not registered' do
        it 'raises an error' do
          expect {
            Pakyow::Realtime::MessageHandler.handle(message, session)
          }.to raise_error Pakyow::Realtime::MissingMessageHandler
        end
      end
    end

    context 'and the required arguments are not passed in the message' do
      it 'raises an error when id is not passed' do
        message.delete('id')

        expect {
          Pakyow::Realtime::MessageHandler.handle(message, session)
        }.to raise_error ArgumentError
      end

      it 'raises an error when action is not passed' do
        message.delete('action')

        expect {
          Pakyow::Realtime::MessageHandler.handle(message, session)
        }.to raise_error ArgumentError
      end
    end
  end
end
