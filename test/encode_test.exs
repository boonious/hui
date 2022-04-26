defmodule HuiEncodeTest do
  use ExUnit.Case, async: true

  import Fixtures.Update
  import Hui.Encode

  alias Hui.Encode.Options
  alias Hui.Query

  describe "when encoding type is :url" do
    # encode/1 implies :url encoding type
    test "encode/1 keywords" do
      query = [q: "loch", "q.op": "AND", sow: true, rows: 61]
      io_list = ["q", 61, "loch", 38, ["q.op", 61, "AND", 38, ["sow", 61, "true", 38, ["rows", 61, "61"]]]]

      assert encode(query) == io_list
      assert encode(query) |> to_string == "q=loch&q.op=AND&sow=true&rows=61"
    end

    test "encode/1 keywords with Solr local params" do
      assert encode(q: "series_t:(blac? OR ambe*)") == ["q", 61, "series_t%3A%28blac%3F+OR+ambe%2A%29"]
    end

    # fq: [x] => "fq=x"
    test "encode/1 keywords with a single-value list" do
      query = [q: "loch", fq: ["type:image"]]

      assert encode(query) == ["q", 61, "loch", 38, ["fq", 61, "type%3Aimage"]]
      assert encode(query) |> to_string == "q=loch&fq=type%3Aimage"
    end

    # fq: [x, y, z] => "fq=x&fq=y&fq=z"
    test "encode/1 keywords with a list value" do
      query = [
        wt: "json",
        fq: ["cat:book", "inStock:true", "price:[1.99 TO 9.99]"],
        fl: "id,name"
      ]

      io_list = [
        "wt",
        61,
        "json",
        38,
        [
          "fq",
          61,
          "cat%3Abook",
          38,
          ["fq", 61, "inStock%3Atrue", 38, ["fq", 61, "price%3A%5B1.99+TO+9.99%5D", 38, ["fl", 61, "id%2Cname"]]]
        ]
      ]

      assert encode(query) == io_list

      assert encode(query) |> to_string ==
               "wt=json&fq=cat%3Abook&fq=inStock%3Atrue&fq=price%3A%5B1.99+TO+9.99%5D&fl=id%2Cname"
    end

    test "encode/1 map query" do
      query = %{
        q: "harry",
        rows: 10,
        fq: ["cat:book", "price:[1.99 TO 9.99]"],
        fl: "id,name"
      }

      io_list = [
        "fl",
        61,
        "id%2Cname",
        38,
        [
          "fq",
          61,
          "cat%3Abook",
          38,
          [
            "fq",
            61,
            "price%3A%5B1.99+TO+9.99%5D",
            38,
            ["q", 61, "harry", 38, ["rows", 61, "10"]]
          ]
        ]
      ]

      assert encode(query) == io_list
      assert encode(query) |> to_string == "fl=id%2Cname&fq=cat%3Abook&fq=price%3A%5B1.99+TO+9.99%5D&q=harry&rows=10"
    end

    # explicit set encoding type to :url
    test "encode/2 keywords" do
      query = [q: "loch", "q.op": "AND", sow: true, rows: 61]
      io_list = ["q", 61, "loch", 38, ["q.op", 61, "AND", 38, ["sow", 61, "true", 38, ["rows", 61, "61"]]]]

      opts = %Options{type: :url}

      assert encode(query, opts) == io_list
      assert encode(query, opts) |> to_string == "q=loch&q.op=AND&sow=true&rows=61"
    end

    test "encode/2 facet struct" do
      opts = %Options{prefix: "facet"}

      encoded_io_list =
        %Query.Facet{field: ["cat", "author_str"], mincount: 1}
        |> Map.to_list()
        |> sanitise()
        |> encode(opts)

      assert encoded_io_list == [
               "facet",
               61,
               "true",
               38,
               ["facet.field", 61, "cat", 38, ["facet.field", 61, "author_str", 38, ["facet.mincount", 61, "1"]]]
             ]

      assert encoded_io_list |> to_string == "facet=true&facet.field=cat&facet.field=author_str&facet.mincount=1"
    end

    test "encode/2 facet range struct" do
      opts = %Options{prefix: "facet"}

      encoded_io_list =
        %Query.FacetRange{range: "price", start: 0, end: 100, gap: 10, per_field: true}
        |> Map.to_list()
        |> sanitise()
        |> encode(opts)

      assert encoded_io_list == [
               "facet.end",
               61,
               "100",
               38,
               ["facet.gap", 61, "10", 38, ["facet.range", 61, "price", 38, ["facet.start", 61, "0"]]]
             ]

      assert encoded_io_list |> to_string == "facet.end=100&facet.gap=10&facet.range=price&facet.start=0"
    end

    test "encode/2 facet per-field range struct" do
      opts = %Options{prefix: "facet", per_field: "price"}

      encoded_io_list =
        %Query.FacetRange{range: "price", start: 0, end: 100, gap: 10, per_field: true}
        |> Map.to_list()
        |> sanitise()
        |> encode(opts)

      assert encoded_io_list == [
               "f.price.facet.end",
               61,
               "100",
               38,
               [
                 "f.price.facet.gap",
                 61,
                 "10",
                 38,
                 ["f.price.facet.range", 61, "price", 38, ["f.price.facet.start", 61, "0"]]
               ]
             ]

      assert encoded_io_list |> to_string ==
               "f.price.facet.end=100&f.price.facet.gap=10&f.price.facet.range=price&f.price.facet.start=0"
    end
  end

  describe "when encoding type is :json" do
    test "encode/2 keywords" do
      query = [df: "words_txt", q: "loch", "q.op": "AND", sow: true]

      io_list = [
        123,
        [
          [34, "df", 34],
          58,
          [34, [[] | "words_txt"], 34],
          44,
          [
            [34, "q", 34],
            58,
            [34, [[] | "loch"], 34],
            44,
            [[34, "q.op", 34], 58, [34, [[] | "AND"], 34], 44, [[34, "sow", 34], 58, "true"]]
          ]
        ],
        125
      ]

      opts = %Options{type: :json}

      assert encode_json(query, opts) == io_list

      assert encode_json(query, opts) |> IO.iodata_to_binary() ==
               "{\"df\":\"words_txt\",\"q\":\"loch\",\"q.op\":\"AND\",\"sow\":true}"

      assert encode_json(query, opts) |> IO.iodata_to_binary() |> Jason.decode!() == %{
               "df" => "words_txt",
               "q" => "loch",
               "q.op" => "AND",
               "sow" => true
             }
    end

    test "encode/2 update doc, with commitWithin, overwrite commands" do
      x = [
        commitWithin: 10,
        overwrite: true,
        doc: single_doc()
      ]

      opts = %Options{type: :json}
      encoded = encode_json(x, opts) |> IO.iodata_to_binary()

      assert encoded =~ "\"commitWithin\":10"
      assert encoded =~ "\"overwrite\":true"
      assert encoded =~ single_doc() |> Jason.encode!()
      assert Jason.decode!(encoded) == %{"commitWithin" => 10, "doc" => single_doc(), "overwrite" => true}
    end

    test "encode/2 keywords update commands" do
      opts = %Options{type: :json}

      x = [expungeDeletes: true, waitSearcher: true]
      assert encode(x, opts) |> IO.iodata_to_binary() == "\"expungeDeletes\":true,\"waitSearcher\":true"

      x = [commitWithin: 10, overwrite: true]
      assert encode(x, opts) |> IO.iodata_to_binary() == "\"commitWithin\":10,\"overwrite\":true"
    end
  end
end
