require 'json'

module Grack
  class JSON

    def initialize(worker)
      @worker = worker
    end

    def call(data, job)
      json = JSON.parse(data)

      @worker.call(json, job)
    end

  end
end
