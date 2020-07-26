defmodule Hui.Query.StandardTest do
  use ExUnit.Case, async: true
  alias Hui.Query

  test "new()" do
    x = Query.Standard.new()
    assert x.__struct__ == Query.Standard

    x = Query.Standard.new("jakarta^4 apache")
    assert x.q == "jakarta^4 apache"
  end
end
