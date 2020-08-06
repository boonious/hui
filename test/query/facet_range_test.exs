defmodule Hui.Query.FacetRangeTest do
  use ExUnit.Case, async: true
  alias Hui.Query

  doctest Query.FacetRange

  test "new()" do
    x = Query.FacetRange.new()
    assert x.__struct__ == Query.FacetRange

    {r, g, s, e} = {"year", "+10YEARS", 1700, 1799}

    x = Query.FacetRange.new(r, g, s, e)
    assert x.range == r
    assert x.gap == g
    assert x.start == s
    assert x.end == e
  end
end
