# 3. Immutability

In Elixir, all values are immutable.

## Performance implications of immutability

### Copy data

Thanks to immutability, we can reuse existing values to produce new one:  

```elixir
iex> list1 = [1, 2, 3]
[1, 2, 3]
iex> list2 = [4 | list1]
[4, 1, 2, 3]
```

In the previous example, we define a list `list1`, then we define a second list `list2` that is the value `4` followed by all the values in `list1`. Such construction is possible because we know that values in `list1` will never change.

### Garbage collection

In Elixir, we code using processes, each of them has its own heap :  

- smaller heaps mean faster garbage collection
- when the process terminates, all its data is discarded and no garbage collection is required
