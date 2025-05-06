# 6. Modules and named functions

Here’s a module `Times` with a function `double` in a file named *Times.exs*:  

```elixir
defmodule Times do
  def double(n) do
    n * 2
  end
end
```

## Compiling a module

We can compile and load this file in iex:  

```elixir
..> iex times.exs
# OR
iex> c "times.exs"
[Times]
iex> Times.double(8)
16
```

## The function's body is a block

There is several ways to write the body of a function, the default way is by using the `do..end` block, but there is a shorter version:  

```elixir
def double(n), do: n * 2
```

It is possible to have several lines with this notation by adding parentheses:  

```elixir
def greet(greeting, name), do: (
  IO.puts greeting
  IO.puts "How're you doing, #{name}?"
)
```

## Function calls and pattern matching

The pattern matching applies to named function in the same way it does for anonymous functions. Here's an example of a function that sum every positive integer from *1* to *n*:  

```elixir
defmodule Math do
  def sum(1), do: 1
  def sum(n), do: n + sum(n-1) 
end
```

This works in the same way as Haskell pattern match: we define a pattern in the function signature. At runtime, Elixir uses the first function that matches the parameters. If *n* is equal to *1*, then it will use the first definition, otherwise it fallbacks to the second one. Note that function declaration order matters, if `sum(n)` is declared before `sum(1)`, then `sum(1)` will never be called. In such case, Elixir's compiler returns a warning.  

## Guard clauses

As some constraints cannot be expressed through a pattern, we have the possibility to add guard clauses in our pattern matches with the `when` keyword. On our previous example, we now want to make sure *n* is a positive integer:  

```elixir
defmodule Math do
  def sum(1), do: 1
  def sum(n) when is_integer(n) and n > 0 do
    n + sum(n-1)
  end
end
```

Be aware that not all guard clauses are allowed in the pattern matching : [doc](https://hexdocs.pm/elixir/main/patterns-and-guards.html#guards).  

## Default parameters

We have the possibility to define default values for function parameters:  

```elixir
def func(p1, p2 \\ 2, p3 \\ 3, p4) do
  IO.inspect [p1, p2, p3, p4]
end

iex> func("a", "b") # => ["a", 2, 3, "b"]
iex> func("a", "b", "c") # => ["a", "b", 3, "c"]
iex> func("a", "b", "c", "d") # => ["a", "b", "c", "d"]
```

Default parameter values can create troubles with the pattern matching as Elixir may be unable to determine which implementation to call. The following example returns a compilation error:  

```elixir
def func(p1, p2 \\ 2, p3 \\ 3, p4) do
  IO.inspect [p1, p2, p3, p4]
end

def func(p1, p2) do
  IO.inspect [p1, p2]
end
```

The following example also fails to compile:  

```elixir
def func(p1, p2 \\ 123), do: IO.inspect [p1, p2]
def func(p1, 99), do: IO.puts "you said 99"
```

To fix it, we can add a function head (without a body) that defines the default parameter value:  

```elixir
def func(p1, p2 \\ 123)
def func(p1, p2), do: IO.inspect [p1, p2]
def func(p1, 99), do: IO.puts "you said 99"
```

## Private functions

We can declare private functions that can only be called within the modules that declare it. To do so we use `defp` instead of `def`.  
We can declare several heads for pattern matching but we cannot mix public and private heads.

## The amazing pipe operator: |>

Elixir provides a pipe operator (`|>`) that takes the result of the expression on the left side, and pass it as the **first** (unlike F#) argument of the expression on the right side.  

```elixir
iex> h(Enum.map)
    def map(enumerable, fun)
...
iex> (1..10) |> Enum.map(&(&1 * &1)) |> Enum.filter(&(&1 < 40))
[1, 4, 9, 16, 25, 36]
```

## Modules

Modules define namespaces to put things on.  
We can nest modules:  

```elixir
defmodule Mod do
  defmodule SubMod do
    ...
  end
end
```

In reality, Elixir does convert it to a module `Mod.SubMod`, so we can also write:  

```elixir
defmodule Mod.SubMod do
  ...
end
```

### Directives for modules

#### The import directive

We can import module functions/macros inside the current scope (function, module) by using the `import`. It must follow the syntax: `import Module [, only:|except:]`.  
For example `import List, only: [flatten: 1]`

#### The alias directive

We can create aliases for modules for reducing typing, for example `alias My.Other.Module.Parser, as: Parser`  
The previous example can be simplified to `alias My.Other.Module.Parser` as we reuse last part of the module's name.  
We can even create aliases for several modules at once: `alias My.Other.Module.{Parser, Runner}`  

#### The require directive

We have to use `require` of a module in order to use macros it defines.

## Module attributes

We can define and access attributes with the `@`:  

```elixir
defmodule Example do
  @author "Romain"
  def get_author do
    @author
  end
end
```

An attribute can be redefined several times in the same module.

## Module names: Elixir, Erlang and atoms

Internally, modules' names are just atoms, Elixir converts it internally and prefixes them with *Elixir.*:  

```elixir
iex> is_atom IO
true
iex> to_string IO
"Elixir.IO"
iex> :"Elixir.IO" === IO
true
iex> IO.puts 123
123
:ok
iex> :"Elixir.IO".puts 123
123
:ok
```

## Calling a function in a Erlang library

To call an Erlang function/module, we use it as an atom:  

```elixir
iex> :io.format("The number is ~3.1f~n", [5.678])
The number is 5.7
:ok
```

## Finding libraries

Existing libraries are available on [hex.pm](https://hex.pm/).
