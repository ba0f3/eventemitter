type
  Args* = ref object of RootObj # ...args
  Handler = proc (args: Args) {.closure.} # callback function type
  Event[T] = tuple[typ: T, handlers:seq[Handler]] # key value pair
  EventEmitter[T] = ref object
    events: seq[Event[T]] # will use sequence as fixed size array

proc createEventEmitter*[T](): EventEmitter[T] =
  result.new
  result.events = @[]

method on*[T](this: EventEmitter[T], typ: T, handler: Handler): void {.base.} =
  var event: Event[T] = (typ: typ, handlers: @[])
  var id: int = -1
  for i in 0..high(this.events):
    if this.events[i].typ == typ:
      id = i
      event = this.events[i]
  event.handlers.add(handler)
  if id == -1: this.events.add(event)
  else: this.events[id] = event

method once*[T](this:EventEmitter[T], typ: T, handler:Handler): void {.base.} =
  var id: Natural = 0
  for i in 0..high(this.events):
      if this.events[i].typ == typ:
        id = this.events[i].handlers.len()
  this.on(typ) do(a: Args):
    handler(a)
    for i in 0..high(this.events):
      if this.events[i].typ == typ:
        this.events[i].handlers.del(id)

method emit*[T](this:EventEmitter[T], typ: T, args:Args): void {.base.} =
  for i in 0..high(this.events):
    if this.events[i].typ == typ:
      for x in 0..high(this.events[i].handlers):
        this.events[i].handlers[x](args)

when isMainModule:
  block:
    type ReadyArgs = ref object of Args
      text: string
    var evts = createEventEmitter[string]()
    evts.on("ready") do(a: Args):
      var args = ReadyArgs(a)
      echo args.text, ": from [1st] handler"
    evts.once("ready") do(a: Args):
      var args = ReadyArgs(a)
      echo args.text, ": from [2nd] handler"
    evts.emit("ready", ReadyArgs(text:"Hello, World"))
    evts.emit("ready", ReadyArgs(text:"Hello, World"))