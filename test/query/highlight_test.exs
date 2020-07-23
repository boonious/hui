defmodule Hui.Query.HighlightTest do
  use ExUnit.Case, async: true
  alias Hui.Query

  test "new()" do
    x = Query.Highlight.new()
    assert x.__struct__ == Query.Highlight

    {fl, snippets, fragsize} = {"title,description", 3, 250}

    x = Query.Highlight.new(fl)
    assert x.fl == fl
    assert is_nil(x.snippets)
    assert is_nil(x.fragsize)

    x = Query.Highlight.new(fl, snippets)
    assert x.fl == fl
    assert x.snippets == snippets
    assert is_nil(x.fragsize)

    x = Query.Highlight.new(fl, snippets, fragsize)
    assert x.fl == fl
    assert x.snippets == snippets
    assert x.fragsize == fragsize
  end
end
