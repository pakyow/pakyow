require_relative '../spec_helper'
require 'pakyow/realtime/connection'

describe Pakyow::Realtime::Connection do
  let :connection do
    Pakyow::Realtime::Connection.new
  end
end
