defmodule Hui.Query.HighlighterUnifiedTest do
  use ExUnit.Case, async: true
  alias Hui.Query

  test "new()" do
    x = Query.HighlighterUnified.new()
    assert x.__struct__ == Query.HighlighterUnified

    {d, s} = {true, :POSTINGS}

    x = Query.HighlighterUnified.new(d)
    assert x.defaultSummary == d
    assert is_nil(x.offsetSource)

    x = Query.HighlighterUnified.new(d, s)
    assert x.defaultSummary == d
    assert x.offsetSource == s
  end
end
