# Gearup

## What is Gearup?

Gearup provides a Rack-like interface for Gearman workers. Like Rack, it provides a binary, `gearup` to run workers, which are conventionally specified in a file named `worker.rb`. A simple `worker.rb` might look like this:

```ruby
require 'gearup/echo'

# Unpack the data given to each job from JSON
use Gearup::Middleware::UnpackJSON

# Run the Echo worker
run Gearup::Echo.new
```

## Worker

Workers respond to `call`, and are given one argument, `env`. The Echo worker above might look like this:

```ruby
module Gearup
  class Echo

    def call(env)
      return env.data
    end

  end
end
```

An application using the Echo worker would send jobs to it using the ability `"gearup.echo"`.

## Middleware

Gearup workers are supported by middleware, which have access to the worker, as well as the `env` given to the worker. [gearman-ruby] provides an API through which workers can send data back to the Gearman server, but I haven't decided if Gearup will expose this API yet, as it hasn't proven terribly useful in production.

For instance, the `Gearup::UnpackJSON` middleware uses the [json] gem to `env.data` from JSON before it's passed to the worker, and looks roughly like so:

```ruby
require 'json'

module Gearup
  module Middleware
    class UnpackJSON

      def initialize(worker)
        @worker = worker
      end

      def call(env)
        env.data = ::JSON.parse(env.data)

        @worker.call(env)
      end

    end
  end
end
```

Note that when adding Middleware to a worker, you may supply arguments to the middleware:

```ruby
module Gearup
  module Middleware
    class Logging

      def initialize(worker, logger)
        @worker = worker
        @logger = logger
      end

      def call(env)
        @logger.debug "Received: #{env.data} from server."

        result = @worker.call(env)

        @logger.debug "Worker returned: #{result}"
      end

    end
  end
end
```

You would use `Gearup::Middleware::Logging` like so:

```ruby
use Gearup::Middleware::Logging, Logger.new('./log/worker.log')
```

## Miscellany

Though I haven't put much thought into how this would work with tools like [Supervisor], [god], or [Foreman] I think a construct like Rack's `URLMap` could be useful for building a map of ability strings to workers, as well as specifying other data; for instance, how many processes of each worker to create.

[gearman-ruby]: http://rubgems.org/gems/gearman-ruby
[json]: http://rubygems.org/gems/json
[Supervisor]: http://supervisord.org/
[god]: http://godrb.com/
[Foreman]: http://ddollar.github.com/foreman/
