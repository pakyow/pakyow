namespace :pakyow do
  desc "List bindings across all views, or a specific view path"
  task :bindings, :view_path do |t, args|
    BindingAnalyzer.analyze(args[:view_path])
  end
end

class BindingAnalyzer
  def self.analyze(view_path)
    bindings = []

    Pakyow::Config::Base.presenter.view_stores.each_pair {|view_store, store_path|
      Pakyow.app.presenter.view_store(view_store).view_info.each {|path, store|
        next unless Pakyow.app.presenter.view_store(view_store).real_path(path)
        path = Utils::String.normalize_path(path) unless path == "/"
        next if view_path && path != Utils::String.normalize_path(view_path)
        next if bindings.select{|b| b[:path] == path}.length > 0

        view = View.at_path(path)
        bindings << { :path => path, :bindings => view.bindings}
      }
    }

    bindings.each {|set|
      next if set[:bindings].empty?

      Pakyow.logger << "\n" + set[:path]

      log_bindings(set[:bindings])
    }
  end

  def self.log_bindings(bindings, nested = "")
    bindings.each {|binding|
      space = "  "

      scope_str = space.dup
      scope_str << "#{nested} > " unless nested.empty?
      scope_str << binding[:scope].to_s
      Pakyow.logger << scope_str

      props = binding[:props]
      if props.count > 0
        binding[:props].each {|prop|
          Pakyow.logger << space + "  #{prop[:prop]}"
        }
      else
        Pakyow.logger << space + "  (no props)"
      end


      next_nested = binding[:scope]
      next_nested = "#{nested} > #{next_nested}" unless nested.empty?
      log_bindings(binding[:nested_bindings], next_nested)
    }
  end
end
