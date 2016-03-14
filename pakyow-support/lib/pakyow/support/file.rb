class File
  def self.format(path)
    File.extname(path).delete('.')
  end
end
