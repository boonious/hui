defmodule Hui.Query.MoreLikeThisTest do
  use ExUnit.Case, async: true
  alias Hui.Query

  test "new()" do
    x = Query.MoreLikeThis.new()
    assert x.__struct__ == Query.MoreLikeThis

    {fl, count, min_tf, min_df, max_df} = {"words", 3, 10, 10, 10_000}

    x = Query.MoreLikeThis.new(fl)
    assert x.fl == fl
    assert is_nil(x.count)
    assert is_nil(x.mintf)
    assert is_nil(x.mindf)
    assert is_nil(x.maxdf)

    x = Query.MoreLikeThis.new(fl, count)
    assert x.fl == fl
    assert x.count == count

    x = Query.MoreLikeThis.new(fl, count, min_tf, min_df, max_df)
    assert x.fl == fl
    assert x.count == count
    assert x.mintf == min_tf
    assert x.mindf == min_df
    assert x.maxdf == max_df
  end
end
