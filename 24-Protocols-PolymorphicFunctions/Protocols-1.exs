defprotocol Caesar do
  def encrypt(string, shift)
  def root13(string)
end

defmodule Caesar.Cypher do
  def encrypt(string, shift) do
    string |> Enum.map(&cypher(&1, shift))
  end

  defp cypher(letter, 0), do: letter
  defp cypher(?z, n), do: cypher(?a, n - 1)
  defp cypher(letter, n), do: cypher(letter + 1, n - 1)
end

defimpl Caesar, for: List do
  def root13(string), do: Caesar.Cypher.encrypt(string, 13)
  def encrypt(string, shift), do: Caesar.Cypher.encrypt(string, shift)
end

defimpl Caesar, for: BitString do
  def root13(string), do: string |> to_char_list |> Caesar.Cypher.encrypt(13)
  def encrypt(string, shift), do: string |> to_char_list |> Caesar.Cypher.encrypt(shift)
end

IO.puts Caesar.root13("ryvkve")
# => elixir

IO.puts Caesar.root13(~c"ryvkve")
# => elixir

IO.puts Caesar.encrypt("ryvkve", 13)
# => elixir

IO.puts Caesar.encrypt(~c"ryvkve", 13)
# => elixir
