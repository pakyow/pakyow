libdir = File.dirname(__FILE__)
Dir["#{libdir}/tasks/*.rake"].sort.each { |task| load task }
