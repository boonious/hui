defmodule Hui.Query.FacetIntervalTest do
  use ExUnit.Case, async: true
  alias Hui.Query

  doctest Query.FacetInterval

  test "new()" do
    x = Query.FacetInterval.new()
    assert x.__struct__ == Query.FacetInterval

    {interval, set} = {"price", ["[0,10]", "(10,100]"]}

    x = Query.FacetInterval.new(interval)
    assert x.interval == interval
    assert is_nil(x.set)

    x = Query.FacetInterval.new(interval, set)
    assert x.interval == interval
    assert x.set == set
  end
end
