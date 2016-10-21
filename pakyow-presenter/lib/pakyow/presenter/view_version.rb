class Pakyow::Presenter::ViewVersion
  attr_reader :default, :empty, :versions

  def initialize(views)
    @empty    = views.find { |view| view.version == :empty }
    @default  = views.find { |view| view.doc.attribute?(:'data-default') } || views.find { |view| view.version != :empty }
    @versions = views
  end

  def initialize_copy(original_view)
    super

    @empty = original_view.empty.soft_copy if original_view.empty
    @versions = original_view.versions.map { |view| view.soft_copy }
    @default = versions.first
  end

  def with(&block)
    if block.arity == 0
      instance_exec(&block)
    else
      yield(self)
    end

    self
  end

  def apply(data, bindings: {}, context: nil, &block)
    data = Array.ensure(data)

    if data.empty?
      @default = @empty
      cleanup
      self
    else
      cleanup

      match(data).bind(data, bindings: bindings, context: context, &block)
    end
  end

  def version(data, &block)
    data = Array.ensure(data)
    coll = Pakyow::Presenter::ViewCollection.new(@default.scoped_as)

    if data.empty?
      @versions.each(&:remove)
    else
      @empty.remove if @empty
      self_dup = self.dup

      view = process_version(self, data.first, &block)
      working = view
      coll << view

      data[1..-1].inject(coll) { |set, datum|
        duped = self_dup.dup
        view = process_version(duped, datum, &block)

        working.after(view)
        working = view
        set << view
      }

      coll
    end
  end

  def bind(data, bindings: {}, context: nil, &block)
    @versions.each do |view|
      view.bind(data, bindings: bindings, context: context, &block)
    end
  end

  def use(version)
    @versions.each do |view|
      @default = view if view.version == version
    end

    cleanup

    @default
  end

  def cleanup
    @versions.reject { |view| view == @default }.each(&:remove)
    @versions = [@default]
  end

  def method_missing(method, *args, &block)
    if @default.respond_to?(method)
      ret = @default.send(method, *args, &block)

      # because `match` mutates the default view (turning it into a collection), we
      # need to set default to this new collection so that things continue to work
      @default = ret if method == :match

      ret
    end
  end

  private

  def process_version(version, datum, &block)
    if block.arity == 1
      version.instance_exec(datum, &block)
    else
      block.call(version, datum)
    end

    version.default
  end
end
