require 'support/helper'
require 'stringio'

describe 'Log' do
  include LogTestHelpers

  before do
    Pakyow::Config.logger.colorize = false
    @text = 'foo'

    @old = $stdout
    $stdout = StringIO.new
  end

  after do
    FileUtils.rm(file) if File.exists?(file)
    $stdout = @old
  end

  it 'prints to console' do
    Pakyow.configure_logger
    Pakyow.logger << @text

    expect(@text.strip).to eq $stdout.string.strip
  end

  it 'prints to file' do
    Pakyow::Config.logger.path = path
    Pakyow::Config.logger.auto_flush = true
    Pakyow.configure_logger
    Pakyow.logger << @text

    expect(File.exists?(file)).to eq true
    expect(@text.strip).to eq File.new(file).read.strip
  end
end
