defmodule Hui.Query.UpdateTest do
  use ExUnit.Case, async: true
  alias Hui.Query

  test "new()" do
    x = Query.Update.new()
    assert x.__struct__ == Query.Update
  end
end
