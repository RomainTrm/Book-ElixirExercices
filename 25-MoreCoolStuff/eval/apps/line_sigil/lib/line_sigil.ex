defmodule LineSigil do
  @doc """
  Implement the `~l` sigil, wich takes a string containing
  multiple lines and returns a list of those lines.

  ## Example usage

    iex> import LineSigil
    nil
    iex> ~l\"""
    ...> one
    ...> two
    ...> three
    ...> \"""
    ["one", "two", "three"]
  """
  def sigil_l(lines, _opts) do
    lines |> String.trim_trailing |> String.split("\n")
  end
end
