defmodule Hui.Query.CommonTest do
  use ExUnit.Case, async: true
  alias Hui.Query

  test "new()" do
    x = Query.Common.new()
    assert x.__struct__ == Query.Common

    {rows, start, fq, sort} = {1, 10, "type:jpeg", "score desc"}

    x = Query.Common.new(rows)
    assert x.rows == rows
    assert is_nil(x.start)
    assert is_nil(x.fq)
    assert is_nil(x.sort)

    x = Query.Common.new(rows, start)
    assert x.rows == rows
    assert x.start == start
    assert is_nil(x.fq)
    assert is_nil(x.sort)

    x = Query.Common.new(rows, start, fq)
    assert x.rows == rows
    assert x.start == start
    assert x.fq == fq
    assert is_nil(x.sort)

    x = Query.Common.new(rows, start, fq, sort)
    assert x.rows == rows
    assert x.start == start
    assert x.fq == fq
    assert x.sort == sort
  end
end
