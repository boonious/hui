defmodule HuiEncoderTest do
  use ExUnit.Case, async: true

  alias Hui.Encoder
  alias Hui.Query

  test "encode/2 map" do
    assert Encoder.encode(%{q: "loch", rows: 10}) == "q=loch&rows=10"
  end

  test "encode/2 keyword list" do
    assert Encoder.encode([q: "loch", rows: 10]) == "q=loch&rows=10"
  end

  test "encode/2 Query.Standard struct" do
    query = %Query.Standard{df: "words_txt", q: "loch torridon", "q.op": "AND", sow: true}
    assert Encoder.encode(query) == "df=words_txt&q=loch+torridon&q.op=AND&sow=true"

    query = %Query.Standard{q: "{!q.op=OR df=series_t}black amber"}
    assert Encoder.encode(query) == "q=%7B%21q.op%3DOR+df%3Dseries_t%7Dblack+amber"
  end

end