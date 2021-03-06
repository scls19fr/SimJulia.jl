using SimJulia

function my_callback(ev::AbstractEvent, succeed_ev::Event)
  println("Callback of $(ev)")
  println("Succeed is triggered: $(triggered(succeed_ev))")
  println("Succeed is processed: $(processed(succeed_ev))")
  println(succeed_ev)
  succeed(succeed_ev, "Yes we can")
  try
    succeed(succeed_ev, "Yes we can twice")
  catch exc
    println(exc)
  end
end

function my_callback2(ev::AbstractEvent, fail_ev::Event, trigger_ev::Event)
  println("Callback of $(ev)")
  fail(fail_ev, ErrorException("No we can't"))
  try
    fail(fail_ev, ErrorException("No we can't twice"))
  catch exc
    println(exc)
  end
  trigger(fail_ev, trigger_ev)
  try
    trigger(fail_ev, trigger_ev)
  catch exc
    println(exc)
  end
end

function succeed_callback(ev::Event)
  println("Succeed is triggered: $(triggered(ev))")
  println("Succeed is processed: $(processed(ev))")
  println(value(ev))
end

function fail_callback(ev::Event)
  println(value(ev))
end

function trigger_callback(ev::Event)
  println(value(ev))
end

env = Environment()
ev = Timeout(env, 1.0)
ev2 = Timeout(env, 2.0)
succeed_ev = Event(env)
fail_ev = Event(env)
trigger_ev = Event(env)
append_callback(ev, my_callback, succeed_ev)
append_callback(ev2, my_callback2, fail_ev, trigger_ev)
append_callback(succeed_ev, succeed_callback)
append_callback(fail_ev, fail_callback)
append_callback(trigger_ev, trigger_callback)
run(env)
println("Succeed is triggered: $(triggered(succeed_ev))")
println("Succeed is processed: $(processed(succeed_ev))")
println("End of simulation at time $(now(env))")

env = Environment(10.0)
run(env, 12.0)
try
  append_callback(ev, my_callback, succeed_ev)
catch exc
  println("Append callback not possible")
end

println("End of simulation at time $(now(env))")
