# 14. Tooling

## Debugging with IEx

There are two ways to set a breakpoint in our code: by injecting it with IEx or with a dedicated instruction in our code.  

## Injecting breakpoints using IEx.pry

We can inject breakpoints by using the `pry` macro.  

```elixir
# Some code before ...
require IEx; IEx.pry
# Some code after ...
```

When calling the code in IEx, it will stop at breakpoints:  

```elixir
...> iex -S mix
iex> Buggy.parse_header << 0, 1, 0, 8, 0, 120 >>
Break reached: Buggy.parse_header/1 (buggy.ex:9)

    6:       division::integer-16
    7:       >>
    8:   ) do
    9:     require IEx; IEx.pry
   10:     IO.puts("format: #{format}")
   11:     IO.puts("tracks: #{tracks}")
   12:     IO.puts("division: #{decode(division)}")

iex> binding
[division: 120, format: 1, tracks: 8]
iex> continue
format: 1
tracks: 8
** (FunctionClauseError) no function clause matching in Buggy.decode/1
```

Calling the `binding` function shows us every variable in the current scope and their values. The `continue` function resumes code execution.  

In this piece of code, *division*'s type is the issue, we've declared an integer, but we expect a binary (note: compiler was also able to detect this issue). Pry shows us the integer value 120. If we fix the code and debug again:  

```elixir
iex> r Buggy # Reloading module once we have fixed it
{:reloaded, [Buggy]}
iex> Buggy.parse_header << 0, 1, 0, 8, 0, 120 >>
Break reached: Buggy.parse_header/1 (buggy.ex:9)

    6:       division::bits-16 # fixed version
    7:       >>
    8:   ) do
    9:     require IEx; IEx.pry
   10:     IO.puts("format: #{format}")
   11:     IO.puts("tracks: #{tracks}")
   12:     IO.puts("division: #{decode(division)}")

iex> binding
[division: <<0, 120>>, format: 1, tracks: 8] # division as a binary value here
iex> continue
format: 1
tracks: 8
division: 0 fps, 120/frame
:ok
```

## Setting breakpoints with Break

The second way to add breakpoints doesn't require any code change. We setup breakpoints from IEx using the `break!` command.  

```elixir
iex> require IEx # Seems unnecessary
IEx
iex> break! Buggy.decode/1
1
iex> breaks

 ID   Module.function/arity   Pending stops
---- ----------------------- ---------------
 1    Buggy.decode/1     

iex> Buggy.parse_header << 0, 1, 0, 8, 0, 120 >>
format: 1
tracks: 8
Break reached: Buggy.decode/1 (lib/buggy.ex:22)

   19:   end
   20:
   21:   def decode(<< 0::1, fps::7, beats::8 >>) do
   22:     "#{-fps} fps, #{beats}/frame"
   23:   end
   24: end

iex> binding
[] # example in the book shows variables of the parse_header scope, doesn't seem logical to me as we have hit the decode function.
```

## Testing

### Testing the comments

We have the possibility to documents our functions and to attach them some iex sessions as examples:  

```elixir
defmodule MyList do
  @doc """
    Apply the function passed as parameters to every element of the list and return a new list.

    ## Example
        iex> list = MyList.map [1, 2, 3], &(&1 * 2)
        [2, 4, 6]
        iex> list = MyList.map [1, 2, 3], &(&1 + 3)
        [4, 5, 6]
  """
  def map([], _func), do: []
  def map([head|tail], func), do: [func.(head) | map(tail, func)]
end
```

The issue of these comments is they're usually not maintained, they get staled and becomes useless.  
ExUnit has *doctest*, this is a tool that extract iex sessions examples from our `@doc` strings, runs it and checks that the output is still correct.  

```elixir
defmodule DocTest do
  use ExUnit.Case
  doctst MyList
end
```

To run doctests:  

```elixir
...> mix test test/docs_test.exs
Running ExUnit with seed: 594664, max_cases: 16
# ...
Finished in 0.08 seconds (0.00s async, 0.08s sync)
1 doctest, 1 test, 0 failures
```

Note: these tests are also integrated in the overall test suite.  

If we force an error:  

```elixir
...> mix test test/docs_test.exs
# ...
  1) doctest MyList.map/2 (1) (DocsTest)
     test/docs_test.exs:3
     Doctest failed
     doctest:
       iex> list = MyList.map [1, 2, 3], &(&1 + 3)
       [4, 5, 5]
     code:  list = MyList.map([1, 2, 3], &(&1 + 3)) === [4, 5, 5]
     left:  [4, 5, 6]
     right: [4, 5, 5]
     stacktrace:
       lib/myList.ex:8: MyList (module)
```

### Structuring tests

For tests, we can define `describe` sections to regroup them and `setup` sections to regroup default values:  

```elixir
defmodule TestStats do
  use ExUnit.Case

  describe "Stats on lists of ints" do
    setup do  
      [ list:  [1, 3? 5, 7, 9, 11] 
        sum:   36,
        count: 6
      ]
    end

    test "calculate sum", fixture do
      assert Stats.sum(fixture.list) == fixture.sum
    end

    # Other tests
  end
end
```

`setup` is called before each test run and values are passed as `fixture`. A `setup_all` function also exists and is invoked only once for the test session. Cleanup functions like `on_exit` are also available.  
For more details, see ExUnit [documentation](https://hexdocs.pm/ex_unit/main/ExUnit.html).

### Property-based testing

To do PBT, we first have to import a library. There are several choices available, here we will use `StreamData`.  
In the `mix.exs` file:

```elixir
defp deps do
  [
    { :stream_data, ">= 0.0.0" },
  ]
end
```

And then use it:  

```elixir
defmodule StatsPropertyTest do
  use ExUnit.Case
  use ExUnitProperties

  describe "Stats on lists of ints" do
    property "single element lists are their own sum" do
      check all number <- number integer() do
        assert Stats.sum([number]) == number
      end
    end

    # Other tests
  end
end
```

We can add conditions on generated values and parameters to generators.  
See `StreamData`'s [documentation](https://hexdocs.pm/stream_data/ExUnitProperties.html) for more details.

### Test coverage

There are tools like [excoveralls](https://github.com/parroty/excoveralls) or [coverex](https://github.com/alfert/coverex) for measuring code coverage.  

## Code dependencies

When compiling a project, mix does dependencies analysis. We can access this information with the `mix xref` command:  

- `mix xref unreachable`: List functions that are unknown at the time they are called.
- `mix xref warnings`: List warnings associated with dependencies.
- `mix xref callers Mod | Mod.func | Mod.func/arity`: List callers for the module/function.
- `mix xref graph`: Show the dependency tree of the application.

Using [dot](https://graphviz.org/), we can customize the graph rendering:  

```text
...> mix xref graph --format dot
...> dot -Grankdir=LR -Epenwidth=2 -Ecolor=#a0a0a0 -Tpng xref_graph.dot -o xreg_graph.png
```

## Server monitoring

Erlang VM comes with some built-in server-monitoring tools. We can access them through IEx:  

```elixir
iex> :observer.start()
# This opens a GUI tool
```

Other tools like [Elixometer](https://github.com/pinterest/elixometer) are also available.  

## Source-code formatting

There is a tool to automatically fix code formatting issues, we can run it (at our own risks) with the `mix format` command.  
