# 5. Anonymous functions

As Elixir is a functional language, functions are a basic type. We can build anonymous functions with the `fn` keyword:  

```elixir
iex> sum = fn a, b -> a + b end
#Function<41.81571850/2 in :erl_eval.expr/6>
iex> sum.(1, 4)
5
iex> greet = fn -> "Hello" end
#Function<43.81571850/0 in :erl_eval.expr/6>
iex> greet.()
"Hello"
```

> Note: parentheses are optional, `fn a, b ->` and `fn (a, b) ->` are two valid ways to declare functions parameters.

## Functions and pattern matching

The pattern matching is available for anonymous functions, here we expect a tuple of two elements:  

```elixir
iex> swap = fn {a, b} -> {b, a} end
#Function<42.81571850/1 in :erl_eval.expr/6>
iex> swap.({5, 9})
{9, 5}
```

We can reuse the same name for distinct variables in a pattern, in such case variables must be equal:  

```elixir
iex> test = fn {a, a} -> a end
#Function<42.81571850/1 in :erl_eval.expr/6>
iex> test.({1, 1})
1
iex> test.({1, 2})
** (FunctionClauseError) no function clause matching in :erl_eval."-inside-an-interpreted-fun-"/1
```

## One function, multiple bodies

We can define multiple bodies with distinct arguments (**warning**: each function body must have the same number of parameters.):  

```elixir
handle_open = fn
    {:ok, file} -> "Read data: #{IO.read(file, :line)}"
    {_, error} -> "Error: #{:file.format_error(error)}"
end
handle_open.(File.open(...)) # Call first body if the file exists, otherwise it fallback to the second body
```

## Functions can return functions

Functions can be returned by a function, this allows us to curry functions. Unfortunately, Elixir doesn't seem to support currying by default, we have to write it by ourselves:  

```elixir
iex> add = fn a -> fn b -> a + b end end
#Function<42.81571850/1 in :erl_eval.expr/6>
iex> add_five = add.(5)
#Function<42.81571850/1 in :erl_eval.expr/6>
iex> add_five.(3)
8
iex> add.(4).(2)
6
```

## Passing functions as arguments

As functions are values, we can return them, but we can also pass them as parameters:  

```elixir
iex> times_2 = fn n -> n * 2 end
#Function<42.81571850/1 in :erl_eval.expr/6>
iex> apply = fn (fun, value) -> fun.(value) end
#Function<41.81571850/2 in :erl_eval.expr/6>
iex> apply.(times_2, 8)
16
```

### Pinned values and function parameters

The pin value `^` defined for pattern matching is also available with function parameters:  

```elixir
defmodule Greeter do
    def for(name, greeting) do
        fn
            (^name) -> "#{greeting} #{name}"
            (_) -> "I don't know you"
    end
end

mr_valim = Greeter.for("José", "Oi!")
IO.puts mr_valim.("José") # => Oi! José
IO.puts mr_valim.("Dave") # => I don't know you
```

### The & notation

There is a short notation using the `&` operator.  

```elixir
iex> sum = &(&1 + &2) # Same as sum = fn (a, b) -> a + b end 
&:erlang.+/2
iex> sum.(4, 5)
9
```

Parameters order matters:  

```elixir
iex> concat = &("#{&1} #{&2}")
#Function<41.81571850/2 in :erl_eval.expr/6>
iex> concat.("a", "b")
"a b"
iex> concat = &("#{&2} #{&1}")
#Function<41.81571850/2 in :erl_eval.expr/6>
iex> concat.("a", "b")
"b a"
```

We can reuse a parameter:  

```elixir
iex> divrem = &{ div(&1, &2), rem(&1, &2) }
#Function<41.81571850/2 in :erl_eval.expr/6>
iex> divrem.(13, 5)
{2, 3}
```

There is a second and even shorter version we can use. We can specify the name and arity (number of parameters) of an existing function and it will build an anonymous function that calls it:  

```elixir
iex> len = &Enum.count/1
&Enum.count/1
iex> len.([1, 2, 3])
3
```
