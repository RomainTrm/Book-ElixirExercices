# 15. Working with multiple processes

Elixir uses the *actor* model of concurrency. An actor is an independent process that shares nothing with other processes. We can *spawn* new processes, send and *receive* messages. These processes are managed by the Erlang VM, using every core of our CPUs.  

## A simple process

Here's a module we want to run in a dedicated process:  

```elixir
defmodule SpawnBasic do
  def greet, do: IO.puts "Hello"
end
```

We can `spawn` a new process:  

```elixir
iex> spawn(SpawnBasic, :greet, [])
Hello
#PID<0.110.0>
```

The `spawn` function returned us *process identifier* (PID), this is a unique ID for our process.  

### Sending messages between processes

In Elixir, we can send messages with the `send` function. It takes a PID and the message to send. The message can be anything but we usually send atoms or tuples.  
We wait for messages with the `receive` function. Like `case`, `receive` can specify several patterns and use guard clauses.  

```elixir
defmodule Spawn do
  def greet do
    receive do
      { sender, msg } ->
        send sender, { :ok, "Hello, #{msg}" }
    end
  end
end

# client side
pid = spawn(Spawn, :geet, [])
send pid, {self(), "World!"}

receive do
  {:ok, message} -> IO.puts message
end

# When this script is executed on IEx, it returns => "Hello, World!"
```

### Handling multiple messages

We can timeout `receive` blocks:  

```elixir
receive do
  {:ok, message} -> IO.puts message
  after 500 -> IO.puts "The greeter has gone away" # time in ms
end
```

A `receive` block can only be called once. Once the `received` has been processed, it exits. To avoid this and listen to new messages, we can use recursion:  

```elixir
defmodule Spawn do
  def greet do
    receive do
      { sender, msg } ->
        send sender, { :ok, "Hello, #{msg}" }
        greet()
    end
  end
end
```

### Recursion, looping and the stack

Recursion isn't an issue with Elixir as the language implements *tail-call optimization* (TCO).  
Reminder:  

```elixir
defmodule NotTCO do
  def factorial(0), do: 1
  def factorial(n), do: n * factorial(n-1)
end

defmodule TCO do
  def factorial(n), do: _fact(n, 1)
  defp _fact(0, acc), do: acc
  defp _fact(n, acc), do: _fact(n-1, acc*n)
end
```

## Process overhead

We can spawn many processes, but the Erlang VM is set up with a limit, we can change that with the `--erl +P`

```elixir
...> elixir -r WorkingWithMultipleProcesses-1.exs -e "Chain.run(1_000_000)"
{3558809, "Result is 1000000"} 
...> elixir -r WorkingWithMultipleProcesses-1.exs -e "Chain.run(2_000_000)"
13:24:00.171 [error] Too many processes
...> elixir --erl "+P 3000000" -r WorkingWithMultipleProcesses-1.exs -e "Chain.run(2_000_000)"
{9428684, "Result is 2000000"}
```

## When processes die

We can kill a process with the `exit` function.  
By default, when a process dies, other processes are not notified.  

### Linking two processes

We can link a process to the new process it spawns by using `spawn_link` instead of `spawn`. This way, if our child process died, it killed the entire application.  
We can handle the death of a child by trapping the exit signal. 

> **Warning: We're not supposed to handle other processes death this way, use OTP framework instead.**

```elixir
defmodule Link do
  import :timer, only: [sleep: 1]

  def sad_function do
    sleep(500)
    exit(:boom)
  end

  def run do
    Process.flag(:trap_exit, true) # With this flag, the "Message received:" will be returned
    spawn_link(Link, :sad_function, [])
    receive do
      msg -> IO.puts "Message received: #{inspect msg}"
      after 1000 -> IO.puts "Nothing happened"
    end
  end
end
```

### Monitoring a process

Linking joins processes in a two-way communication.  
Use *monitoring* to spawn a child process and by notified of its termination, but without the reverse notification (one-way communication).  
We can use `spawn_monitor` to monitor a new process and `Process.monitor` for an existing process.  

## Parallel Map - The "Hello World" of Erlang

We can parallelize mapping for elements of a list. For each element we spawn a new process and get a PID, then we convert processes PIDs to results:  

```elixir
defmodule Parallel do
  def pmap(collection, fun) do
    me = self()
    collection
    |> Enum.map(fn (elem) -> 
      spawn_link fn -> (send me, { self(), fun.(elem) }) end
    end)
    |> Enum.map(fn (pid) -> 
      receive do { ^pid, result } -> result end
    end)
  end
end
```

```elixir
iex> Parallel.pmap 1..10, &(&1 * &1)
[1, 4, 9, 16, 25, 36, 49, 64, 81, 100]
```

## A Fibonacci Server

Here we write a naive Fibonacci algorithm implementation that takes a measurable number of seconds.  
We will compute the 37th Fibonacci number in parallel 20 times. We will repeat this operation with 1 to 10 processes.  
The complete code example is available [here](WorkingWithMultipleProcesses-8.exs).  

```elixir
iex> RunProcesses.run()
[
  {37, 24157817},
  {37, 24157817},
  # ...
  {37, 24157817}
]

 #  Time (s)
 1  4.69
 2  2.34
 3  1.75
 4  1.42
 5  1.44
 6  1.48
 7  1.33
 8  1.31
 9  1.33
10  1.19
:ok
```

Note: this code is really inefficient, here's how we calculate *fib(5)*:  

```text
fib(5)
= fib(4)                                     + fib(3)
= fib(3)                   + fib(2)          + fib(2)          + fib(1)
= fib(2)          + fib(1) + fib(1) + fib(0) + fib(1) + fib(0) + fib(1) 
= fib(1) + fib(0) + fib(1) + fib(1) + fib(0) + fib(1) + fib(0) + fib(1)
```

## Agents - A teaser

Elixir modules are sets of functions, they cannot store states, processes can. Elixir has a module called `Agent` that makes it easy to wrap a process containing a state.  

```elixir
defmodule FibAgent do
  def start_link do
    Agent.start_link(fn -> %{ 0 => 0, 1 => 1 } end)
  end

  def fib(pid, n) when n >= 0 do
    Agent.get_and_update(pid, &do_fib(&1, n))
  end

  defp do_fib(cache, n) do
    case cache[n] do
      nil -> 
        { n_1, cache } = do_fib(cache, n - 1)
        result = n_1 + cache[n - 2]
        { result, Map.put(cache, n, result) }

      cached_value ->
        { cached_value, cache }
    end
  end
end
```

We can compute result instantaneously:  

```elixir
iex> { :ok, agent } = FibAgent.start_link()
{:ok, #PID<0.235.0>}
iex> IO.puts FibAgent.fib(agent, 2000)
4224696333392304878706725602341482782579852840250681098010280137314308584370130707224123599639141511088446087538909603607640194711643596029271983312598737326253555802606991585915229492453904998722256795316982874482472992263901833716778060607011615497886719879858311468870876264597369086722884023654422295243347964480139515349562972087652656069529806499841977448720155612802665404554171717881930324025204312082516817125
:ok
```
