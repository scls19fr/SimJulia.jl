type StoreKey <: AbstractResourceKey
  priority :: Int
  id :: Float64
end

type StorePut{T} <: PutEvent
  bev :: BaseEvent
  proc :: Process
  res :: AbstractResource
  item :: T
  function StorePut(res::AbstractResource, item::T)
    put = new()
    put.bev = BaseEvent(res.env)
    put.proc = active_process(res.env)
    put.res = res
    put.item = item
    return put
  end
end

type StoreGet <: GetEvent
  bev :: BaseEvent
  proc :: Process
  res :: AbstractResource
  filter :: Function
  function StoreGet(res::AbstractResource, filter::Function)
    get = new()
    get.bev = BaseEvent(res.env)
    get.proc = active_process(res.env)
    get.res = res
    get.filter = filter
    return get
  end
end

type Store{T} <: AbstractResource
  env :: Environment
  capacity :: Int
  items :: Set{T}
  seid :: Int
  put_queue :: PriorityQueue{StorePut{T}, StoreKey}
  get_queue :: PriorityQueue{StoreGet, StoreKey}
  function Store(env::Environment, capacity::Int=typemax(Int))
    sto = new()
    sto.env = env
    sto.capacity = capacity
    sto.items = Set{T}()
    sto.seid = 0
    if VERSION >= v"0.4-"
      sto.put_queue = PriorityQueue(StorePut{T}, StoreKey)
      sto.get_queue = PriorityQueue(StoreGet, StoreKey)
    else
      sto.put_queue = PriorityQueue{StorePut{T}, StoreKey}()
      sto.get_queue = PriorityQueue{StoreGet, StoreKey}()
    end
    return sto
  end
end

function Put{T}(sto::Store{T}, item::T, priority::Int=0)
  put = StorePut{T}(sto, item)
  sto.put_queue[put] = StoreKey(priority, sto.seid+=1)
  append_callback(put, trigger_get, sto)
  trigger_put(put, sto)
  return put
end

function get_any_item{T}(item::T)
  return true
end

function Get{T}(sto::Store{T}, filter::Function=get_any_item, priority::Int=0)
  get = StoreGet(sto, filter)
  sto.get_queue[get] = StoreKey(priority, sto.seid+=1)
  append_callback(get, trigger_put, sto)
  trigger_get(get, sto)
  return get
end

function isless(a::StoreKey, b::StoreKey)
  return (a.priority < b.priority) || (a.priority == b.priority && a.id < b.id)
end

function do_put(sto::Store, ev::StorePut, key::StoreKey)
  if length(sto.items) < sto.capacity
    push!(sto.items, ev.item)
    succeed(ev)
  end
  return false
end

function do_get(sto::Store, ev::StoreGet, key::StoreKey)
  for item in sto.items
    if ev.filter(item)
      delete!(sto.items, item)
      succeed(ev, item)
      break
    end
  end
  return true
end

function items(sto::Store)
  return sto.items
end
