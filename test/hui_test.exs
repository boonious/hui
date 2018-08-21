defmodule HuiTest do
  use ExUnit.Case
  doctest Hui

  test "greets the world" do
    assert Hui.hello() == :world
  end
end
