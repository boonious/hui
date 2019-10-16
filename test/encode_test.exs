defmodule HuiEncodeTest do
  use ExUnit.Case, async: true

  alias Hui.Encode

  test "encode/1 IO data" do
    query_list = [df: nil, q: "loch", "q.op": "", sow: nil]
    assert Encode.encode(query_list) == [["q", "=", "loch", ""]] # omit nil and "" keywords

    query_list = [df: "words_txt", q: "loch", "q.op": "AND", sow: true]
    assert Encode.encode(query_list) == [["df", "=", "words_txt", "&"], ["q", "=", "loch", "&"], ["q.op", "=", "AND", "&"], ["sow", "=", "true", ""]]
  end

  # TODO: more tests for specific Solr query syntax
  test "encode/1 Solr queries" do
    query_list = [q: "series_t:(blac? OR ambe*)"]
    assert Encode.encode(query_list) == [["q", "=", "series_t%3A%28blac%3F+OR+ambe%2A%29", ""]]
  end

end