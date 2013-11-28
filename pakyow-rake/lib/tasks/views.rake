namespace :pakyow do
  desc "List view structure for all view stores, or a specific view path"
  task :views, :view_path do |t, args|
    ViewStructureAnalyzer.analyze(args[:view_path])
  end
end

class ViewStructureAnalyzer
  def self.analyze(view_path)
    views = []

    Pakyow::Config::Base.presenter.view_stores.each_pair {|view_store, store_path|
      Pakyow.app.presenter.view_store(view_store).view_info.each {|path, store|
        next unless Pakyow.app.presenter.view_store(view_store).real_path(path)
        path = Utils::String.normalize_path(path) unless path == "/"
        next if view_path && path != Utils::String.normalize_path(view_path)
        next if views.select{|v| v[:path] == path}.length > 0

        view = View.at_path(path)
        views << { :path => path, :store => store, :containers => view.containers.map {|c| c[:name]} }
      }
    }

    views.sort{|a,b| a[:path] <=> b[:path]}.each {|info|
      root  = info[:store][:root_view]
      views = info[:store][:views]
      containers = info[:containers]

      Pakyow.logger << "\n" + info[:path] + " (#{Utils::String.normalize_path(root).gsub(info[:path], '.')})"

      maxlen = containers.map{|c| c.length}.sort.last
      containers.each {|container|
        space = (maxlen - container.length).times.inject("") {|s| s << " " }

        if file = views[container]
          file.gsub!(info[:path], '.')
        else
          file = '?'
        end

        Pakyow.logger << "  #{space}#{container}: #{file}"
      }
    }
  end
end
