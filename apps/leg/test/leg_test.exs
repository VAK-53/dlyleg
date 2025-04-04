defmodule LegTest do
  use ExUnit.Case
  doctest Leg

  test "greets the world" do
    assert Leg.hello() == :world
  end
end
