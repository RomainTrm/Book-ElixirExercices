defmodule MyList do
  @doc """
    Apply the function passed as parameters to every element of the list and return a new list.

    ## Example
        iex> list = MyList.map [1, 2, 3], &(&1 * 2)
        [2, 4, 6]
        iex> list = MyList.map [1, 2, 3], &(&1 + 3)
        [4, 5, 6]
  """
  def map([], _func), do: []
  def map([head|tail], func), do: [func.(head) | map(tail, func)]
end
