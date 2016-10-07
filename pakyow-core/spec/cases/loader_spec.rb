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

  it 'can recursively load files' do
    expect(Object.const_defined?(:Reloadable)).to eq true
  end

  it 'should tell time' do
    times = @loader.times.dup
    @loader.instance_variable_set(:@times, {})
    `touch #{File.join(path, 'reloadable.rb')}`
    @loader.load_from_path(path)

    # Won't be nil because reloader.enabled is true by default
    expect(times.first).not_to be_nil

    # Won't be nil because reloader picks up the updated file
    expect(@loader.times.first).to_not be_nil
  end
end
