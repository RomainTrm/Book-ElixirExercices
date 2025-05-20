# 17. OTP: Servers

*OTP* stands for *Open Telecom Platform*, now OTP is a general-purpose tool for developing and managing large systems.  
It provides a lot of capabilities like application discovery, failure detection and management, hot code swapping and server structure.  

## Some OTP definitions

OTP defines systems in terms of hierarchies of *applications*. An application consists of one or more processes. These processes follow one of a small number of OTP conventions, called *behaviors*. There is a behavior used for general-purpose servers, one for implementing event handlers, and one for finite-state machines. Each implementation of one of these behaviors will run  in its own process (and may have additional associated processes).  
A special behavior, called *supervisor*, monitor the health of these processes and implement strategies for restarting them if needed.  

## An OTP server

### State and the single server

So far (like with the Fibonacci implementation of previous chapters) with "stored" a state by using a recursion: we were passing the state as a parameter for the next call. OTP server does this for us, always passing as a parameter the last state returned.  

### Our first OTP server

In this example, we pass a number as state when we start the server, then we can call it with the `:next_number` request:  

First we create a project `sequence` with Mix.  

```bash
...> mix new sequence
* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/sequence.ex
* creating test
* creating test/test_helper.exs
* creating test/sequence_test.exs
...> cd sequence
...> mkdir lib/sequence
```

Then we create a file `lib/sequence/server.ex`:  

```elixir
defmodule Sequence.Server do
  use GenServer

  def init(initial_number) do
    { :ok, initial_number }
  end

  def handle_call(:next_number, _from, current_number) do
    { :reply, current_number, current_number + 1 }
  end
end
```

When a client call the server, GenServer invokes the *handle_call* function, passing:  

1. information passed by the client
2. the client's PID
3. the server state

The response contains  

1. the action the OTP should perform, here `:reply` to the client
2. the value to return to the client in the response
3. the new state of the server

#### Fire up our server manually

We can execute it:  

```elixir
...> iex -S mix
iex> { :ok, pid } = GenServer.start_link(Sequence.Server, 100)
{:ok, #PID<0.169.0>}
iex> GenServer.call(pid, :next_number)
100
iex> GenServer.call(pid, :next_number)
101
iex> GenServer.call(pid, :next_number)
102
```

Note: the first parameter of a call can contain more complex values than an atom, for example we can add a `:set_number` call:  

```elixir
def handle_call({:set_number, new_number}, _from, _current_number) do
  { :reply, new_number, new_number }
end
```

#### One-way calls

The `call` function calls a server and waits for a reply. When no reply is expected, use `cast` instead.  

```elixir
def handle_cast({:increment_number, delta}, current_number) do
  { :noreply, current_number + delta }
end
```

```elixir
iex> r Sequence.Server
{:reloaded, [Sequence.Server]}
iex> GenServer.call(pid, :next_number)
103
iex> GenServer.cast(pid, {:increment_number, 50})
:ok
iex> GenServer.call(pid, :next_number)
154
```

### Tracing a server's execution

The third parameter of a *start_link* is a set of options.

During development, we can use the debug `:trace`:  

```elixir
iex> { :ok, pid } = GenServer.start_link(Sequence.Server, 100, [debug: [:trace]])
iex> GenServer.call(pid, :next_number)
*DBG* <0.178.0> got call next_number from <0.160.0>
*DBG* <0.178.0> sent 100 to <0.160.0>, new state 101
100
iex> GenServer.call(pid, :next_number)
*DBG* <0.178.0> got call next_number from <0.160.0>
*DBG* <0.178.0> sent 101 to <0.160.0>, new state 102
101
```

We can retrieve some `:statistics`:  

```elixir
iex> { :ok, pid } = GenServer.start_link(Sequence.Server, 100, [debug: [:statistics]])
iex> GenServer.call(pid, :next_number)
100
iex> GenServer.call(pid, :next_number)
101
iex> :sys.statistics pid, :get
{:ok,
 [
   start_time: {{2025, 5, 20}, {13, 34, 45}},
   current_time: {{2025, 5, 20}, {13, 35, 6}},
   reductions: 106,
   messages_in: 2,
   messages_out: 2
 ]}
```

The `reduction` value is a measure of the amount of work the server does. It's used in process scheduling as a way of making sure all processes get a fair share of the available CPU.  

The list of the `debug` parameters we give to GenSever is simply the names of functions to call in the *sys* module. We can turn things on and off while running our server:  

```elixir
iex> { :ok, pid } = GenServer.start_link(Sequence.Server, 100)
{:ok, #PID<0.180.0>}
iex> :sys.trace pid, true
:ok
iex> GenServer.call(pid, :next_number)
*DBG* <0.180.0> got call next_number from <0.160.0>
*DBG* <0.180.0> sent 100 to <0.160.0>, new state 101
100
iex> :sys.trace pid, false
:ok
iex> GenServer.call(pid, :next_number)
101
```

`get_status` is another useful *sys* function:  

```elixir
iex> :sys.get_status pid
{:status, #PID<0.180.0>, {:module, :gen_server},
 [
   [
     "$initial_call": {Sequence.Server, :init, 1},
     "$ancestors": [#PID<0.160.0>, #PID<0.94.0>]
   ],
   :running,
   #PID<0.160.0>,
   [],
   [
     header: ~c"Status for generic server <0.180.0>",
     data: [
       {~c"Status", :running},
       {~c"Parent", #PID<0.160.0>},
       {~c"Logged events", []}
     ],
     data: [{~c"State", 102}]
   ]
 ]}
```

Note: we can customize status format:  

```elixir
def format_status(_reason, [ _pdict, state ]) do
   [data: [{~c"State", "My current state is '#{inspect state}', and I'm happy"}]]
end
```

```elixir
iex> r Sequence.Server
{:reloaded, [Sequence.Server]}
iex> :sys.get_status pid
{:status, #PID<0.180.0>, {:module, :gen_server},
 [
   [
     "$initial_call": {Sequence.Server, :init, 1},
     "$ancestors": [#PID<0.160.0>, #PID<0.94.0>]
   ],
   :running,
   #PID<0.160.0>,
   [],
   [
     header: ~c"Status for generic server <0.180.0>",
     data: [
       {~c"Status", :running},
       {~c"Parent", #PID<0.160.0>},
       {~c"Logged events", []}
     ],
     data: [{~c"State", "My current state is '102', and I'm happy"}] # => custom message
   ]
 ]}
```

## GenServer Callbacks

When adding the `use GenServer` to a module, Elixir create default implementations for [callbacks](https://hexdocs.pm/elixir/1.12/GenServer.html#callbacks), all w have to do is defining overload to code the desired behaviors:  

- `init(start_arguments)`: called when starting a new server, the parameter is the second param of the *start_link*. We should return `{:ok, state}` or `{:error, reason}`. We can also define a timeout (in ms) for the server when no message has been received with `{:ok, state, timeout}`.  
- `handle_call(request, from, state)`: Invoked when a client uses `GenServer.call(pid, request)`. The *from* is a tuple containing the PID of the client and a unique tag. Valid responses are `{:no_reply, new_state [, :hibernate | timeout]}`, `{:stop, reason, new_state}`, `{:reply, response, new_state [, :hibernate | timeout]}` and `{:stop, reason, reply, new_state}`. Default implementation returns `:bad_call` error.
- `handle_cast(request, state)`: Invoked when a client uses `GenServer.cast(pid, request)`. Valid responses are `{:no_reply, new_state [, :hibernate | timeout]}` and `{:stop, reason, new_state}`. The default implementation returns `:bad_cast` error.
- `handle_info(info, state)`: Used to handle messages that are not *call* or *cast* requests. For examples *timeout* message or a termination message from a linked process. Also handle messages sent to the PID with the `send` function (bypassing GenServer).
- `terminate(reason, state)`: Called when the server is about to terminate.
- `code_change(from_version, state, extra)`: Updates a server without stopping it. This callback is invoked to change from the old state format to the new.
- `format_status(reason, [pdict, state])`: Used to customize the display of the server's state. Conventional response is `[data: [{~c"State", state_info}]]`.

For *call* and *cast*:  

- `:hibernate`: server state is removed from memory but recovered at the next request. This saves some memory but add CPU load.
- `timeout`: accepts `:infinite` (default value) or any number (in ms).

## Naming a process

We can assign unique names to our processes to replace PIDs:  

```elixir
iex> { :ok, pid } = GenServer.start_link(Sequence.Server, 100, name: :seq)
{:ok, #PID<0.198.0>} 
iex> GenServer.call(:seq, :next_number)
100
iex> GenServer.call(:seq, :next_number)
101
iex> :sys.get_status :seq
{:status, #PID<0.198.0>, {:module, :gen_server},
 [
   [
     "$initial_call": {Sequence.Server, :init, 1},
     "$ancestors": [#PID<0.160.0>, #PID<0.94.0>]
   ],
   :running,
   #PID<0.160.0>,
   [],
   [
     header: ~c"Status for generic server seq",
     data: [
       {~c"Status", :running},
       {~c"Parent", #PID<0.160.0>},
       {~c"Logged events", []}
     ],
     data: [{~c"State", "My current state is '102', and I'm happy"}]
   ]
 ]}
```

## Tidying up the interface

The current implementation isn't satisfying: we've got direct dependencies to GenServer for calling functions. Let's define an interface that abstract GenServer and expose a business-oriented API:  

```elixir
defmodule Sequence.Server do
  use GenServer

  # Public API
  def start_link(current_number) do
    GenServer.start_link(__MODULE__, current_number, name: __MODULE__)
  end

  def next_number do
    GenServer.call __MODULE__, :next_number
  end

  def increment_number(delta) do
    GenServer.cast __MODULE__, {:increment_number, delta}
  end

  # GenServer implementation
  def init(initial_number) do
    { :ok, initial_number }
  end

  def handle_call(:next_number, _from, current_number) do
    { :reply, current_number, current_number + 1 }
  end

  # ....
end
```

Then we can use our public API:  

```elixir
iex> r Sequence.Server
{:reloaded, [Sequence.Server]}
iex> Sequence.Server.start_link 42
{:ok, #PID<0.207.0>}
iex> Sequence.Server.next_number
42
iex> Sequence.Server.next_number
43
iex> Sequence.Server.increment_number 50
:ok
iex> Sequence.Server.next_number
94
```

This pattern is widely spread in the Elixir community.  

## Making our server into a component

The author argues that this canonical does not really satisfy him, because a single file contains:  

- The API
- The logic of our service (here adding a number)
- The implementation of that logic into the server

This can rapidly escalate in a lot of complexity (and I tend to agree), so he suggests splitting it in three distinct files:  

```bash
...> mix new sequence_split
...> cd sequence_split
...> mkdir lib/sequence                                                               
...> echo . > lib/sequence/impl.ex
...> echo . > lib/sequence/server.ex
```

We've got the following tree:  

```goat
lib
+-+ sequence
| +- impl.ex
| +- server.ex
+- sequence_split.ex
```

Then we add our code:  

```elixir
# sequence_split.ex
defmodule Sequence do
  @server Sequence.Server

  def start_link(current_number) do
    GenServer.start_link(@server, current_number, name: @server)
  end

  def next_number do
    GenServer.call(@server, :next_number)
  end

  def increment_number(delta) do
    GenServer.cast(@server, {:increment_number, delta})
  end
end
```

```elixir
# sequence/server.ex
defmodule Sequence.Server do
  use GenServer
  alias Hex.Solver.Constraints.Impl
  alias Sequence.Impl

  def init(initial_number) do
    {:ok, initial_number}
  end

  def handle_call(:next_number, _from, current_number) do
    {:reply, current_number, Impl.next(current_number)}
  end

  def handle_cast({:increment_number, delta}, current_number) do
    {:noreply, Impl.increment(current_number, delta)}
  end

  def format_status(_reason, [ _pdict, state ]) do
    [data: [{~c"State", "My current state is '#{inspect state}', and I'm happy"}]]
  end
end
```

```elixir
# sequence/impl
defmodule Sequence.Impl do
  def next(number), do: number + 1
  def increment(number, delta), do: number + delta
end
```
