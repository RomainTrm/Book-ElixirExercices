# Appendix 1. Exceptions: raise and try, catch and throw

With Elixir, we don't do so much error-handling thanks to the actor pattern.  
We use exception for things that are not supposed to happen.  

## Raising an exception

We can raise an exception by using the `raise` function, it produces a `RuntimeError`:  

```elixir
iex> raise "Giving up"
** (RuntimeError) Giving up
    iex:1: (file)
iex> raise RuntimeError
** (RuntimeError) runtime error
    iex:1: (file)
iex> raise RuntimeError, message: "override message"
** (RuntimeError) override message
    iex:1: (file)
```

We can intercept exceptions with the `try` function. It takes a block of code to execute and can be followed by optional `rescue`, `catch` and `after` clauses.  
With `rescue` and `catch` we can pattern match errors and make decisions.  

```elixir
# exception.ex
defmodule Boom do
  def start(n) do
    try do
      raise_error(n)
    rescue
      [ FunctionClauseError, RuntimeError ] ->
        IO.puts "no function match or runtime error"
      error in [ArithmeticError] ->
        IO.inspect error
        IO.puts "Oh! Arithmetic error"
        reraise "Too late", __STACKTRACE__
      other_errors ->
        IO.puts "Disaster! #{inspect other_errors}"
    after
      IO.puts "DONE!"
    end
  end

  defp raise_error(0) do
    IO.puts "No error"
  end

  defp raise_error(val = 1) do
    IO.puts "About to divide by zero"
    1 / (val - 1)
  end

  defp raise_error(2) do
    IO.puts "About to call a function that doesn't exist"
    raise_error(99)
  end

  defp raise_error(3) do
    IO.puts "About to try to open a file that doesn't exist"
    File.open!("/doesnt-exist")
  end
end
```

```elixir
iex> c("exception.ex")
[Boom]
iex> Boom.start 1
About to divide by zero
%ArithmeticError{message: "bad argument in arithmetic expression"}
Oh! Arithmetic error
DONE!
** (RuntimeError) Too late
    exception.ex:25: Boom.raise_error/1
    exception.ex:4: Boom.start/1
    iex:2: (file)
iex> Boom.start 2
About to call a function that doesn`t exist
no function match or runtime error
DONE!
:ok
iex> Boom.start 3
About to try to open a file that doesn`t exist
Disaster! %File.Error{reason: :enoent, path: "/doesnt-exist", action: "open"}
DONE!
:ok
```

## catch, exit and throw

There is a second kind of error that is generated when a process calls `error`, `exit` or `throw`.  
They all take a parameter that is available to the `catch` handler.  

```elixir
# catch.ex
defmodule Catch do
  def start(n) do
    try do
      incite(n)
    catch
      :exit, code -> "Exited with code #{inspect code}"
      :throw, value -> "Throw called with #{inspect value}"
      what, value -> "Caught #{inspect what} with #{inspect value}"
    end
  end

  defp incite(1) do
    exit(":something_bad_happened")
  end

  defp incite(2) do
    throw {:animal, "Wombat"}
  end

  defp incite(3) do
    :erlang.error "Oh no!"
  end
end
```

```elixir
iex> c("catch.ex")
[Catch]
iex> Catch.start 1
"Exited with code \":something_bad_happened\""
iex> Catch.start 2
"Throw called with {:animal, \"Wombat\"}"
iex> Catch.start 3
"Caught :error with \"Oh no!\""
```

## Defining your own exceptions

Elixir exceptions are basically record. We can define exceptions using the `defexception`.  

```elixir
# defexception.ex
defmodule KinectProtocolError do
  defexception message: "Kinect protocol error",
               can_retry: false

  def full_message(me) do
    "Kinect failed: #{me.message}, retriable: #{me.can_retry}"
  end
end

defmodule Test do
  def run do
    try do
      raise KinectProtocolError
    rescue
      error in [KinectProtocolError] ->
        IO.puts KinectProtocolError.full_message(error)
        if error.can_retry, do: IO.puts "Schedule retry"
    end
  end
end
```

```elixir
iex> c("defexception.ex")
[KinectProtocolError, Test]
iex> Test.run
Kinect failed: Kinect protocol error, retriable: false
nil
```

## Now ignore this appendix

As mentioned earlier, handling exception isn't the way we're supposed to use Elixir. Instead we should think in terms of isolation with dedicated processes.
