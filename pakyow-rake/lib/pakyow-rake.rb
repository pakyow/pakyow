libdir = File.dirname(__FILE__)
$LOAD_PATH.unshift(libdir) unless $LOAD_PATH.include?(libdir)

Dir["#{libdir}/tasks/*.rake"].sort.each { |task| load task }
