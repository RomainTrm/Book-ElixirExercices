# 11. Strings and Binaries

## String literals

- Can hold UTF-8 characters
- May contains escape sequences (\r, \n, etc.)
- Allow interpolation: `"Hello, #{name}"`
- Can escape special characters with a backslash
- Support *heredocs*

### Heredocs

Regular string support multiline but keep text indentation. *heredocs* notation fixes this by using the triple string delimiter: `'''` or `"""`.  

### Sigils

We can write regex with the `~r{...}` syntax. These ~-style literals are called *sigils*.  
For more details, see the [documentation](https://hexdocs.pm/elixir/main/sigils.html).  

~C: A character list with no escaping or interpolation
~c: A character list with some escaping and interpolation
~D: A Date in the format yyyy-mm-dd
~N: A naive DateTime in the format yyyy-mm-dd hh:mm:ss[.ddd]
~R: A regular expression with no escaping or interpolation
~r: A regular expression escaped and interpolated
~S: A string with no escaping or interpolation
~s: A string with some escaping and interpolation
~T: A Time in the format hh:mm:ss[.ddd]
~W: A list of whitespace-delimited words, with no escaping or interpolation
~w: A list of whitespace-delimited words, with some escaping and interpolation

```elixir
iex> ~w[the c#{'a'}t lay on my book]
["the", "cat", "lay", "on", "my", "book"]
iex> ~w[the c#{'a'}t lay on my book]a
warning: using single-quoted strings to represent charlists is deprecated.
[:the, :cat, :lay, :on, :my, :book]
```

We can define our own sigils.  

## The name "strings"

In Elixir, `"cat"` is a string, `'cat'` is a character’s list.  
These are different and **libraries working on strings only work with the double-quoted form**.

## Single-quoted strings - Lists of character codes

Single-quoted strings are represented as a list of integer values, each value corresponding to a character.  

> Note: single quote notation `'wombat'` is deprecated, now use the `~c` sigil instead: `~c"wombat"`.  

```elixir
iex> str = ~c"wombat"
~c"wombat"
iex> is_list str
true
iex> length str
6
iex> Enum.reverse str
~c"tabmow"
iex> [67, 65, 84]
~c"CAT"
iex> :io.format "~w~n", [str]
[119,111,109,98,97,116]
:ok
```

We can use list pattern matching as well:  

```elixir
iex> ~c"pole" ++ ~c"vault"
~c"polevault"
iex> ~c"pole" -- ~c"vault"
~c"poe"
iex> [head | tail] = ~c"cat"
~c"cat"
iex> head
99
iex> tail
~c"at"
iex> [head|tail]
~c"cat"
```

The notation `?c` returns the integer code for a character, it can be used pattern matches:  

```elixir
iex> ?-
45
iex> [head | tail] = ~c"-123"
~c"-123"
iex> head
45
iex> [?- | tail] = ~c"-123"
~c"-123"
iex> tail
~c"123"
```

## Binaries

The Binary type represents a sequence of bits, it follows the syntax `<< term... >>`.  
Simplest term is a number from 0 to 255. They are stored as successive bytes.  

```elixir
iex> b = << 1, 2, 3 >>
<<1, 2, 3>>
iex> byte_size b
3
iex> bit_size b
24
```

We can use modifier:  

```elixir
iex> b = <<1::size(2), 1::size(3)>> # 01 001
<<9::size(5)>>
```

We can store integers, floats and other binaries:  

```elixir
iex> int = << 1 >>
<<1>>
iex> float = << 2.5 :: float >>
<<64, 4, 0, 0, 0, 0, 0, 0>>
iex> mix = << int :: binary, float :: binary >>
<<1, 64, 4, 0, 0, 0, 0, 0, 0>>
```

Finally, we can extract bits:  

```elixir
iex> << sign::size(1), exp::size(11), mantissa::size(52) >> = << 3.14159::float >>
<<64, 9, 33, 249, 240, 27, 134, 110>>
iex> sign
0
iex> exp
1024
iex> mantissa
2570632149304942
iex> (1 + mantissa / :math.pow(2, 52)) * :math.pow(2, exp-1023) * (1 - 2 * sign)
3.14159
```

## Double-quoted strings are binaries

Single-quoted strings are stored as char lists, double-quoted strings are stored as binaries.  
This representation can be more efficient but it as two caveats:  

- the size of the binary isn't always equal to the size of the string
- we cannot benefit from the enumerable functions

### Strings and Elixir libraries

There is a `String` module available, see full [documentation](https://hexdocs.pm/elixir/main/String.html).  
It contains various functions like `at`, `capitalize`, `downcase`, `length` and so on.  
When Elixir documentation uses the word *string*, it means double-quoted strings. Usually it uses the word *binary*.  

## Binaries and pattern matching

For patterns, we can specify a type: `binary`, `bits`, `bitstring`, `bytes`, `float`, `integer`, `utf8`, `utf16` or `utf32`.  
We can also add qualifiers:  

- `size(n)`: The size of the field in bits
- `signed` or `unsigned`: for integers fields, should it be interpreted as signed?
- endianness: `big`, `little` or `native`

Example: `<< length::unsigned-integer-size(12), flags::bitstring-size(4) >>`
