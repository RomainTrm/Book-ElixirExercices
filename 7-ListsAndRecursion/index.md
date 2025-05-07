# 7. Lists and recursion

## Heads and tails

Elixir's *list* are *linked lists*. This means a list is defined as an element follow by a list.  
An empty list is defined like this: `[]`  
A list of one element: `[1]` that is equivalent to `[1 | []]` (a head `1` followed by an empty list).  

```elixir
iex> [1 | [2 | [3 | []]]]
[1, 2, 3]
```

We can apply pattern matching to lists:  

```elixir
iex> [a, b, c] = [1, 2, 3]
[1, 2, 3]
iex> a
1
iex> [head | tail] = [1, 2, 3]
[1, 2, 3]
iex> head
1
iex> tail
[2, 3]
```

## Using head and tail to process a list

With this head-tail pattern, we can process lists, for example get the number of elements:  

```elixir
defmodule MyList do
  def len([]), do: 0
  def len([_head|tail]), do: 1 + len(tail)
end
```

It executes like this:  

```text
len([1, 2, 3])
= 1 + len([2, 3])
= 1 + 1 + len([3])
= 1 + 1 + 1 + len([])
= 1 + 1 + 1 + 0
= 3
```

## Creating a map function

We can create a `map` function that takes a `list` and a `function` as parameters, it applies the `function` to every element of the `list`:  

```elixir
defmodule MyList do
  def map([], _func), do: []
  def map([head|tail], func), do: [func.(head) | map(tail, func)]
end
```

Then we can use it:  

```elixir
iex> MyList.map [1, 2, 3], &(&1 * 2)
[2, 4, 6]
```

## Reducing a list to a single value

We can also go through the list and accumulate its elements into a single value, this is a `reduce` function:  

```elixir
defmodule MyList do
  def reduce([], value, _func), do: value
  def reduce([head|tail], value, func), do: reduce(tail, func.(head, value), func)
end
```

And then we can use it:  

```elixir
iex> MyList.reduce [1, 2, 3], 0, &(&1 + &2)
6
```

## More complex list patterns

We can place the tail wherever we want: `[a, b, c | tail]`

## The List module in action

There is a `List` module available to manipulate linked lists.  
