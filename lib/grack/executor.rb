require 'optparse'

module Grack
  class Executor

    class Options

      def parse!(args)
        options = {}
        opt_parser = OptionParser.new do |opts|
          opts.banner = "Usage: workup [ruby options] [grack options] [workup config]"

          opts.separator ""
          opts.separator "Ruby options:"

          opts.on("-d", "--debug", "set debugging flags (set $DEBUG to true)") {
            options[:debug] = true
          }
          opts.on("-w", "--warn", "enable warnings") {
            options[:warn] = true
          }

          opts.on("-I", "--include PATH",
                  "specify $LOAD_PATH, ':'-separated") { |path|
            options[:include] = path.split(":")
          }

          opts.on("-r", "--require LIBRARY",
                  "require a library, before executing your script") { |library|
            options[:require] = library
          }

          opts.separator ""
          opts.separator "Rack options:"
          opts.on("-s", "--server SERVER[, SERVER]", "Job server address(es)") { |s|
            options[:servers] = s.gsub!(/\s+/, '').split(',')
          }

          opts.on("-D", "--daemonize", "run daemonized in the background") { |d|
            options[:daemonize] = d ? true : false
          }

          opts.on("-P", "--pid FILE", "file to store PID (default: grack.pid)") { |f|
            options[:pid] = ::File.expand_path(f)
          }

          opts.separator ""
          opts.separator "Common options:"

          opts.on_tail("-h", "-?", "--help", "Show this message") do
            puts opts

            exit
          end

          opts.on_tail("--version", "Show version") do
            puts "Grack #{Grack::VERSION} (Release: #{Grack::RELEASE})"
            exit
          end
        end

        begin
          opt_parser.parse! args
        rescue OptionParser::InvalidOption => e
          warn e.message
          abort opt_parser.to_s
        end

        options[:config] = args.last if args.last
        options
      end

    end

    attr_writer :options

    def self.execute(options = nil)
      new(options).execute
    end

    def self.middleware
      @middleware ||= begin
        # A safe hash for our purposes: if the requested key is not present, it
        # sets and returns an empty array for that key
        #
        # XXX: create some sweet middleware for deploy and for develop

        m = Hash.new { |h, k| h[k] = [] }
      end
    end

    def initialize(options = nil)
      @options = options
      @worker = options && options[:worker]
    end

    def options
      @options ||= parse_options(ARGV)
    end

    def default_options
      {
        :environment => ENV['GRACK_ENV'] || 'development',
        :pid => nil,
        :servers => ['localhost:4730'],
        :config => 'config.wu'
      }
    end

    def middleware
      self.class.middleware
    end

    def worker
      @worker ||= begin
        if !::File.exist? options[:config]
          abort "configuration #{options[:config]} not found"
        end

        worker, options = Grack::Builder.parse_file(self.options[:config],
                                                    opt_parser)
        self.options.merge! options

        worker
      end
    end

    def execute
      if options[:warn]
        $-w = true
      end

      if includes = options[:include]
        $LOAD_PATH.unshift(*includes)
      end

      if library = options[:require]
        require library
      end

      if options[:debug]
        $DEBUG = true
        require 'pp'
        p options[:servers]
        pp wrapped_worker
        pp worker
      end

      wrapped_worker

      daemonize_worker if options[:daemonize]
      write_pid if options[:pid]

      trap(:INT) do
        if handler.respond_to?(:shutdown)
          handler.shutdown
        else
          exit
        end
      end

      ability = worker.class.name

      handler.start wrapped_worker, ability, options
    end

    def handler
      @handler ||= Grack::GearmanHandler
    end

    private

    def parse_options(args)
      options = default_options

      options.merge! opt_parser.parse!(args)
      options[:config] = ::File.expand_path(options[:config])
      ENV['GRACK_ENV'] = options[:environment]

      options
    end

    def opt_parser
      Options.new
    end

    def wrapped_worker
      @wrapped_worker ||= build_worker worker
    end

    def build_worker(worker)
      middleware[options[:environment]].reverse_each do |middleware|
        middleware = middleware.call(self) if middleware.respond_to?(:call)

        if middleware
          # If we've still got +middleware+, either by the return of +call+
          # above or because it doesn't respond to +call+, we assume it's
          # an array with the first element being that which responds to
          # +new+ and the rest being the arguments for +new+
          klass = middleware.shift
          worker = klass.new(worker, *middleware)
        end
      end

      worker
    end

    def daemonize_worker
      if RUBY_VERSION < "1.9"
        exit if fork
        Process.setsid
        exit if fork
        Dir.chdir '/'
        STDIN.reopen '/dev/null'
        STDOUT.reopen '/dev/null', 'a'
        STDERR.reopen '/dev/null', 'a'
      else
        Process.daemon
      end
    end

    def write_pid
      ::File.open(options[:pid], 'w') { |f| f.write("#{Process.pid}") }
      at_exit { ::File.delete(options[:pid]) if ::File.exist?(options[:pid]) }
    end

  end
end
