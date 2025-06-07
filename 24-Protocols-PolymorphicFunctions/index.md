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

    def from_file(name) do
      %Midi{content: File.read!(name)}
    end
  end
end
```

### Built-in Protocols: Enumerable and Collectable
