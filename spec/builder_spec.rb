require 'gearup'

describe Gearup::Builder do

  it 'adds a worker using "run"' do
    worker = stub
    subject.run worker

    subject.worker.should == worker
  end

  it 'adds a middleware using "use"' do
    middleware = stub
    subject.use middleware

    subject.middleware.should include(middleware)
  end

  it 'adds a middleware with dependencies' do
    middleware, dependency = stub, stub
    subject.use middleware, dependency

    subject.middleware.should include(middleware)
  end

  it 'builds workers' do
    middleware, worker = stub, stub

    built_worker = Gearup::Builder.build do
      use middleware

      run worker
    end

    built_worker.worker.should == worker
    built_worker.middleware.should include(middleware)
  end

end
