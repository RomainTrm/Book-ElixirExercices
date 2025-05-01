defmodule Parallel do
  def pmap(collection, func) do
    collection
    |> Enum.map(&(Task.async(fn -> func.(&1) end)))
    |> Enum.map(&(Task.await/1))
  end
end

# Get the square of element by kicking a new process, using all cores of the CPU
# iex> result = Parallel.pmap 1..10000, &(&1 * &1)
