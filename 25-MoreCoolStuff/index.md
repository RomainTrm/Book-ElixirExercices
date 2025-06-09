# 25. More cool stuff

## Writing your own sigils

Here's a sigil `~l` that takes multiline string and returns a list containing each line:  

```elixir
defmodule LineSigil do
  @doc """
  Implement the `~l` sigil, which takes a string containing
  multiple lines and returns a list of those lines.

  ## Example usage

    iex> import LineSigil
    nil
    iex> ~l\"""
    ...> one
    ...> two
    ...> three
    ...> \"""
    ["one", "two", "three"]
  """  
  def sigil_l(lines, _opts) do
    lines |> String.trim_trailing |> String.split("\n")
  end
end
```

Because `sigil_l` is in lowercase, it supports string interpolation. If our sigil were `~L{...}` (define with `sigil_L`), then no interpolation would be performed.  
To override existing functions like `sigil_C`, `sigil_c`, etc., we have to explicitly import the `Kernel` module and use the `except` clause.  

### Picking up the options

We'll override the `~c` sigil to specify color constants.  

```elixir
defmodule ColorSigil do
  @color_map [
    rgb: [red: 0xff0000, green: 0x00ff00, blue: 0x0000ff],
    hsb: [red: {0, 100, 100}, green: {120, 100, 100}, blue: {240, 100, 100}]
  ]

  def sigil_c(color_name, []), do: _c(color_name, :rgb)
  def sigil_c(color_name, 'r'), do: _c(color_name, :rgb)
  def sigil_c(color_name, 'h'), do: _c(color_name, :hsb)

  defp _c(color_name, color_space) do
    @color_map[color_space][String.to_atom(color_name)]
  end

  defmacro __using__(_opts) do # Override the sigil of scopes that call the use of our module
    quote do
      import Kernel, except: [sigil_c: 2] # Exclude existing sigil
      import unquote(__MODULE__), only: [sigil_c: 2] # Import our sigil override
    end
  end
end

defmodule Example do
  use ColorSigil

  def rgb, do: IO.inspect ~c{red}
  def hsb, do: IO.inspect ~c{red}h
end

# iex> Example.rgb
# 16711680
# iex> Example.hsb
# {0, 100, 100}
```

## Multi-app umbrella projects

As project grows, we may want to split the code into multiple libraries or apps. Mix makes it easy.  
Elixir calls these multi-app projects *umbrella projects*.  

### Create an umbrella project

First, we create the umbrella project:

```elixir
...> mix new --umbrella eval
```

### Create the subprojects

Then, we can create the subprojects:  

```elixir
eval> cd eval/apps
eval/apps> mix new line_sigil
eval/apps> mix new evaluator
```

Now, we can try our umbrella project:  

```elixir
eval/apps> cd ..
eval> mix compile
==> evaluator
Compiling 1 file (.ex)
Generated evaluator app
==> line_sigil
Compiling 1 file (.ex)
Generated line_sigil app
```

It is still possible to create a umbrella project afterwhile. We simply have to create it and then move existing projects into the `app` folder.

See [code implementation](./eval/apps/) of both projects.  
We can use the code from another project in the `app` folder simply by referencing the desired module: `import LineSigil`.  

```elixir
eval> mix test
==> evaluator
Running ExUnit with seed: 597849, max_cases: 16

..
Finished in 0.1 seconds (0.00s async, 0.1s sync)
2 tests, 0 failures
==> line_sigil
There are no tests to run
```
