defmodule HuiEncodeTest do
  use ExUnit.Case, async: true

  alias Hui.Encode
  alias Hui.Encode.Options
  alias Hui.Query

  test "encode IO data" do
    x = [df: "words_txt", q: "loch", "q.op": "AND", sow: true]

    expected = [
      ["df", "=", "words_txt", "&"],
      ["q", "=", "loch", "&"],
      ["q.op", "=", "AND", "&"],
      ["sow", "=", "true", ""]
    ]

    assert Encode.encode(x) == expected
  end

  test "encode IO data for JSON format" do
    x = [df: "words_txt", q: "loch", "q.op": "AND", sow: true]
    opts = %Options{format: :json}

    expected = [
      ["\"", "df", "\"", ":", "\"words_txt\""],
      ["\"", "q", "\"", ":", "\"loch\""],
      ["\"", "q.op", "\"", ":", "\"AND\""],
      ["\"", "sow", "\"", ":", "true"]
    ]

    assert Encode.encode(x, opts) == expected

    expected_json = "{" <> Enum.join(expected, ",") <> "}"
    assert is_map(Poison.decode!(expected_json)) == true
  end

  test "encode omit nil or empty keywords" do
    x = [df: nil, q: "loch", "q.op": "", sow: nil]
    assert Encode.encode(x) == [["q", "=", "loch", ""]]
  end

  # TODO: more tests for specific Solr query syntax
  test "encode Solr queries" do
    x = [q: "series_t:(blac? OR ambe*)"]
    assert Encode.encode(x) == [["q", "=", "series_t%3A%28blac%3F+OR+ambe%2A%29", ""]]
  end

  # fq: [x, y] => "fq=x&fq=y"
  test "encode keyword with listed values" do
    x = [q: "loch", fq: ["type:image"]]
    assert Encode.encode(x) == [["q", "=", "loch", "&"], ["fq=type%3Aimage", ""]]

    x = [
      wt: "json",
      fq: ["cat:book", "inStock:true", "price:[1.99 TO 9.99]"],
      fl: "id,name,author,price"
    ]

    expected = [
      ["wt", "=", "json", "&"],
      ["fq=cat%3Abook&fq=inStock%3Atrue&fq=price%3A%5B1.99+TO+9.99%5D", "&"],
      ["fl", "=", "id%2Cname%2Cauthor%2Cprice", ""]
    ]

    assert Encode.encode(x) == expected
  end

  test "encode should handle empty, nil values / lists" do
    assert Encode.encode(q: nil, fq: ["", "date", nil, "", "year"]) == [["fq=date&fq=year", ""]]
    assert Encode.encode(fq: ["", "date", nil, "", "year"], q: "") == [["fq=date&fq=year", ""]]

    assert Encode.encode(q: "loch", fq: ["", "date", nil, "", "year"]) == [
             ["q", "=", "loch", "&"],
             ["fq=date&fq=year", ""]
           ]
  end

  test "transform query struct" do
    x = %Query.Facet{field: ["cat", "author_str"], mincount: 1}
    opts = %Encode.Options{prefix: "facet"}

    expected = [facet: true, field: ["cat", "author_str"], mincount: 1]
    assert Encode.transform(x) == expected

    expected = [facet: true, "facet.field": ["cat", "author_str"], "facet.mincount": 1]
    assert Encode.transform(x, opts) == expected

    x = %Query.FacetRange{range: "price", start: 0, end: 100, gap: 10, per_field: true}
    opts = %Encode.Options{prefix: "facet", per_field: "price"}

    expected = [
      "f.price.facet.end": 100,
      "f.price.facet.gap": 10,
      "f.price.facet.range": "price",
      "f.price.facet.start": 0
    ]

    assert Encode.transform(x, opts) == expected
  end
end
