defmodule Hui.Query.SpellCheckTest do
  use ExUnit.Case, async: true
  alias Hui.Query

  test "new()" do
    x = Query.SpellCheck.new()
    assert x.__struct__ == Query.SpellCheck

    x = Query.SpellCheck.new("javaw")
    assert x.q == "javaw"
    assert is_nil(x.collate)

    x = Query.SpellCheck.new("javaw", true)
    assert x.q == "javaw"
    assert x.collate == true
  end
end
