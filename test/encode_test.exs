defmodule HuiEncodeTest do
  use ExUnit.Case, async: true

  alias Hui.Encode
  alias Hui.Encode.Options
  alias Hui.Query

  # new encoder being developed gradually
  # for https://github.com/boonious/hui/issues/7
  import Hui.EncodeNew
  alias Hui.EncodeNew.Options

  describe "encode/1 keywords" do
    test "into IO list" do
      query = [q: "loch", "q.op": "AND", sow: true, rows: 61]
      io_list = ["q", 61, "loch", 38, ["q.op", 61, "AND", 38, ["sow", 61, "true", 38, ["rows", 61, "61"]]]]

      assert encode(query) == io_list
      assert encode(query) |> to_string == "q=loch&q.op=AND&sow=true&rows=61"
    end

    # TODO: more tests for specific Solr query syntax
    test "with Solr local params value into IO list" do
      assert encode(q: "series_t:(blac? OR ambe*)") == ["q", 61, "series_t%3A%28blac%3F+OR+ambe%2A%29"]
    end

    # fq: [x] => "fq=x"
    test "with a single-value list into IO list" do
      query = [q: "loch", fq: ["type:image"]]

      assert encode(query) == ["q", 61, "loch", 38, ["fq", 61, "type%3Aimage"]]
      assert encode(query) |> to_string == "q=loch&fq=type%3Aimage"
    end

    # fq: [x, y, z] => "fq=x&fq=y&fq=z"
    test "with a list value into IO list" do
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
  end

  describe "encode (JSON)" do
    test "IO data" do
      x = [df: "words_txt", q: "loch", "q.op": "AND", sow: true]
      opts = %Options{format: :json}

      expected = [
        ["\"", "df", "\"", ":", "\"words_txt\"", ","],
        ["\"", "q", "\"", ":", "\"loch\"", ","],
        ["\"", "q.op", "\"", ":", "\"AND\"", ","],
        ["\"", "sow", "\"", ":", "true", ""]
      ]

      assert Encode.encode(x, opts) == expected

      expected_json = "{" <> (expected |> IO.iodata_to_binary()) <> "}"
      assert is_map(Poison.decode!(expected_json)) == true
    end

    test "update: doc, commitWithin, overwrite (JSON)" do
      x = [
        commitWithin: 10,
        overwrite: true,
        doc: %{
          "actor_ss" => ["Harrison Ford", "Rutger Hauer", "Sean Young", "Edward James Olmos"],
          "desc" =>
            "A blade runner must pursue and terminate four replicants who stole a ship in space, and have returned to Earth to find their creator.",
          "directed_by" => ["Ridley Scott"],
          "genre" => ["Sci-Fi", "Thriller"],
          "id" => "tt0083658",
          "initial_release_date" => "1982-06-25",
          "name" => "Blade Runner"
        }
      ]

      expected =
        "\"add\":{\"commitWithin\":10,\"overwrite\":true,\"doc\":{\"name\":\"Blade Runner\"," <>
          "\"initial_release_date\":\"1982-06-25\",\"id\":\"tt0083658\",\"genre\":[\"Sci-Fi\",\"Thriller\"]," <>
          "\"directed_by\":[\"Ridley Scott\"],\"desc\":\"A blade runner must pursue and terminate four replicants" <>
          " who stole a ship in space, and have returned to Earth to find their creator.\",\"actor_ss\"" <>
          ":[\"Harrison Ford\",\"Rutger Hauer\",\"Sean Young\",\"Edward James Olmos\"]}}"

      opts = %Encode.Options{format: :json}
      assert Encode.encode(x, opts) |> IO.iodata_to_binary() == expected
    end

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
    test "query struct" do
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
