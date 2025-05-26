defmodule Fib do
  def of(0), do: 1
  def of(1), do: 1
  def of(n), do: of(n-1) + of(n-2)
end

IO.puts("Start the task")
task = Task.async(fn -> Fib.of(20) end)
IO.puts("Do something else...")
IO.puts("Wait for the task")
result = Task.await(task)
IO.puts("Result is: #{result}")
