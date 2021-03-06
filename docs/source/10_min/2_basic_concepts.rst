Discrete Events
---------------

SimJulia is a discrete-event simulation library. The behavior of active components (like vehicles, customers or messages) is modeled with `processes`. All processes live in an `environment`. They interact with the environment and with each other via `events`.

Processes are described by simple Julia functions. During their lifetime, they create events and `yield` them in order to wait for them to be triggered.

When a process yields an event, the process gets suspended. SimJulia resumes the process, when the event occurs (we say that the event is triggered). Multiple processes can wait for the same event. SimJulia resumes them in the same order in which they yielded that event.

An important event is a timeout. Events of this type are triggered after a certain amount of (simulated) time has passed. They allow a process to sleep (or hold its state) for the given time. A timeout and all other events can be created by calling an appropriate constructor having a reference to the environment that the process lives in.


The First Process
~~~~~~~~~~~~~~~~~

The first example will be a `car` process. The car will alternately drive and park for a while. When it starts driving (or parking), it will print the current simulation time.

So let’s start::

  julia> using SimJulia

  julia> function car(env::Environment)
           while true
             println("Start parking at $(now(env))")
             parking_duration = 5.0
             yield(Timeout(env, parking_duration))
             println("Start driving at $(now(env))")
             trip_duration = 2.0
             yield(Timeout(env, trip_duration))
           end
         end
  car (generic function with 1 method)

The car process function requires a reference to an :class:`Environment` (env) in order to create new events. The car‘s behavior is described in an infinite loop. Though it will never terminate, it will pass the control flow back to the simulation once a :func:`yield(ev) <yield>` statement is reached. If the yielded event is triggered (“it occurs”), the simulation will resume the function at this statement.

The car switches between the states parking and driving. It announces its new state by printing a message and the current simulation time (as returned by the function :func:`now(env) <now>`). It then calls the contructor :func:`Timeout(env, parking_duration) <Timeout>` to create a timeout event. This event describes the point in time the car is done parking (or driving, respectively). By yielding the event, it signals the simulation that it wants to wait for the event to occur.

Now that the behavior of the car has been modeled, create an instance of it and see how it behaves::

  julia> env = Environment()
  Environment(0.0,PriorityQueue{BaseEvent,EventKey}(),0,0,Nullable{Process}())

  julia> Process(env, car)
  SimJulia.Process 1: car

  julia> run(env, 15.0)
  Start parking at 0.0
  Start driving at 5.0
  Start parking at 7.0
  Start driving at 12.0
  Start parking at 14.0

The first thing to do is to create an instance of :class:`Environment`. This instance is passed into the car process function. Calling :func:`Process(env, car) <Process>` creates a :class:`Process` that needs to be started and added to the environment.
Note, that at this time, none of the code of our process function is being executed. Its execution is merely scheduled at the current simulation time.
The :class:`Process` returned by :func:`Process(env, car) <Process>` can be used for process interactions (this will be covered in the next section).
Finally, the simulation starts by calling :func:`run(env, 15.0) <run>` where the second argument is the end time.

