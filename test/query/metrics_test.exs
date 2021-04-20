defmodule Hui.Query.MetricsTest do
  use ExUnit.Case, async: true
  alias Hui.Query

  doctest Query.Metrics

  test "new()" do
    x = Query.Metrics.new()
    assert x.__struct__ == Query.Metrics
  end
end
