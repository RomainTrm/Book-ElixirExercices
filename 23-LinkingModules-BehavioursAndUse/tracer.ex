defmodule Tracer do
  def dump_args(args) do
    args |> Enum.map(&inspect/1) |> Enum.join(", ")
  end

  def dump_defn(name, args) do
    "#{name}(#{dump_args(args)})"
  end

  defmacro def(definition={name,_,args}, do: content) do
    quote do
      Kernel.def(unquote(definition)) do
        IO.puts "==> call: #{Tracer.dump_defn(unquote(name), unquote(args))}"
        result = unquote(content)
        IO.puts "<== result: #{result}"
        result
      end
    end
  end

  defmacro __using__(_opts) do
    quote do
      import Kernel, except: [def: 2]
      import unquote(__MODULE__), only: [def: 2]
    end
  end
end

defmodule Test do
  use Tracer

  def puts_sum_three(a, b, c), do: IO.inspect(a+b+c)
  def add_list(list), do: Enum.reduce(list, 0, &(&1+&2))
end
