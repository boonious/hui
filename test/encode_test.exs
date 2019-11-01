defmodule HuiEncodeTest do
  use ExUnit.Case, async: true

  alias Hui.Encode

  test "encode IO data" do
    query_list = [df: "words_txt", q: "loch", "q.op": "AND", sow: true]

    assert Encode.encode(query_list) == [
             ["df", "=", "words_txt", "&"],
             ["q", "=", "loch", "&"],
             ["q.op", "=", "AND", "&"],
             ["sow", "=", "true", ""]
           ]
  end

  test "encode omit nil or empty keywords" do
    query_list = [df: nil, q: "loch", "q.op": "", sow: nil]
    assert Encode.encode(query_list) == [["q", "=", "loch", ""]]
  end

  # TODO: more tests for specific Solr query syntax
  test "encode Solr queries" do
    query_list = [q: "series_t:(blac? OR ambe*)"]
    assert Encode.encode(query_list) == [["q", "=", "series_t%3A%28blac%3F+OR+ambe%2A%29", ""]]
  end

  # fq: [x, y] => "fq=x&fq=y"
  test "encode keyword with listed values" do
    query_list = [q: "loch", fq: ["type:image"]]
    assert Encode.encode(query_list) == [["q", "=", "loch", "&"], ["fq=type%3Aimage", ""]]

    query_list = [
      wt: "json",
      fq: ["cat:book", "inStock:true", "price:[1.99 TO 9.99]"],
      fl: "id,name,author,price"
    ]

    assert Encode.encode(query_list) == [
             ["wt", "=", "json", "&"],
             ["fq=cat%3Abook&fq=inStock%3Atrue&fq=price%3A%5B1.99+TO+9.99%5D", "&"],
             ["fl", "=", "id%2Cname%2Cauthor%2Cprice", ""]
           ]
  end

  test "encode map" do
    query_map = %{
      q: "harry",
      wt: "json",
      fq: ["cat:book", "inStock:true", "price:[1.99 TO 9.99]"],
      fl: "id,name,author,price"
    }

    assert Encode.encode(query_map) == [
             ["fl", "=", "id%2Cname%2Cauthor%2Cprice", "&"],
             ["fq=cat%3Abook&fq=inStock%3Atrue&fq=price%3A%5B1.99+TO+9.99%5D", "&"],
             ["q", "=", "harry", "&"],
             ["wt", "=", "json", ""]
           ]
  end
end
