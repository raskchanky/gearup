# Grack

There's got to be a better name.

## A Rack-like library for Gearman workers

That is, a worker is merely something that responds to `call`. Without any
middleware, a worker is given a string of data, and Gearman Job.

Something like so:

```ruby
class ReversesStrings

  def call(data, job)
    data.reverse
  end

end
```

And then instead of having `config.ru`, you have `config.wu`, and run `workup`.
