# 12. Control flow

There are controls flow constructs in Elixir, but we must don't use a lot as most of the flow can be controlled by a pattern matching.  

## if and unless

```elixir
iex> if 1 == 1, do: "true", else: "false"
"true"
iex> if 1 == 2, do: "true", else: "false"
"false"
iex> unless 1 == 1, do: "error", else: "ok"
"ok"
iex> unless 1 == 2, do: "error", else: "ok"
"error"
```

## cond

The `cond` macro lets us list a series of conditions, each with associated code.  

```elixir
def fizzbuzz(current) do
  cond do 
    rem(current, 3) == 0 and rem(current, 5) == 0 -> "FizzBuzz"
    rem(current, 3) == 0 -> "Fizz"
    rem(current, 5) == 0 -> "Buzz"
    true -> current
  end
end
```

> Note: previous example is a demonstration of the `cond`, we can write it in a more idiomatic way with a pattern matching.  

## case

`case` let us test a value against a set of patterns. This is a way to write a pattern matching locally without defining a function several times.  

```elixir
case File.open("config_file") do
  { :ok, file } -> IO.puts "First line: #{IO.read(file, :line)}"
  { :error, reason } -> IO.puts "Failed to open file: #{reason}"
end
```

## Raising exceptions

Exceptions in Elixir is a **panic mode** response to things that are not supposed to happen. Normal flow for error handling should be done by returning the error as the result of a function.  

```elixir
iex> raise "Giving up"
** (RuntimeError) Giving up
iex> raise RuntimeError
** (RuntimeError) runtime error
iex> raise RuntimeError, message: "override message"
** (RuntimeError) override message
```

## Designing with exceptions

For our previous example, if we expect the code to open the file successfully every time:  

```elixir
case File.open("config_file") do
  { :ok, file } -> process(file)
  { :error, reason } -> raise "Failed to open config file: #{reason}"
end
```

We can even delegate this case to Elixir by not defining the error case:  

```elixir
case File.open("config_file") do
  { :ok, file } -> process(file)
  # Return MatchError exception if the open function doesn't return :ok
end
```

The third solution is the trailing `!`. With it we know the function may fail, we choose to run the happy path and let Elixir raise an exception if an error is returned:  

```elixir
file = File.open!("config_file")
```
