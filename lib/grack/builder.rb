module Grack
  class Builder
    def self.parse_file(config, opts = Executor::Options.new)
      options = {}
      if config =~ /\.wu$/
        cfgfile = ::File.read(config)
        if cfgfile[/^#\\(.*)/] && opts
          options = opts.parse! $1.split(/\s+/)
        end
        cfgfile.sub!(/^__END__\n.*\Z/m, '')
        worker = eval "Grack::Builder.new {\n" + cfgfile + "\n}.to_worker",
          TOPLEVEL_BINDING, config
      else
        require config
        worker = Object.const_get(::File.basename(config, '.rb').capitalize)
      end
      return worker, options
    end

    def initialize(default_worker = nil, &block)
      @use, @run = [], nil, default_worker
      instance_eval(&block) if block_given?
    end

    def self.worker(default_worker = nil, &block)
      self.new(default_worker, &block).to_worker
    end

    def use(middleware, *args, &block)
      @use << proc { |worker| middleware.new(worker, *args, &block) }
    end

    def run(worker)
      @run = worker
    end

    def to_worker
      fail "missing run statement" unless @run
      @use.reverse.inject(@run) { |a,e| e[a] }
    end

    def call(env)
      to_worker.call(env)
    end

  end
end

