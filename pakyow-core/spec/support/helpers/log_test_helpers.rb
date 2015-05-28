module LogTestHelpers
  def file
    File.join(path, 'pakyow.log')
  end

  def path
    File.join(Dir.pwd, 'test')
  end
end
