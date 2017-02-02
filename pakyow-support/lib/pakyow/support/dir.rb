class Dir
  # visit dir, then all files in dir, then walk_dir each directory in dir
  def self.walk(dir, &block)
    yield dir
    all = Dir.entries(dir)
    partition = all.partition{|e| File.file?("#{dir}/#{e}")}
    files = partition[0]
    dirs = partition[1]
    files.each{|f| yield "#{dir}/#{f}" unless f.start_with?(".")}
    dirs.each{|d| walk("#{dir}/#{d}", &block) unless d.start_with?(".")}
  end

  def self.print(dir)
    puts "/#{dir}"
    Dir.walk(dir) {|full_path|
      path = full_path.gsub(Regexp.new("#{dir}\/?"), '')
      next if path.empty?

      prefix = "|"
      path.scan(/\//).size.times do
        prefix += "  |"
      end

      path.gsub!(/^.*\//, '')
      puts "#{prefix}-- #{path}"
    }
  end

  def self.within_dir?(dir1, dir2)
    dir2.start_with?(dir1)
  end
end
