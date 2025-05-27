# 22. Macros and code evaluation

> **Warning**: Never use a macro when we can use a function.  

## Macros inject code

To define macros, we use `defmacro`, `quote` and `unquote`.  
When we pass parameters to a macro, Elixir doesn't evaluate them. Instead, it passes them as tuples representing their code.  

```elixir
defmodule My do
  defmacro macro(params) do
    IO.inspect params
  end
end

defmodule Test do 
  require My

  # These values represent themselves
  My.macro :atom # => :atom
  My.macro 1 # => 1

  # These are represented by 3-element tuples
  My.macro {1, 2, 3, 4, 5}
  # => {:{}, [line: 13], [1, 2, 3, 4, 5]}

  My.macro do: ( a = 1; a + a )
  # => [
  # =>   do: {:__block__, [line: 21],
  # =>    [
  # =>      {:=, [line: 21], [{:a, [line: 21], nil}, 1]},
  # =>      {:+, [line: 21], [{:a, [line: 21], nil}, {:a, [line: 21], nil}]}
  # =>    ]}
  # => ]

  My.macro do 1 + 2 else 3 + 4 end
  # => [do: {:+, [line: 23], [1, 2]}, else: {:+, [line: 23], [3, 4]}]
end
```

### Load order

Macros should be available at compile time. If we declare a macro in the same scope in which we use it, then we'll get an error. A solution is to place macros in dedicated modules to make sure we can load them.  

### The `quote` function

The `quote` function forces code to remain unevaluated.  
This is a way to say, "interpret the following block as code and return the internal representation".

```elixir
iex> quote do: :atom
:atom
iex> quote do: 1
1
iex> quote do: [do: 1]
[do: 1]
iex> quote do: {1, 2, 3, 4, 5}
{:{}, [], [1, 2, 3, 4, 5]}
iex> quote do: [ do: 1 + 2, else: 3 + 4 ]
[
  do: {:+, [context: Elixir, imports: [{1, Kernel}, {2, Kernel}]],
   [1, 2]},
  else: {:+, [context: Elixir, imports: [{1, Kernel}, {2, Kernel}]],
   [3, 4]}
]
```

## Using the representation as code

When calling a macro, Elixir injects the code back into our program and returns to the caller the result of executing that code. In a certain way, we're injecting new code at runtime.  

```elixir
defmodule My do
  defmacro macro(code) do
    IO.inspect code
    quote do: IO.puts "Different code"
  end
end

defmodule Test do
  require My
  My.macro(IO.puts("hello"))
end

# => {{:., [line: 20], [{:__aliases__, [line: 20], [:IO]}, :puts]}, [line: 20], ["hello"]}
# => Different code
```

### The `unquote` function

Inside a `quote` block, we need a way to evaluate and execute injected code, that's the `unquote` function.  

```elixir
defmodule My do
  defmacro macro(code) do
    quote do: IO.inspect(unquote(code))
  end
end

defmodule Test do
  require My
  My.macro(1 + 2)
end

# => 3
```

We also have additional functions:  

```elixir
iex> Code.eval_quoted(quote do: [1, 2, unquote([3, 4])])
{[1, 2, [3, 4]], []}
iex> Code.eval_quoted(quote do: [1, 2, unquote_splicing([3, 4])])
{[1, 2, 3, 4], []}
iex> Code.eval_quoted(quote do: [?a, ?=, unquote_splicing(~c"1,2,3,4")])
{~c"a=1,2,3,4", []}
```

### Back to our myif macro

We can define an if macro as follows:  

```elixir
defmodule My do
  defmacro if(condition, clauses) do
    do_clause = Keyword.get(clauses, :do, nil)
    else_clause = Keyword.get(clauses, :else, nil)
    quote do
      case unquote(condition) do
        val when val in [false, nil] -> unquote(else_clause)
        _                            -> unquote(do_clause)
      end
    end
  end
end

defmodule Test do
  require My
  My.if 1 == 2 do
    IO.puts "1 == 2"
  else
    IO.puts "1 != 2"
  end
end

# => 1 != 2
```

## Using bindings to inject values

Macros are executed at compile time, this means they can't access values that are calculated at runtime.  

```elixir
defmodule My do
  defmacro mydef(name) do
    quote do
      def unquote(name)(), do: unquote(name)
    end
  end
end

defmodule Test do
  require My
  [:fred, :bert] |> Enum.each(&My.mydef(&1))
end

# => Doesn't compile
# => error: invalid syntax in def capture()
```

Bindings solve this issue:  

```elixir
defmodule My do
  defmacro mydef(name) do
    quote bind_quoted: [name: name] do
      def unquote(name)(), do: unquote(name)
    end
  end
end

defmodule Test do
  require My
  [:fred, :bert] |> Enum.each(&My.mydef(&1))
end
```

If we run this code:  

```elixir
iex> IO.puts Test.fred
fred
:ok
```

The `bind_quoted` defers the executions of the `unquote` calls in the body, this way, the methods are defined at runtime.  

## Macros are hygienic

Macros are not substitution of code at runtime, they have both their own scope and scope during execution of the quoted macro body. `import` and `alias` are also locally scoped.  

```elixir
defmodule Scope do
  defmacro update_local(val) do
    local = "some value"
    result = quote do
      local = unquote(val)
      IO.puts "End of macro body, local = #{local}"
    end
    IO.puts "In macro definition, local = #{local}"
    result
  end
end

defmodule Test do
  require Scope

  local = 123
  Scope.update_local("cat")
  IO.puts "On return, local = #{local}"
end

# => In macro definition, local = some value
# => End of macro body, local = cat
# => On return, local = 123
```

## Other ways to run code fragments

We can use `Code.eval_quoted` to evaluate a code fragment.  

```elixir
iex> fragment = quote do: IO.puts("hello")
{{:., [], [{:__aliases__, [alias: false], [:IO]}, :puts]}, [], ["hello"]}
iex> Code.eval_quoted(fragment)
hello
{:ok, []}
```

We can disable the scope on macros by using the `var!(:name)`.  

```elixir
iex> fragment = quote do: IO.puts(var!(a))
{{:., [], [{:__aliases__, [alias: false], [:IO]}, :puts]}, [],
 [
   {:var!, [context: Elixir, imports: [{1, Kernel}, {2, Kernel}]],
    [{:a, [], Elixir}]}
 ]}
iex> Code.eval_quoted fragment, [a: "cat"]
cat
{:ok, [a: "cat"]}
```

We can convert a string containing code with `Code.string_to_quoted` and inversely code to string with `Macro.to_string`.  
We can also directly evaluate a string with `Code.eval_string`.

> **Danger**: Following content shows in the same time promises and dangers of homoiconic languages.

## Macros and operators

We can override unary and binary operators. But we need to remove any existing definition first.  

```elixir
defmodule Operators do
  defmacro a + b do
    quote do
      to_string(unquote(a)) <> to_string(unquote(b))
    end
  end
end

defmodule Test do
  IO.puts(123 + 456) # => "579"
  import Kernel, except: [+: 2]
  import Operators
  IO.puts(123 + 456) # => "123456"
end

IO.puts(123 + 456) # => "579"
```

## Digging ridiculously deep

Every piece of code can be represented by a 3-value tuple.  
However, metadata isn't mandatory, so we can execute code on the fly:  

```elixir
iex> quote do: 1 + 2
{:+, [context: Elixir, imports: [{1, Kernel}, {2, Kernel}]], [1, 2]}
iex> Code.eval_quoted {:+, [], [1, 2]}
{3, []}
```