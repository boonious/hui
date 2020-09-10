defmodule HuiEncodeTest do
  use ExUnit.Case, async: true

  import Fixtures.Update

  alias Hui.Encode
  alias Hui.Encode.Options
  alias Hui.Query

  # new encoder being developed gradually
  # for https://github.com/boonious/hui/issues/7
  import Hui.EncodeNew
  alias Hui.EncodeNew.Options

  describe "when encoding type is :url" do
    # encode/1 implies :url encoding type
    test "encode/1 keywords" do
      query = [q: "loch", "q.op": "AND", sow: true, rows: 61]
      io_list = ["q", 61, "loch", 38, ["q.op", 61, "AND", 38, ["sow", 61, "true", 38, ["rows", 61, "61"]]]]

      assert encode(query) == io_list
      assert encode(query) |> to_string == "q=loch&q.op=AND&sow=true&rows=61"
    end

    # TODO: more tests for specific Solr query syntax
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
      json = encode_json(x, opts) |> IO.iodata_to_binary()

      assert json =~ "\"commitWithin\":10"
      assert json =~ "\"overwrite\":true"
      assert json =~ single_doc() |> Jason.encode!()
      assert Jason.decode!(json) == %{"commitWithin" => 10, "doc" => single_doc(), "overwrite" => true}
    end
  end

  describe "encode (JSON)" do
    test "update: commit, expungeDeletes, waitSearcher" do
      opts = %Encode.Options{format: :json}

      x = [commit: true, expungeDeletes: nil, waitSearcher: nil]
      assert Encode.encode(x, opts) |> IO.iodata_to_binary() == "\"commit\":{}"

      x = [commit: true, expungeDeletes: nil, waitSearcher: true]
      expected = "\"commit\":{\"waitSearcher\":true}"
      assert Encode.encode(x, opts) |> IO.iodata_to_binary() == expected

      x = [commit: true, expungeDeletes: false, waitSearcher: nil]
      expected = "\"commit\":{\"expungeDeletes\":false}"
      assert Encode.encode(x, opts) |> IO.iodata_to_binary() == expected

      x = [commit: true, expungeDeletes: false, waitSearcher: false]
      expected = "\"commit\":{\"expungeDeletes\":false,\"waitSearcher\":false}"
      assert Encode.encode(x, opts) |> IO.iodata_to_binary() == expected

      x = [commit: true, expungeDeletes: true, waitSearcher: true]
      expected = "\"commit\":{\"expungeDeletes\":true,\"waitSearcher\":true}"
      assert Encode.encode(x, opts) |> IO.iodata_to_binary() == expected
    end

    test "update: delete by ID" do
      opts = %Encode.Options{format: :json}

      x = [delete: {:id, "tt1650453"}]
      expected = "\"delete\":{\"id\":\"tt1650453\"}"
      assert Encode.encode(x, opts) |> IO.iodata_to_binary() == expected

      x = [delete: [id: "tt1650453", id: "tt165045"]]
      expected = "\"delete\":{\"id\":\"tt1650453\"},\"delete\":{\"id\":\"tt165045\"}"
      assert Encode.encode(x, opts) |> IO.iodata_to_binary() == expected

      x = [delete: "tt1650453"]
      expected = "\"delete\":\"tt1650453\""
      assert Encode.encode(x, opts) |> IO.iodata_to_binary() == expected

      x = [delete: ["123", "456"]]
      expected = "\"delete\":[\"123\",\"456\"]"
      assert Encode.encode(x, opts) |> IO.iodata_to_binary() == expected
    end

    test "update: delete by query" do
      opts = %Encode.Options{format: :json}

      x = [delete: [query: "name:Persona", query: "genre:Drama"]]
      expected = "\"delete\":{\"query\":\"name:Persona\"},\"delete\":{\"query\":\"genre:Drama\"}"
      assert Encode.encode(x, opts) |> IO.iodata_to_binary() == expected

      x = [delete: {:query, "name:Persona"}]
      expected = "\"delete\":{\"query\":\"name:Persona\"}"
      assert Encode.encode(x, opts) |> IO.iodata_to_binary() == expected
    end

    test "update: optimize" do
      opts = %Encode.Options{format: :json}

      x = [optimize: true, maxSegments: nil, waitSearcher: nil]
      expected = "\"optimize\":{}"
      assert Encode.encode(x, opts) |> IO.iodata_to_binary() == expected

      x = [optimize: true, maxSegments: 10, waitSearcher: false]
      expected = "\"optimize\":{\"maxSegments\":10,\"waitSearcher\":false}"
      assert Encode.encode(x, opts) |> IO.iodata_to_binary() == expected
    end

    test "update: rollback" do
      opts = %Encode.Options{format: :json}

      x = [rollback: true]
      expected = "\"rollback\":{}"
      assert Encode.encode(x, opts) |> IO.iodata_to_binary() == expected
    end
  end

  describe "transform" do
    # test transformation of update structs into ordered keyword lists
    test "update struct: doc, commitWithin, overwrite" do
      x = %Query.Update{doc: Fixtures.Update.single_doc(), commitWithin: 10, overwrite: true}
      opts = %Encode.Options{format: :json}

      assert Encode.transform(x, opts) == [
               [
                 commitWithin: 10,
                 overwrite: true,
                 doc: Fixtures.Update.single_doc()
               ]
             ]
    end

    test "update struct: commit, expungeDeletes, waitSearcher" do
      x = %Query.Update{doc: nil, commit: true, waitSearcher: true, expungeDeletes: false}
      opts = %Encode.Options{format: :json}

      expected = [[commit: true, expungeDeletes: false, waitSearcher: true]]
      assert Encode.transform(x, opts) == expected
    end

    test "update struct: delete by ID" do
      opts = %Encode.Options{format: :json}

      x = %Query.Update{delete_id: "tt1650453"}
      expected = [[delete: {:id, "tt1650453"}]]
      assert Encode.transform(x, opts) == expected

      x = %Query.Update{delete_id: ["tt1650453", "tt1650453"]}
      expected = [[delete: [id: "tt1650453", id: "tt1650453"]]]
      assert Encode.transform(x, opts) == expected

      x = %Query.Update{commit: true, delete_id: ["tt1650453", "tt1650453"]}
      expected1 = [delete: [id: "tt1650453", id: "tt1650453"]]
      expected2 = [commit: true, expungeDeletes: nil, waitSearcher: nil]
      assert Encode.transform(x, opts) == [expected1, expected2]
    end

    test "update struct: delete by query" do
      opts = %Encode.Options{format: :json}
      x = %Query.Update{delete_query: ["name:Persona", "genre:Drama"], commit: true}

      expected = [
        [delete: [query: "name:Persona", query: "genre:Drama"]],
        [commit: true, expungeDeletes: nil, waitSearcher: nil]
      ]

      assert Encode.transform(x, opts) == expected

      x = %Query.Update{delete_query: "name:Persona"}
      expected = [[delete: {:query, "name:Persona"}]]
      assert Encode.transform(x, opts) == expected
    end

    test "update struct: optimize" do
      opts = %Encode.Options{format: :json}

      x = %Query.Update{optimize: true}
      expected = [[optimize: true, maxSegments: nil, waitSearcher: nil]]
      assert Encode.transform(x, opts) == expected

      x = %Query.Update{optimize: true, maxSegments: 10, waitSearcher: false}
      expected = [[optimize: true, maxSegments: 10, waitSearcher: false]]
      assert Encode.transform(x, opts) == expected
    end

    test "update struct: rollback" do
      opts = %Encode.Options{format: :json}

      x = %Query.Update{rollback: true}
      expected = [[rollback: true]]
      assert Encode.transform(x, opts) == expected

      x = %Query.Update{rollback: false}
      expected = []
      assert Encode.transform(x, opts) == expected

      x = %Query.Update{delete_query: "name:Persona", rollback: true}
      expected = [[delete: {:query, "name:Persona"}], [rollback: true]]
      assert Encode.transform(x, opts) == expected
    end

    test "raise exception for unsupported encoding format" do
      x = %Query.Update{doc: %{id: "123"}, commitWithin: 10, overwrite: true}
      opts = %Encode.Options{format: "blah"}

      error = "blah format is not supported. Hui currently only encodes update message in JSON."
      assert_raise RuntimeError, error, fn -> Encode.transform(x, opts) end
    end
  end
end
