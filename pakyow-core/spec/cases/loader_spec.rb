require 'support/helper'

class Pakyow::Loader
  attr_accessor :times
end

describe 'Loader' do
  include LoaderTestHelpers

  before do
    @loader = Pakyow::Loader.new
    @loader.load_from_path(path)
  end

  it 'can recursively loads files' do
    expect(Object.const_defined?(:Reloadable)).to eq true
  end

  it 'should tell time' do
    Pakyow::Config.app.auto_reload = true

    times = @loader.times.dup
    `touch #{File.join(path, 'reloadable.rb')}`
    @loader.load_from_path(path)

    expect(times.first).to be_nil
    expect(@loader.times.first).to_not be_nil
  end
end
