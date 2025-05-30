# 23. Linking modules: Behavio(u)rs and use

When declaring OTP servers, we used the `use GenServer` notation. This is how inject behaviors.

## Behaviors

An Elixir behavior is a list of functions. A module that implements a behavior must implement all the associated functions. If it doesn't, Elixir generates a compilation warning.  
We can think of behaviors as interfaces in OOP, by declaring it, we let the compiler check that all the expected functions are provided.  

### Defining behaviors

We define a behavior with `@callback` definitions.  
For example, the `Mix.Scm` module contains:  

```elixir
defmodule Mix.SCM do
  # ...

  @callback fetchable? :: boolean

  @callback format(opts) :: String.t

  # ...
end
```

This example uses Erlang type specification, see [chapter 25](../25-MoreCoolStuff/) for details.  

### Declaring behaviors

We declare a behaviour using the `@behaviour` attribute.  

```elixir
defmodule Mix.SCM.Git do
  @behaviour Mix.SCM

  def fetchable?, do: true
  def format(opts), do: opts[:git]
  # ...
end
```

### Taking it further

In a given module, we can have functions to implement the behavior alongside other functions. We can use the `@impl` annotation to identify functions implementing the behavior.  

```elixir
defmodule Mix.SCM.Git do
  @behaviour Mix.SCM

  def init(args) do # Plain function
    # ...
  end

  @impl Mix.SCM # callback
  def fetchable?, do: true

  @impl Mix.SCM # callback
  def format(opts), do: opts[:git]
  # ...
end
```

### `use` and `__using__`

The `use` function calls the `__using__` function/macro of the module passed as parameters.  
This is usefull to inject behavior callbacks and associated default implementations into our modules.  

## Putting it together - tracing method calls

Here's an example where we want to trace functions calls and results.

```elixir
defmodule Tracer do
  def dump_args(args) do
    args |> Enum.map(&inspect/1) |> Enum.join(", ")
  end

  def dump_defn(name, args) do
    "#{name}(#{dump_args(args)})"
  end

  defmacro def(definition={name,_,args}, do: content) do
    quote do
      Kernel.def(unquote(definition)) do
        IO.puts "==> call: #{Tracer.dump_defn(unquote(name), unquote(args))}"
        result = unquote(content)
        IO.puts "<== result: #{result}"
        result
      end
    end
  end

  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [def: 2]
      import unquote(__MODULE__), only: [def: 2]
    end
  end
end

defmodule Test do
  use Tracer

  def puts_sum_three(a, b, c), do: IO.inspect(a+b+c)
  def add_list(list), do: Enum.reduce(list, 0, &(&1+&2))
end
```

```elixir
iex > Test.puts_sum_three(1,2,3)
==> call: puts_sum_three(1, 2, 3)
6
<== result: 6
6
iex> Test.add_list([5,6,7,8])
==> call: add_list([5, 6, 7, 8])
<== result: 26
26
```
