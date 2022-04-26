defmodule Hui.GuardsTest do
  use ExUnit.Case, async: true
  import Hui.Guards

  test "is_nil_empty/1 guard" do
    assert is_nil_empty(nil) == true
    assert is_nil_empty("") == true
    assert is_nil_empty([]) == true
  end

  test "is_url/1 guard" do
    refute is_url(nil) == true
    refute is_url("") == true
    refute is_url([]) == true
  end

  test "is_url/2 guard" do
    refute is_url("", nil) == true
    refute is_url("http://localhost", nil) == true
    assert is_url("http://localhost", [{"accept", "application/json"}]) == true
  end

  test "is_url/3 guard" do
    refute is_url("", nil, []) == true
    assert is_url("http://localhost", [{"accept", "application/json"}], timeout: 10_000) == true
  end
end
