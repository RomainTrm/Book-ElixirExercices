# 8. Maps, Keyword lists, Sets and Structs

## How to choose between Maps, Structs, and Keyword lists

I want to pattern-match againts the content => use map  
I want more thant one entry with the same key => use keyword list  
I want to guarantee the elements are ordered => use keyword list  
I have a fixe set of fields (the data is always the same) => use a struct  
Otherwise => use a map

## Keyword lists

Keyword lists are typically used in the context of options passed to functions:  

```elixir
defmodule Canvas do
  @defaults [ fg: "black", bg: "white", font: "Merriweather" ]

  def draw_text(text, options \\ []) do 
    options = Keyword.merge(@defaults, options)
    IO.puts "Drawing test #{inspect(text)}"
    IO.puts "Foreground: #{options[:fg]}"
    IO.puts "Background: #{Keyword.get(options, :bg)}"
  end
end
```

```elixir
iex> Canvas.draw_text("Hello")
Drawing test "Hello"
Foreground: black
Background: white
:ok
iex> Canvas.draw_text("Hello", fg: "red")
Drawing test "Hello"
Foreground: red
Background: white
:ok
```

## Maps

Maps are the go-to key/value data structure, here are some functions from the `Map` module:  

```elixir
iex> map = %{ name: "Dave", likes: "Programming", where: "Dallas" }
%{name: "Dave", where: "Dallas", likes: "Programming"}
iex> Map.keys map
[:name, :where, :likes]
iex> Map.values map
["Dave", "Dallas", "Programming"]
iex> map[:name]
"Dave"
iex> map.name
"Dave"
iex> Map.drop map, [:where, :likes]
%{name: "Dave"}
iex> Map.has_key? map, :where
true
```

## Pattern matching and updating maps

For the map `person = %{ name: "Dave", height: 1.88 }`:  

- Is there an entry with key `:name`?  

```elixir
iex> %{ name: a_name } = person
%{name: "Dave", height: 1.88}
iex> a_name
"Dave"
```

- Are there entries for the keys `:name` and `:height`?

```elixir
iex> %{ name: _, height: _ } = person
%{name: "Dave", height: 1.88}
```

- Does the entry with key `:name` have the value "Dave"?

```elixir
iex> %{ name: "Dave" } = person
%{name: "Dave", height: 1.88}
```

But if we try to find a key that doesn't exists:  

```elixir
iex> %{ weight: _ } = person
** (MatchError) no match of right hand side value: %{name: "Dave", height: 1.88}
```

Note: we can use pattern matching to extract values, here in a list with the `for` syntax:  

```elixir
people = [
  %{ name: "Dave", height: 1.88 },
  %{ name: "Bob", height: 1.63 },
  %{ name: "John", height: 1.56 }
]

IO.inspect(for person = %{ height: height } <- people, height > 1.6, do: person)
# => [%{name: "Dave", height: 1.88}, %{name: "Bob", height: 1.63}]
```

### Pattern matching can't bind keys

We can't bind a value to a key during pattern matching:

```elixir
iex> %{ 2 => state} = %{ 1 => :ok, 2 => :error }
%{1 => :ok, 2 => :error}
iex> state
:error
iex> { item => :ok } = %{ 1 => :ok, 2 => :error }
** (SyntaxError) invalid syntax found on iex:23:8:
```

### Pattern matching can match variables keys

We can use the pin operator on the left-hand side of a match:  

```elixir
person = %{ name: "Dave", height: 1.88 }
for key <- [:name, :height] do
  %{ ^key => value } = person
  value
end
# => ["Dave", 1.88]
```

## Updating a Map

We can create a copy of a map with a modification: `new_map = %{ old_map | key => value, ...}`  

```elixir
iex> person = %{ name: "Dave", height: 1.88 }
%{name: "Dave", height: 1.88}
iex> %{ person | height: 1.77 }
%{name: "Dave", height: 1.77}
```

Be careful, we can't add a new key to a map using this syntax, to do so we must use `Map.put_new/3` instead.  

## Structs

Maps are anonymous key/value data structures, Elixir doesn't know what is in there until it tries to access it.  
A struct is a typed map with a fixed set of fields and default values. We can pattern match structs by type as wall well as content.  

```elixir
defmodule Subscriber do
  defstruct name: "", paid: false, over_18: true
end
```

```elixir
iex> %Subscriber{}
%Subscriber{name: "", paid: false, over_18: true}
iex> %Subscriber{ name: "Dave" }
%Subscriber{name: "Dave", paid: false, over_18: true}
iex> %Subscriber{ name: "Mary", paid: true }
%Subscriber{name: "Mary", paid: true, over_18: true}
```

We can apply manipulate such struct in the same way as maps:  

```elixir
iex> s = %Subscriber{ name: "Mary" }
%Subscriber{name: "Mary", paid: false, over_18: true}
iex> s.name
"Mary"
iex> %Subscriber{ over_18: over_18} = s
%Subscriber{name: "Mary", paid: false, over_18: true}
iex> over_18
true
iex> s2 = %Subscriber{ s | paid: true }
%Subscriber{name: "Mary", paid: true, over_18: true}
```

## Nested dictionary structures

We can nest structures:  

```elixir
defmodule Customer do
  defstruct name: "", company: ""
end

defmodule BugReport do
  defstruct owner: %Customer{}, details: "", severity: 1
end
```

Then we can manipulate:  

```elixir
iex> report = %BugReport{owner: %Customer{name: "Dave", company: "Pragmatic"}, details: "broken"}
%BugReport{
  owner: %Customer{name: "Dave", company: "Pragmatic"},
  details: "broken",
  severity: 1
}
iex> report.owner.name
"Dave"
iex> report = %BugReport{ report | owner: %Customer{ report.owner | company: "PragProg" }}
%BugReport{
  owner: %Customer{name: "Dave", company: "PragProg"},
  details: "broken",
  severity: 1
}
```

Accessing values deep in a data structure for an update can be complex.  
Elixir provides dedicated functions to update values inside a nested dictionary structure:  

```elixir
# put_in set a value
iex> new_report = put_in(report.owner.name, "Mary")
%BugReport{
  owner: %Customer{name: "Mary", company: "PragProg"},
  details: "broken",
  severity: 1
}
# update_in apply a function to the existing value
iex> new_report = update_in(report.owner.name, &("Mr. " <> &1))
%BugReport{
  owner: %Customer{name: "Mr. Dave", company: "PragProg"},
  details: "broken",
  severity: 1
}
```

### Nested accessors and nonstructs

These functions are also available for maps, we have to use atoms to access the desired property:  

```elixir
iex> report = %{owner: %{name: "Dave", company: "Pragmatic"}, details: "broken"}
%{owner: %{name: "Dave", company: "Pragmatic"}, details: "broken"}
iex> new_report = put_in(report[:owner][:company], "PragProg")
%{owner: %{name: "Dave", company: "PragProg"}, details: "broken"}
```

### Dynamic (runtime) nested accessors

These accessors are macros, they operate at compile time. As a result:  

- the number of keys we pass a particular call is static
- we can't pass the set of keys as parameters between functions

```elixir
iex> report = %{owner: %{name: "Dave", company: "Pragmatic"}, details: "broken"}
%{owner: %{name: "Dave", company: "Pragmatic"}, details: "broken"}
iex> get_in(report, [:owner, :name])
"Dave"
```

Note: `get_in` and `get_and_update_in` macros accept functions as a key, that function is invoked to return the corresponding values.  

```elixir
authors = [
    %{ name: "José", language: "Elixir" },
    %{ name: "Matz", language: "Ruby" },
    %{ name: "Larry", language: "Perl" }
]
language_with_an_r = fn (:get, collection, next_fn) ->
  for row <- collection do
    if String.contains?(row.language, "r") do
      next_fn.(row)
    end
  end
end

IO.inspect get_in(authors, [language_with_an_r, :name])
# => ["José", nil, "Larry"]
# Ruby is ignored because it doesn't contains a lowercase "r"
```

### The Access module

An `Access` module is available with a set of functions to use as parameters to `get_in` and `get_and_update_in`. More details [here](https://hexdocs.pm/elixir/1.12/Access.html#functions).  

```elixir
cast = [
  %{ character: "Buttercup", actor: {"Robin", "Wright"}, role: "princess" },
  %{ character: "Westley", actor: {"Carey", "Elwes"}, role: "farm boy" }
]
IO.inspect get_in(cast, [Access.all(), :actor, Access.elem(1)])
# => ["Wright", "Elwes"]
```

## Sets

Sets are implemented using the module [`MapSet`](https://hexdocs.pm/elixir/1.12/MapSet.html).  
