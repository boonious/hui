defmodule Hui.Query.SuggestTest do
  use ExUnit.Case, async: true
  alias Hui.Query

  test "new()" do
    x = Query.Suggest.new()
    assert x.__struct__ == Query.Suggest

    {q, count, dictionary, context} = {"ha", 10, ["name_infix", "ln_prefix"], "subscriber"}

    x = Query.Suggest.new(q)
    assert x.q == q
    assert is_nil(x.count)
    assert is_nil(x.dictionary)
    assert is_nil(x.cfq)

    x = Query.Suggest.new(q, count)
    assert x.q == q
    assert x.count == count

    x = Query.Suggest.new(q, count, dictionary, context)
    assert x.q == q
    assert x.count == count
    assert x.dictionary == dictionary
    assert x.cfq == context
  end
end
