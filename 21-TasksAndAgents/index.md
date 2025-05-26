# 21. Tasks and Agents

Sometimes, we need an abstraction between the low-level `spawn` and `receive` and the high-level OTP.  
Tasks and Agents are two Elixir abstractions that use OTP's features but insulate us from these details.

## Tasks

An Elixir `Task` is a function that runs in the background.  

```elixir
# task.exs
defmodule Fib do
  def of(0), do: 1
  def of(1), do: 1
  def of(n), do: of(n-1) + of(n-2)
end

IO.puts("Start the task")
task = Task.async(fn -> Fib.of(20) end)
IO.puts("Do something else...")
IO.puts("Wait for the task")
result = Task.await(task)
IO.puts("Result is: #{result}")
```

```elixir
..> elixir task.exs
Start the task
Do something else...
Wait for the task
Result is: 10946
```

### Tasks and Supervision

Tasks are implemented as OTP servers, meaning we can add them to our application's supervision tree.  

`Task` lifecycle differs in case of a crash. Using `Task.async` require us to call `Task.await` to terminate the task. Using `Task.start_link` terminates the task immediately.  

We can also declare tasks in a Supervisor's children:  

```elixir
children = [
  { Task, fn -> dp_something() end }
]
Supervisor.start_link(children, strategy: :one_for_one)
```

This can be embedded in a dedicated module:  

```elixir
defmodule MyApp.MyTask do
  use Task

  def start_link(param) do
    Task.start_link(__MODULE__, :thing_to_run, [ params ])
  end

  def thing_to_run(param) do
    IO.puts "running task with #{param}"
  end
end
```

```elixir
children = [
  { MyApp.MyTask, 123 }
]
```

See `Task`'s [documentation](https://hexdocs.pm/elixir/Task.html) for more details.

## Agents

An Elixir `Agent` is a background process that maintains a state.  
We set an initial state at the start the agent with a function. At any moment we can get the actual state using the `Agent.get` and update it with `Agent.update`.  

```elixir
iex> { :ok, count } = Agent.start(fn -> 0 end)
{:ok, #PID<0.105.0>}
iex> Agent.get(count, &(&1))
0
iex> Agent.update(count, &(&1+1))
:ok
iex> Agent.update(count, &(&1+1))
:ok
iex> Agent.get(count, &(&1))
2
```

As for any processes, we can add a name to an agent:  

```elixir
iex> Agent.start(fn -> 99 end, name: Sum)
{:ok, #PID<0.105.0>}
iex> Agent.get(Sum, &(&1))
99
```

A typical use of Agents is to maintain the state of a module:  

```elixir
# agent_dict.exs
defmodule Frequency do
  def start_link do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def add_word(word) do
    Agent.update(
      __MODULE__,
      fn dic ->
        Map.update(dic, word, 1, &(&1+1))
      end)
  end

  def count_for(word) do
    Agent.get(__MODULE__, fn dic -> Map.get(dic, word) end)
  end

  def words do
    Agent.get(__MODULE__, &Map.keys/1)
  end
end
```

If we use it, the state is maintained:  

```elixir
iex> c "agent_dict.exs"
[Frequency]
iex> Frequency.start_link
{:ok, #PID<0.112.0>}
iex> Frequency.add_word "dave"
:ok
iex> Frequency.words
["dave"]
iex> Frequency.add_word "was"
:ok
iex> Frequency.add_word "here"
:ok
iex> Frequency.add_word "he"
:ok
iex> Frequency.add_word "was"
:ok
iex> Frequency.words
["dave", "he", "here", "was"]
iex> Frequency.count_for("dave")
1
iex> Frequency.count_for("was")
2
```

See `Agent`'s [documentation](https://hexdocs.pm/elixir/Agent.html) for more details.

## A bigger example

In the [`anagrams.exs`](./anagrams.exs) file, we've built a module that finds anagrams in dictionaries. These are referenced in parallel by using tasks and then stored in memory with an agent.  

```elixir
...> iex anagrams.exs
iex> Dictionary.start_link
{:ok, #PID<0.113.0>}
iex> Enum.map(1..4, &"words/list#{&1}") |> WordListLoader.load_from_files
[:ok, :ok, :ok, :ok]
iex> Dictionary.anagrams_of "organ"
["ronga", "rogan", "organ", "nagor", "groan", "grano", "goran", "argon", "angor"]
```

### Making it distributed

As agents and tasks are OTP servers, we can easily distribute them across nodes. This is a one-line change to set a globally accessible name:  

```elixir
@name {:global, __MODULE__}
```

```elixir
# Window 1
...> iex --sname one anagrams.exs
iex(one@machine-name)>

# Window 2
...> iex --sname two anagrams.exs
iex(two@machine-name)> Node.connect :"one@machine-name"
true
iex(two@machine-name)> Node.list
[:"one@machine-name"]

# Window 1
iex(one@machine-name)> Dictionary.start_link
{:ok, #PID<0.122.0>}
iex(one@machine-name)> Enum.map(1..2, &"words/list#{&1}") |> WordListLoader.load_from_files
[:ok, :ok]

# Window 2
iex(two@machine-name)> Enum.map(3..4, &"words/list#{&1}") |> WordListLoader.load_from_files
[:ok, :ok]

# Window 1
iex(one@machine-name)> Dictionary.anagrams_of "organ"
["ronga", "rogan", "organ", "nagor", "groan", "grano", "goran", "argon", "angor"]

# Window 2
iex(two@machine-name)> Dictionary.anagrams_of "organ"
["ronga", "rogan", "organ", "nagor", "groan", "grano", "goran", "argon", "angor"]
# => Same result: state is shared across nodes 
```

## Agents and Tasks, or GenServer?

We can eliminate the need to make a decision by wrapping our agents and tasks in modules. That way we can always switch implementation without affecting the rest of the codebase.
