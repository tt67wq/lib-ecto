defmodule LibEctoTest do
  use ExUnit.Case
  doctest LibEcto

  test "greets the world" do
    assert LibEcto.hello() == :world
  end
end
