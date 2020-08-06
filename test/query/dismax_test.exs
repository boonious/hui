defmodule Hui.Query.DisMaxTest do
  use ExUnit.Case, async: true
  alias Hui.Query

  test "new()" do
    x = Query.DisMax.new()
    assert x.__struct__ == Query.DisMax

    {q, qf, mm} = {"loch", "title^2.3 description subject^0.4", "2<-25% 9<-3"}

    x = Query.DisMax.new(q)
    assert x.q == q
    assert is_nil(x.qf)
    assert is_nil(x.mm)

    x = Query.DisMax.new(q, qf)
    assert x.q == q
    assert x.qf == qf
    assert is_nil(x.mm)

    x = Query.DisMax.new(q, qf, mm)
    assert x.q == q
    assert x.qf == qf
    assert x.mm == mm
  end
end
