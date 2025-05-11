defmodule DocsTest do
  use ExUnit.Case
  doctest MyList

  test "greets the world" do
    assert Docs.hello() == :world
  end
end
