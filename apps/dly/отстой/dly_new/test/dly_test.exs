defmodule DlyTest do
  use ExUnit.Case
  doctest Dly

  test "greets the world" do
    assert Dly.hello() == :world
  end
end
