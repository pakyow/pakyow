namespace :pakyow do
  namespace :routes do
    desc "List all routes"
    task :all do
      Pakyow::Router.instance.sets.each {|set_data|
        set_name, set = set_data

        Log.enter
        Log.enter "#{set_name} routes"
        Log.enter

        all_routes = []
        set.routes.each {|route_data|
          method, routes = route_data

          routes.each {|route|
            all_routes << {
              method: method,
              path: File.join('/', route[4]),
              name: route[2]
            }
          }
        }

        all_routes.sort{|a,b| a[:path] <=> b[:path]}.each {|route|
          s = "#{route[:method].upcase}\t#{route[:path]}"
          s << ", :#{route[:name]}" if route[:name]
          Log.enter s
        }

        Log.enter
      }
    end
  end
end
