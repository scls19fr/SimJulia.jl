type ResourceKey <: AbstractResourceKey
  priority :: Int
  id :: Int
  preempt :: Bool
  since :: Float64
end

type ResourcePut <: PutEvent
  bev :: BaseEvent
  proc :: Process
  res :: AbstractResource
  function ResourcePut(env::AbstractEnvironment, res::AbstractResource)
    put = new()
    put.bev = BaseEvent(env)
    put.proc = active_process(env)
    put.res = res
    return put
  end
end

type ResourceGet <: GetEvent
  bev :: BaseEvent
  proc :: Process
  res :: AbstractResource
  function ResourceGet(env::AbstractEnvironment, res::AbstractResource)
    get = new()
    get.bev = BaseEvent(env)
    get.proc = active_process(env)
    get.res = res
    return get
  end
end

type Resource <: AbstractResource
  env :: AbstractEnvironment
  capacity :: Int
  seid :: Int
  put_queue :: PriorityQueue{ResourcePut, ResourceKey}
  get_queue :: PriorityQueue{ResourceGet, ResourceKey}
  users :: PriorityQueue{Process, ResourceKey}
  function Resource(env::AbstractEnvironment, capacity::Int=1)
    res = new()
    res.env = env
    res.capacity = capacity
    res.seid = 0
    if VERSION >= v"0.4-"
      res.put_queue = PriorityQueue(ResourcePut, ResourceKey)
      res.get_queue = PriorityQueue(ResourceGet, ResourceKey)
      res.users = PriorityQueue(Process, ResourceKey, Order.Reverse)
    else
      res.put_queue = PriorityQueue{ResourcePut, ResourceKey}()
      res.get_queue = PriorityQueue{ResourceGet, ResourceKey}()
      res.users = PriorityQueue{Process, ResourceKey}(Order.Reverse)
    end
    return res
  end
end


type Preempted
  by :: Process
  usage_since :: Float64
end

function Put(res::Resource, key::ResourceKey)
  req = ResourcePut(res.env, res)
  res.put_queue[req] = key
  append_callback(req, trigger_get, res)
  trigger_put(req, res)
  return req
end

Request(res::Resource, key::ResourceKey)=Put(res, key)

function Put(res::Resource, priority::Int=0, preempt::Bool=false)
  return Put(res, ResourceKey(priority, res.seid+=1, preempt, 0.0))
end

Request(res::Resource, priority::Int=0, preempt::Bool=false)=Put(res, priority, preempt)

function Get(res::Resource)
  rel = ResourceGet(res.env, res)
  res.get_queue[rel] = ResourceKey(0, res.seid+=1, false, 0.0)
  append_callback(rel, trigger_put, res)
  trigger_get(rel, res)
  return rel
end

Release(res::Resource)=Get(res)

function isless(a::ResourceKey, b::ResourceKey)
  return (a.priority < b.priority) || (a.priority == b.priority && a.preempt < b.preempt) || (a.priority == b.priority && a.preempt == b.preempt && a.id < b.id)
end

function do_put(res::Resource, ev::ResourcePut, key::ResourceKey)
  if length(res.users) >= res.capacity && key.preempt
    (proc_preempt, key_preempt) = peek(res.users)
    if key_preempt > key
      dequeue!(res.users)
      Interruption(proc_preempt, Preempted(ev.proc, key_preempt.since))
    end
  end
  if length(res.users) < res.capacity
    key.since = now(res.env)
    res.users[ev.proc] = key
    succeed(ev, key)
  end
  return false
end

function do_get(res::Resource, ev::ResourceGet, key::ResourceKey)
  dequeue!(res.users, ev.proc)
  succeed(ev)
  return false
end

function count(res::Resource)
  return length(res.users)
end

function by(pre::Preempted)
  return pre.by
end

function usage_since(pre::Preempted)
  return pre.usage_since
end
