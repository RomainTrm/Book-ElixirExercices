# Pattern matching

## Assignments and equality

The `=` operator is the *match operator*, meaning it tests for equality.  

```elixir
iex> a = 1
1
iex> a + 2
3
iex> 1 = a
1
iex> 2 = a
** (MatchError) no match of right hand side value: 1
```

When we write `iex> a = 1`, it acts as an assignment, but we can read it as "*a* equals 1, so *a* is 1".

## More complex matches

Here are some more complex pattern matches with lists:

```elixir
iex> list = [ 1, 2, [ 3, 4, 5 ]]
[1, 2, [3, 4, 5]]
iex> [a, b, c] = list # valid pattern match, list contains 3 elements
[1, 2, [3, 4, 5]]
iex> a
1
iex> c
[3, 4, 5]
iex> [a, 2, b] = list # valid pattern match, 2nd value is 2
[1, 2, [3, 4, 5]]
iex> [a, 1, b] = list # invalid pattern match, 2nd value isn't 1
** (MatchError) no match of right hand side value: [1, 2, [3, 4, 5]]
```

## Ignoring a value

As with F#, the wildcard `_` operator is available to ignore a value in a pattern.  

```elixir
iex> [1, _, _] = [1, 2, 3]
[1, 2, 3]
iex> [1, _, _] = [1, "cat", :dog]
[1, "cat", :dog]
```

## Variables bind once (per match)

Once set in a match, a variable is reused for equality:

```elixir
iex> [a, a] = [1, 1]
[1, 1]
iex> [b, b] = [1, 2]
** (MatchError) no match of right hand side value: [1, 2]
```

A variable can be redefined in a subsequent match:

```elixir
iex> a = 1
1
iex> [1, a, 3] = [1, 2, 3]
[1, 2, 3]
iex> a
2
```

To force the equality with the existing value, we have to prefix the variable with `^`:

```elixir
iex> a = 1
1
iex> [^a, 2] = [1, 2]
[1, 2]
iex> [^a, 2] = [2, 2]
** (MatchError) no match of right hand side value: [2, 2]
```
