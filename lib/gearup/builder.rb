module Gearup
  class Builder

    def self.build(&specification)
      built_specification = new.tap { |b| b.instance_eval(&specification) }
    end

    attr_reader :worker, :middleware

    def initialize
      @worker = nil
      @middleware = []
    end

    def run(worker)
      @worker = worker
    end

    def use(*args)
      middleware = args.shift

      @middleware << middleware
    end

  end
end
