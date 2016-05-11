__precompile__()

module SimJulia
  using Base.Order
  using Base.Collections

  using Calculus

  import Base.show, Base.isless, Base.yield, Base.run, Base.count, Base.isless
  import Base.now, Base.step, Base.&, Base.|
  import Base.setindex!
  import Base.Collections.peek

  export AbstractEvent, run, succeed, fail, trigger, triggered, processed, value, append_callback, stop_simulation
  export Event, Timeout, EventOperator, AllOf, AnyOf, (&), (|)
  export Process, Interrupt, yield, is_process_done, cause
  export Environment, step, peek, now, active_process
  export Continuous, Variable, Parameter, QSSIntegrator, ExplicitQuantizer, RKIntegrator
  export DelayedProcess
  export Resource, Preempted, Get, Put, Request, Release, cancel, by, usage_since, capacity, count
  export Container, level
  export Store, items

  include("base.jl")
  include("events.jl")
  include("processes.jl")
  include("environments.jl")
  include("util.jl")
  include("continuous/base.jl")
  include("continuous/model.jl")
  include("continuous/explicit_quantizer.jl")
  include("continuous/QSSintegrator.jl")
  include("continuous/RKintegrator.jl")
  include("resources/base.jl")
  include("resources/resources.jl")
  include("resources/containers.jl")
  include("resources/stores.jl")
end
