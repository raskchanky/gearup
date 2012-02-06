require 'gearman'

module Grack
  module GearmanHandler

    def self.start(worker, ability, options)
      @client = Gearman::Client.new(options[:servers])
      @worker = Gearman::Worker.new(options[:servers])
      @taskset = Gearman::TaskSet.new(@client)

      @worker.add_ability(ability) do |data, job|
        worker.call(data, job)
      end

      loop { @worker.work }
    end

  end
end
