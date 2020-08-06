defmodule Hui.Query.FacetTest do
  use ExUnit.Case, async: true
  alias Hui.Query

  doctest Query.Facet

  test "new()" do
    x = Query.Facet.new()
    assert x.__struct__ == Query.Facet

    {f, q} = {["type", "year"], "year:2001"}

    x = Query.Facet.new(f)
    assert x.field == f
    assert is_nil(x.query)

    x = Query.Facet.new(f, q)
    assert x.field == f
    assert x.query == q

    x = Query.Facet.new(nil, q)
    assert is_nil(x.field)
    assert x.query == q
  end
end
