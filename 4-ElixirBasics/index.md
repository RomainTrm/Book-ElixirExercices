# 4. Elixir basics

## Value types

### Arbitrary sized integers

Can be written as decimal `1234`, hexa `0xcafe`, octal `0o765` and binary `0b001010`.  
We can use the _ as a separator: `1_000_000`.  
There is no size limit for an integer, it grows to fit the magnitude of the value.

### Floating-point numbers

Floating-point numbers are written using the decimal point. There must be at least one digit before and after the point: `1.0`.  
We can use trailing exponent: `0.135156e1` or `5151.054e-2`.  
Floats are IEEE 754 double precision.

### Atoms

An atom is a constant representing something's name, it starts with `:`, followed by an atom word or an Elixir operator.  

An atom word is a sequence of UTF-8 letters (including combining marks), digits, `_` or `@`. It may end with a `!` or a `?`. All the following examples are valid atoms: `:toto`, `:is_binary?`, `:var@2`, `:===`, `:"long atom name"`.  

As atoms are defined by their name, two atoms with the same name are equals, even if they've been created in different applications and machines.

### Ranges

Ranges are represented with the `start..end` syntax where both variables are integers.

### Regular expressions

Elixir has regular expressions literals written as `~r{regexp}` or `~r{regexp}opts`. Here's the list of the available `opts` [modifers](https://hexdocs.pm/elixir/Regex.html#module-modifiers).  

To manipulate these expressions, we use the `Regex` module:  

```elixir
iex> Regex.run ~r{[aeiou]}, "caterpillar"
["a"]
iex> Regex.scan ~r{[aeiou]}, "caterpillar"
[["a"], ["e"], ["i"], ["a"]]
iex> Regex.split ~r{[aeiou]}, "caterpillar"
["c", "t", "rp", "ll", "r"]
iex> Regex.replace ~r{[aeiou]}, "caterpillar", "*"
"c*t*rp*ll*r"
```

## System types

The following types reflect resources in the Erlang VM.

### PIDs and ports

A PID is a reference to a process (local or remote), a port is a reference to a resource we will be writing or reading.  

A new PID is associated with every new process. We can retrieve the PID of the current process with the command `self`:  

```elixir
iex> self
#PID<0.104.0>
```

### References

The function `make_ref` creates a globally unique reference. No other reference will be equal to it. This is not used in this book.

## Collection types

### Tuples

Tuples are ordered collection of values: `{1, 2}`, `{:ok, , 42, "next"}`

Pattern match applies to them:  

```elixir
iex> {status, count, action} = {:ok, 42, "next"}
{:ok, 42, "next"}
iex> status
:ok
iex> count
42
```

### Lists

In Elixir, lists are implemented as linked lists (a tuple is closer to a conventional array).  
Some dedicated operators are available to manipulate them:  

```elixir
iex> [1, 2, 3] ++ [4, 5, 6] # Concatenation
[1, 2, 3, 4, 5, 6]
iex> [1, 2, 3, 4] -- [2, 4] # Difference
[1, 3]
iex> 1 in [1, 2, 3] # Membership
true
iex> "cat" in [1, 2, 3]
false
```

Elixir also provides a shortcut for key/value pairs lists (keyword list):

```elixir
iex> list = [name: "Dave", city: "Dallas"]
[name: "Dave", city: "Dallas"]
iex> list[:name]
"Dave"
iex> list[:city]
"Dallas"
```

The previous list implicitly converted to `[{:name, "Dave"}, {:city, "Dallas"}]`.

Square brackets for keyword list are optional as long as the list is the last argument of a given context (a function, a tuple, ...).  

```elixir
iex> {1, name: "Dave", city: "Dallas"}
{1, [name: "Dave", city: "Dallas"]}
```

### Maps

A map is a collection of key/value pairs:  

```elixir
iex> states = %{ "AL" => "Alabama", "WI" => "Wisconsin" }
%{"AL" => "Alabama", "WI" => "Wisconsin"}
iex> %{:red => 0xff0000, :green => 0x00ff00, :blue => 0x0000ff}
%{blue: 255, green: 65280, red: 16711680}
```

Note 1: We can use a mix of different types of keys.  
Note 2: Atom keys can use the same shortcut as keyword list:  

```elixir
iex> %{red: 0xff0000, green: 0x00ff00, blue: 0x0000ff}
%{blue: 255, green: 65280, red: 16711680}
```

Maps allow a key to be defined only once whereas a keyword list can define it several times. Also a map is more optimized for accessing values.

We can access value as we did with the list:  

```elixir
iex> states = %{ "AL" => "Alabama", "WI" => "Wisconsin" }
%{"AL" => "Alabama", "WI" => "Wisconsin"}
iex> states["AL"]
"Alabama"
iex> states["WI"]
```

For atoms key, there's also a dot notation:

```elixir
iex> colors = %{red: 0xff0000, green: 0x00ff00, blue: 0x0000ff}
%{blue: 255, green: 65280, red: 16711680}
iex> colors[:red]
16711680
iex> colors.red
16711680
```

### Binaries

Binaries allow us to manipulate sequences of bytes and bits.  

```elixir
iex> bin = <<1, 2>>
<<1, 2>>
iex> byte_size bin
2
```

We can control type of size of the elements, here a single byte compose of three elements of 2, 4 and 2 bits:

```elixir
iex> bin = <<3 :: size(2), 5 :: size(4), 1 :: size(2)>>
<<213>>
iex> byte_size bin
1
```

## Dates and times

We have an available type for dates:  

```elixir
iex> {:ok, d1} = Date.new(2025, 05, 03)
{:ok, ~D[2025-05-03]}
iex> d2 = ~D[2025-05-03]
~D[2025-05-03]
iex> d1 == d2
true
iex> Date.add(d1, 7)
~D[2025-05-10]
iex> inspect d1, structs: false
"%{calendar: Calendar.ISO, month: 5, __struct__: Date, day: 3, year: 2025}"
```

We use `~D[]` sigil for dates and `~T[]` for time. We also have a range of dates available:  

```elixir
iex> d1 = ~D[2025-05-03]
~D[2025-05-03]
iex> d2 = ~D[2025-08-03]
~D[2025-08-03]
iex> dateRange = Date.range(d1, d2)
Date.range(~D[2025-05-03], ~D[2025-08-03])
iex> Enum.count(dateRange)
93
iex> ~D[2025-07-12] in dateRange
true
```

There is two date/time types:  

- `NaiveDateTime` that simply combine a `Date` and a `Time`, it can be used with de `~N[]` sigil.
- `DateTime` that combine `Date`, `Time` and an associated timezone.

## Names, source files, conventions, operators, and so on

### Truth

There are three values for Boolean operations: `true`, `false` and `nil`.  
`nil` is treated as `false` in Boolean contexts. They are aliases of atoms of the same name, so `true` equals `:true`.  

In most contexts, values other than `false` and `nil` are treated as `true` (truthy).  

### Operators

For comparisons:  

```elixir
a === b # strict equality, 1 === 1.0 returns false
a !== b # strict inequality, 1 !== 1.0 returns true
a == b # value equality, 1 == 1.0 returns true
a != b # value inequality, 1 != 1.0 returns false
a > b # Normal comparisons
a >= b
a < b
a <= b
```

Boolean operators:  

```elixir
# Following operators expect true or false as the first argument
a or b
a and b
not a

# Following operators check for a truthy first argument
a || b
a && b
!a
```

Arithmetic operators:  

= - * / div rem

Integer division returns a floating-point result, use *div(a, b)* to get an integer.

Join operators:  

```elixir
binary1 <> binary2 # contacts two binaries (and strings)
list1 ++ list2  # contains two lists
list1 -- list2 # remove elements of list2 from a copy of list1
```

The *in* operator:  

```elixir
a in enum # test if a is in a list, a range, a map. For maps, a should be a {key, value} tuple.
```

## Variable scope

### Do-block scope

Return values instead of setting variables inside a block:  

```elixir
# Bad
case integer do
  1 => atom = :one
  2 => atom = :two
end

# Ok
atom = 
  case integer do
    1 => :one
    2 => :two
  end
```

### The with expression

The *with* expression serves two goals:  

- defines a local scope for variables
- it gives some control over pattern-matching failures

```elixir
# with syntax
result = with var1 = ...
              var2 = ...
         do
            do_something(var1, var2)
         end
```

We can use the `<-` operator to retrieve the value that couldn't be matched instead of an exception when using `=`:  

```elixir
iex> with [a | _] = [1, 2, 3], do: a
1
iex> with [a | _] = nil, do: a
** (MatchError) no match of right hand side value: nil
iex> with [a | _] <- [1, 2, 3], do: a
1
iex> with [a | _] <- nil, do: a
nil
```
