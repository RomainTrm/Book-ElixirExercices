# 24. Protocols - Polymorphic functions

Protocols are a way to extend modules' functionalities without modifying them.  

## Defining a protocol

Defining a protocol is like defining a module, but functions will not have bodies, they are there simply to declare the interface that the protocol requires:  

```elixir
defprotocol Inspect do
  @fallback_to_any true
  def inspect(thing, opts)
end
```

## Implementing a protocol

We use the `defimpl` macro to define the implementation of a protocol:  

```elixir
defimpl Inspect, for: PID do
  def inspect(pid, _opts) do
    "#Process" <> IO.iodata_to_binary(:erlang.pid_to_list(pid)) <> "!!"
  end
end

defimpl Inspect, for: Reference do
  def inspect(ref, _opts) do
    ~c"#Ref" ++ rest = :erlang.ref_to_list(ref) 
    "#Reference" <> IO.iodata_to_binary(rest)
  end
end
```

```elixir
iex> inspect self
"#PID<0.104.0>"
iex> defimpl Inspect, for: PID do
...>   def inspect(pid, _opts) do
...>     "#Process" <> IO.iodata_to_binary(:erlang.pid_to_list(pid)) <> "!!"
...>   end
...> end
warning: redefining module Inspect.PID (current version defined in memory)
{:module, Inspect.PID, <<70, 79, ...>>, {:inspect, 2}}
iex> inspect self
"#Process<0.104.0>!!"
```

## The available types

We can define protocol implementations for the following types: `Any`, `Atom`, `BitString`, `Float`, `Function`, `Integer`, `List`, `Map`, `PID`, `Port`, `Record`, `Reference`, `Tuple`.  

The type `Any` is a catchall, allowing us to define an implementation of any type. If we have another implementation for a specific type, we have to put it before the implementation of `Any`. Though, by default Elixir doesn't rout other types to the `Any` implementation, to allow this routing we must use the `@fallback_to_any true` annotation.  

We can also list multiple types on a single `defimpl`:  

```elixir
defprotocol Collection do
  @fallback_to_any true
  def is_collection?(value)
end

defimpl Collection, for: [List, Tuple, BitString, Map] do
  def is_collection?(_), do: true
end

defimpl Collection, for: Any do
  def is_collection?(_), do: false
end

Enum.each [1, 1.0, [1, 2], {1, 2}, %{}, "cat"], fn value -> 
  IO.puts "#{inspect value}: #{Collection.is_collection?(value)}"
end

# => 1: false
# => 1.0: false
# => [1, 2]: true
# => {1, 2}: true
# => %{}: true
# => "cat": true
```

## Protocols and Structs

Structs are just maps with a key `__struct__` referencing the struct's module:  

```elixir
iex> defmodule Blob do
...>   defstruct content: nil
...> end
{:module, Blob, <<70, 79, 82, ...>>, %Blob{content: nil}}
iex> b = %Blob{content: 123}
%Blob{content: 123}
iex> inspect b
"%Blob{content: 123}"
iex> inspect b, structs: false
"%{__struct__: Blob, content: 123}"
```

## Built-in Protocols

Elixir comes with the following protocols:  

- `Enumerable` and `Collectable`
- `Inspect`
- `List.Chars`
- `String.Chars`

We're going to implement them for the following code:  

```elixir
defmodule Midi do
  defstruct(content: <<>>)

  defmodule Frame do
    defstruct(
        type: "xxxx",
        length: 0,
        data: <<>>
    )

    def to_binary(%Midi.Frame{type: type, length: length, data: data}) do
      <<
        type::binary-4,
        length::integer-32,
        data::binary
      >>
    end
  end

  def from_file(name) do
    %Midi{content: File.read!(name)}
  end
end
```

### Built-in Protocols: Enumerable and Collectable

The `Enumerable` protocol is defined by four functions:  

```elixir
defprotocol Enumerable do
  def count(collection)
  def member?(collection, value)
  def reduce(collection, acc, fun)
  def slice(collection)
end
```

We will implement `reduce/3` and `count/1`, for the two other functions we'll pass a default `{:error, __MODULE__}` implementation.  
However, we also want to enumerate our `Midi` type lazily. For this we can look at the `reduce` documentation:  

```elixir
iex>  h Enumerable.reduce

                        def reduce(enumerable, acc, fun)

  @spec reduce(t(), acc(), reducer()) :: result()

Reduces the enumerable into an element.

Most of the operations in Enum are implemented in terms of reduce. This
function should apply the given t:reducer/0 function to each element in the
enumerable and proceed as expected by the returned accumulator.

See the documentation of the types t:result/0 and t:acc/0 for more information.

## Examples

As an example, here is the implementation of reduce for lists:

    def reduce(_list, {:halt, acc}, _fun), do: {:halted, acc}
    def reduce(list, {:suspend, acc}, fun), do: {:suspended, acc, &reduce(list, &1, fun)}
    def reduce([], {:cont, acc}, _fun), do: {:done, acc}
    def reduce([head | tail], {:cont, acc}, fun), do: reduce(tail, fun.(head, acc), fun)
```

And here's how we implement it:  

```elixir
  ## Reduce
  # Housekeeping function for laizy handling
  def _reduce(_content, {:halt, acc}, _fun) do
    {:halted, acc}
  end

  # Housekeeping function for laizy handling
  def _reduce(content, {:suspend, acc}, fun) do
    {:suspended, acc, &_reduce(content, &1, fun)}
  end

  def _reduce(_content = "", {:cont, acc}, _fun) do
    {:done, acc}
  end

  def _reduce(<<
        type::binary-4,
        length::integer-32,
        data::binary-size(length),
        rest::binary
      >>,
      {:cont, acc},
      fun) do
    frame = %Midi.Frame{type: type, length: length, data: data}
    _reduce(rest, fun.(frame, acc), fun)
  end

  def reduce(%Midi{content: content}, acc, fun) do
    _reduce(content, acc, fun)
  end

  ## Count
  def count(midi = %Midi{}) do
    frame_count = Enum.reduce(midi, 0, fn (_, count) -> count + 1 end)
    {:ok, frame_count}
  end
```

```elixi
...> iex.bat midi.exs
iex> midi = Midi.from_file("ABBA_-_Dancing_Queen.mid")
%Midi{
  content: <<77, 84, 104, 100, 0, 0, 0, 6, 0, 0, 0, 1, 0, 96, 77, 84, 114, 107,
    0, 1, 16, 89, 0, 255, 84, 5, 96, 0, 3, 0, 0, 0, 255, 33, 1, 0, 0, 240, 5,
    126, 127, 9, 1, 247, 0, 255, 33, 1, 0, ...>>
}
iex> Enum.take(midi, 2)
[
  %Midi.Frame{type: "MThd", length: 6, data: <<0, 0, 0, 1, 0, 96>>},
  %Midi.Frame{
    type: "MTrk",
    length: 69721,
    data: <<0, 255, 84, 5, 96, 0, 3, 0, 0, 0, 255, 33, 1, 0, 0, 240, 5, 126,
      127, 9, 1, 247, 0, 255, 33, 1, 0, 0, 255, 88, 4, 4, 2, 24, 8, 0, 255, 89,
      2, 0, 0, 0, 255, 81, 3, ...>>
  }
]
iex> Enum.count midi
2
```

Rest of the chapter does the same thing for `Collectable` then `Inspect` protocols.  
We can look at the implementation in the [midi.exs](midi.exs) file.  

```elixir
# Collectable
iex> list = Enum.to_list(midi)
[
  %Midi.Frame{type: "MThd", length: 6, data: <<0, 0, 0, 1, 0, 96>>},
  %Midi.Frame{
    type: "MTrk",
    length: 69721,
    data: <<0, 255, 84, 5, 96, 0, 3, 0, 0, 0, 255, 33, 1, 0, 0, 240, 5, 126,
      127, 9, 1, 247, 0, 255, 33, 1, 0, 0, 255, 88, 4, 4, 2, 24, 8, 0, 255, 89,
      2, 0, 0, 0, 255, 81, 3, ...>>
  }
]
iex> new_midi = Enum.into(list, %Midi{})
%Midi{
  content: <<77, 84, 104, 100, 0, 0, 0, 6, 0, 0, 0, 1, 0, 96, 77, 84, 114, 107,
    0, 1, 16, 89, 0, 255, 84, 5, 96, 0, 3, 0, 0, 0, 255, 33, 1, 0, 0, 240, 5,
    126, 127, 9, 1, 247, 0, 255, 33, 1, 0, ...>>
}
iex> new_midi == midi
true

# Inspect without algebra
iex> midi = Midi.from_file("ABBA_-_Dancing_Queen.mid")
#Midi[
#Midi.Header{Midi format: 0, tracks: 1, timing: 96 bpm}
#Midi.Track{length: 69721, data: <<0, 255, 84, 5, 96, 0, 3, 0, 0, 0, 255, 33, 1, 0, 0, 240, 5, 126, 127, 9, 1, 247, 0, 255, 33, 1, 0, 0, 255, 88, 4, 4, 2, 24, 8, 0, 255, 89, 2, 0, 0, 0, 255, 81, 3, 9, 30, 106, 103, 193, ...>>}
]

# Inspect with algebra
iex> midi = Midi.from_file("ABBA_-_Dancing_Queen.mid")
#Midi[
  #Midi.Header{
    Midi format: 0
    tracks: 1
    timing: 96 bpm
  },
  #Midi.Track[
    length: 69721,
    data: <<0, 255, 84, 5, 96, 0, 3, 0, 0, 0, 255, 33, 1, ...>>
  ]
]
```
