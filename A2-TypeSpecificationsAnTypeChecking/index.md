# Appendix 2. Type specifications and type checking

## When specifications are used

Type specifications come from Erlang where exported public function is preceded by a `-spec` line:  

```erlang
-spec return_error(integer(), any()) -> no_return().
return_error(Line, Message) ->
    throw({error, {Line, ?MODULE, Message}}).
```

This allows Erlang developers to document their code and also run static analysis to spot type mismatches with tools like [dialyzer](https://www.erlang.org/doc/apps/dialyzer/dialyzer.html).  

We can have the same benefits in Elixir with the `@spec` attribute. In IEx we have the `s` helper for displaying specifications and `t` for user-defined types. Erlang tools (such as dialyzer) are also available.  

```elixir
iex> t(Enum)
@type acc() :: any()

@type default() :: any()

@type element() :: any()

@type index() :: integer()

@type t() :: Enumerable.t()
```

## Specifying a type

A type is a subset of all possible values of the language. `integer` means all the possible integer values, but excludes other values like lists or PIDs. `any` (and its wildcard `_`) means a set of all values, `none` an empty set and *nil* can be represented with `nil`.  

### Collection types

We declare lists with `[integer]`, a non-empty list is declared like `[integer,...]`.  

Binaries are declared with the syntax:  

- `<<>>` for empty binary.
- `<<_:: size>>` for a sequence of *size* bits.
- `<<_::size * unit_size>>` for a sequence of *size* unit where every unit is *unit_size* bits long.

Tuples are declared with the syntax `{integer, atom}` or `tuple(integer, atom)`.

### Combining types

For integers, we can use the range `..` operator to combine types.  
For other types we must use the union `|` operator.

### Structures

We can define types for structures as well:  

```elixir
defmodule LineItem do
  defstruct sku: "", quantity: 1
  @type t :: %LineItem{sku: String.t, quantity: integer}
end
```

### Anonymous functions

Anonymous functions are specified using `(head -> return_type)`. We can use `...` as a header for an arbitrary arity.

```elixir
(... -> integer)
(() -> String.t)
(integer, atom -> list(atom))
(list(integer) -> integer)
((list(integer)) -> integer)
```

### Handling truthy values

Type `as_boolean(T)` says the function that uses the `T` value treat is as a truthy value (anything other than `false` or `nil` is `true`).  

## Defining new types

We can specify types with the `@type type_namme :: type_specification`.  

```elixir
@type term :: any
@type binary :: <<_::_ * 8>>
@type boolean :: true | false
@type byte :: 0..255
@type list(t) :: [ t ]
```

We also have `@typep` to declare a local type that remains private to the module and `opaque` that define a type whose name may be known outside of the module but whose definition is not.

## Specs for functions and callbacks

`@spec` defines a function:  

```elixir
@spec function_name(param1_type, ...) :: return_type
```

Examples:  

```elixir
@type key :: any
@type value :: any
@type keys :: [key]
@type t :: tuple | list # t is the type of the collection

@spec values(t) :: [value]
@spec size(t) :: non_neg_integer
@spec has_key?(t, key) :: boolean
@spec update(t, key, value, (value -> value)) :: t
```

We can specify multiple specifications for functions with multiple heads:  

```elixir
@spec at(t, index) :: element | nil
@spec at(t, index, default) :: element | default
def at(collection, n default \\ nil) do
    # ...
end
```

More details on the typespecs, see the [documentation](https://hexdocs.pm/elixir/typespecs.html).

## Using Dialyzer

We've created a project called *simple* with the following module:  

```elixir
defmodule Simple do
  @type atom_list :: list(atom)
  @spec count_atoms(atom_list) :: non_neg_integer
  def count_atoms(list) do
    nil # no behavior yet
  end
end
```

We add the dependency [dialyxir](https://hex.pm/packages/dialyxir) to our project, then we get it, compile and run the analysis:  

```elixir
...> mix deps.get
...> mix compile
...> mix dialyzer
Finding suitable PLTs
Checking PLT...
# Many lines ...

Starting Dialyzer
[
  # ...
]
Total errors: 1, Skipped: 0, Unnecessary Skips: 0
done in 0m6.74s
lib/simple.ex:3:invalid_contract
The @spec for the function does not match the success typing of the function.

Function:
Simple.count_atoms/1

Success typing:
@spec count_atoms(atom_list()) :: non_neg_integer()

________________________________________________________________________________
done (warnings were emitted)
```

It shows us we have an issue, `Simple.count_atoms` doesn't return the expected type. Let's fix it:  

```elixir
defmodule Simple do
  @type atom_list :: list(atom)
  @spec count_atoms(atom_list) :: non_neg_integer
  def count_atoms(list) do
    length list
  end
end
```

Then run analysis again:  

```elixir
...> mix dialyzer
Compiling 1 file (.ex)
# ...

Starting Dialyzer
[
  # ...
]
Total errors: 0, Skipped: 0, Unnecessary Skips: 0
done in 0m3.59s
done (passed successfully)
```

If we add a second module and run the analysis:  

```elixir
defmodule Client do
  @spec other_function() :: non_neg_integer
  def other_function do
    Simple.count_atoms [1, 2, 3]
  end
end
```

```elixir
 mix dialyzer
Compiling 1 file (.ex)
# ...

Starting Dialyzer
[
    # ...
]
Total errors: 2, Skipped: 0, Unnecessary Skips: 0
done in 0m3.43s
lib/client.ex:3:7:no_return
Function other_function/0 has no local return.
________________________________________________________________________________
lib/client.ex:4:12:call
The function call will not succeed.

Simple.count_atoms([1, 2, 3])

breaks the contract
(atom_list()) :: non_neg_integer()

________________________________________________________________________________
done (warnings were emitted)
```

We've got an error because we've passed as parameters a list that doesn't match the `list(atom)` contract.  
If we replace list content with atoms, then the error disappears.  

### Dialyzer and type inference

Dialyzer also does a decent job with unannotated code because it knows the types of the built-in functions.

```elixir
defmodule NoSpecs do
  def length_plus_n(list, n) do
    length(list) + n
  end
  
  def call_it do
    length_plus_n(1, 2)
  end
end
```

```elixir
...>  mix dialyzer
Compiling 2 files (.ex)
# ...
Total errors: 2, Skipped: 0, Unnecessary Skips: 0
done in 0m3.28s
lib/no_specs.ex:6:7:no_return
Function call_it/0 has no local return.
________________________________________________________________________________
lib/no_specs.ex:7:5:call
The function call will not succeed.

NoSpecs.length_plus_n(1, 2)

will never return since the 1st arguments differ
from the success typing arguments:

([any()], number())

________________________________________________________________________________
done (warnings were emitted)
```

It detected that the first argument passed in `call_it` isn't a list and will fail at runtime.  
If we fix it and make another error on the second argument:  

```elixir
defmodule NoSpecs do
  def length_plus_n(list, n) do
    length(list) + n
  end
  
  def call_it do
    length_plus_n([1, 2], :c)
  end
end
```

```elixir
...> mix dialyzer
Compiling 1 file (.ex)
# ...

Total errors: 2, Skipped: 0, Unnecessary Skips: 0
done in 0m3.32s
lib/no_specs.ex:6:7:no_return
Function call_it/0 has no local return.
________________________________________________________________________________
lib/no_specs.ex:7:5:call
The function call will not succeed.

NoSpecs.length_plus_n([1, 2], :c)

will never return since the 2nd arguments differ
from the success typing arguments:

([any()], number())

________________________________________________________________________________
done (warnings were emitted)
```

Because of the `+`, it recognized that the second argument is expected to be a numeric. So it assigned a default typespec to our `length_plus_n` function.
