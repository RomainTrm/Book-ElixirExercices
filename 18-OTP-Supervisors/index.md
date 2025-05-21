# 18. OTP: Supervisors

*Supervisors* perform all the process monitoring and restarting.  

## Supervisors and Workers

A *Supervisor* manages one or more processes (workers or other supervisors). To do so, it uses the OTP supervisor behavior.  

```elixir
...> mix new --sup sequence
* creating README.md
* creating .formatter.exs
* creating .gitignore
* creating mix.exs
* creating lib
* creating lib/sequence.ex
* creating lib/sequence/application.ex
* creating test
* creating test/test_helper.exs
* creating test/sequence_test.exs
```

This adds this file `lib/sequence/application`. Once we've implemented our sequence server, we can declare it in the `children` section:  

```elixir
defmodule Sequence.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    children = [
      {Sequence.Server, 123} # Init the sequence server with the number 123
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Sequence.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
```

When our application start, the supervisor will start the server and set the number.  

```elixir
...> iex -S mix
iex> Sequence.Server.increment_number 5
:ok
iex> Sequence.Server.next_number
128

# Now we crash the server
iex> Sequence.Server.increment_number "cat"
:ok

13:24:08.403 [error] GenServer Sequence.Server terminating
** (ArithmeticError) bad argument in arithmetic expression
    :erlang.+(129, "cat")
    (sequence 0.1.0) lib/sequence/server.ex:31: Sequence.Server.handle_cast/2
    (stdlib 6.2.2) gen_server.erl:2371: :gen_server.try_handle_cast/3
    (stdlib 6.2.2) gen_server.erl:2433: :gen_server.handle_msg/6
    (stdlib 6.2.2) proc_lib.erl:329: :proc_lib.init_p_do_apply/3
Last message: {:"$gen_cast", {:increment_number, "cat"}}
State: [data: [{~c"State", "My current state is '129', and I'm happy"}]]

# Server has been restared at his initial state
iex> Sequence.Server.next_number
123
iex> Sequence.Server.next_number
124
```

### Managing process state across restarts

We will write a separate process *stash* that can store and retrieve a value. In case of the sequence* server crash, we'll use *stash* to recover the last state.  

```elixir
# lib/sequence/stash
defmodule Sequence.Stash do
  use GenServer

  @me __MODULE__

  def start_link(initial_number) do
    GenServer.start_link(@me, initial_number, name: @me)
  end

  def get() do
    GenServer.call(@me, {:get})
  end

  def update(new_number) do
    GenServer.cast(@me, {:update, new_number})
  end

  # Server implementations

  def init(initial_number) do
    {:ok, initial_number}
  end

  def handle_call({:get}, _from, current_number) do
    {:reply, current_number, current_number}
  end

  def handle_cast({:update, new_number}, _current_number) do
    {:noreply, new_number}
  end
end
```

Now we have to supervise it alongside the sequence server. If one process crashes, we have the choice between several supervision strategies:  

- `:one_for_one`: if a server dies, the supervisor will restart it. This is the default strategy.
- `:one_for_all`: if a server dies, all remaining servers are terminated, then they're all restarted.
- `:rest_for_one`: if a server dies, the servers that follow it in the child list are terminated, then dying and terminated servers are restarted.

So we declare our *stash* server and we update our strategy:  

```elixir
# lib/sequence/application.ex
def start(_type, _args) do
  children = [
    {Sequence.Stash, 123}, # contains the initial state
    {Sequence.Server, nil}, # initial state is removed
  ]

  opts = [strategy: :rest_for_one, name: Sequence.Supervisor] # use the :rest_for_one strategy
  Supervisor.start_link(children, opts)
end
```

Now we have to update the *sequence* server to call the *stash*:  

```elixir
# lib/sequence/server.ex
defmodule Sequence.Server do
  use GenServer

  # Public API
  def start_link(_) do # Ignore parameter
    GenServer.start_link(__MODULE__, nil, name: __MODULE__) # Pass nil as initial state
  end

  # ...

  # GenServer implementation
  def init(_) do
    { :ok, Sequence.Stash.get() } # get state from stash
  end

  # ...

  def terminate(_reason, current_number) do
    Sequence.Stash.update(current_number) # store last state in stash
  end
end
```

Now, we should retrieve our last state after a crash from the server:  

```elixir
...> iex -S mix
iex> Sequence.Server.next_number
123
iex> Sequence.Server.next_number
124

# Server crash
iex> Sequence.Server.increment_number "cat"
:ok

13:49:39.174 [error] GenServer Sequence.Server terminating
** (ArithmeticError) bad argument in arithmetic expression
    :erlang.+(125, "cat")
    (sequence 0.1.0) lib/sequence/server.ex:31: Sequence.Server.handle_cast/2
    (stdlib 6.2.2) gen_server.erl:2371: :gen_server.try_handle_cast/3
    (stdlib 6.2.2) gen_server.erl:2433: :gen_server.handle_msg/6
    (stdlib 6.2.2) proc_lib.erl:329: :proc_lib.init_p_do_apply/3
Last message: {:"$gen_cast", {:increment_number, "cat"}}
State: [data: [{~c"State", "My current state is '125', and I'm happy"}]]

# Resumes with the last state
iex> Sequence.Server.next_number
125
```

### Simplify the stash

As the sole job of the *stash* is to store a value, Agents are perfect fit for it and we'll be able to simplify our code.

## Worker restart options

There is a second level of configurations that applies to individual workers, the most commonly used is the `:restart` option.  

- `:permanent`: the worker should always be running, so the supervisor's strategy is applied whenever the worker terminates.  
- `:temporary`: the worker should never be restarted, so the supervision strategy is ignored if the worker dies.
- `:transient`: the worker is expected to terminate normally at some point. When it does, it is not restarted. If it terminates abnormally, then the supervision strategy is applied.

To apply this option, we add it to the `use GenServer` (or `use Supervisor`):  

```elixir
defmodule Convolver do
  use GenServer, restart: :transient
  # ...
```

### A little more details

The `children` list is a list of *child specifications*, it specifies functions to start, shutdown workers, the restart strategies, the worker types. We can create such list by using the `Supervisor.child_spec/2` function.  
For more details, see the [documentation](https://hexdocs.pm/elixir/1.12/Supervisor.html#module-child-specification).
