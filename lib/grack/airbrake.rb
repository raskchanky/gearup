require 'hoptoad_notifier'

module Grack
  class Airbrake

    def initialize(worker)
      @worker = worker
    end

    def call(data, job)
      begin
        @worker.call(data, job)
      rescue => exception
        params = { :data => data }

        HoptoadNotifier.notify(exception, params)
      end
    end

  end
end
