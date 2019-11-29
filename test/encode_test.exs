defmodule HuiEncodeTest do
  use ExUnit.Case, async: true

  alias Hui.Encode
  alias Hui.Encode.Options
  alias Hui.Query

  describe "encode" do
    test "IO data" do
      x = [df: "words_txt", q: "loch", "q.op": "AND", sow: true]

      expected = [
        ["df", "=", "words_txt", "&"],
        ["q", "=", "loch", "&"],
        ["q.op", "=", "AND", "&"],
        ["sow", "=", "true", ""]
      ]

      assert Encode.encode(x) == expected
    end

    test "omit nil or empty keywords" do
      x = [df: nil, q: "loch", "q.op": "", sow: nil]
      assert Encode.encode(x) == [["q", "=", "loch", ""]]
    end

    # TODO: more tests for specific Solr query syntax
    test "Solr queries" do
      x = [q: "series_t:(blac? OR ambe*)"]
      assert Encode.encode(x) == [["q", "=", "series_t%3A%28blac%3F+OR+ambe%2A%29", ""]]
    end

    # fq: [x, y] => "fq=x&fq=y"
    test "keyword with listed values" do
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

    test "handle empty, nil values / lists" do
      assert Encode.encode(q: nil, fq: ["", "date", nil, "", "year"]) == [["fq=date&fq=year", ""]]
      assert Encode.encode(fq: ["", "date", nil, "", "year"], q: "") == [["fq=date&fq=year", ""]]

      expected = [["q", "=", "loch", "&"], ["fq=date&fq=year", ""]]
      assert Encode.encode(q: "loch", fq: ["", "date", nil, "", "year"]) == expected
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
      expected = File.read!("./test/data/update_doc5.json")
      update_doc = expected |> Poison.decode!()

      d = update_doc["add"]["doc"]
      c = update_doc["add"]["commitWithin"]
      o = update_doc["add"]["overwrite"]

      x = %Query.Update{doc: d, commitWithin: c, overwrite: o}
      opts = %Encode.Options{format: :json}

      expected = [
        [
          commitWithin: 10,
          overwrite: true,
          doc: %{
            "actor_ss" => [
              "Tom Skerritt",
              "Sigourney Weaver",
              "Veronica Cartwright",
              "Harry Dean Stanton"
            ],
            "desc" =>
              "After a space merchant vessel perceives an unknown transmission as a distress call, its landing on the source moon finds one of the crew attacked by a mysterious lifeform, and they soon realize that its life cycle has merely begun.",
            "directed_by" => ["Ridley Scott"],
            "genre" => ["Sci-Fi", "Horror"],
            "id" => "tt0078748",
            "initial_release_date" => "1979-06-22",
            "name" => "Alien"
          }
        ]
      ]

      assert Encode.transform(x, opts) == expected
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
      expected1 = [commit: true, expungeDeletes: nil, waitSearcher: nil]
      expected2 = [delete: [id: "tt1650453", id: "tt1650453"]]
      assert Encode.transform(x, opts) == [expected1, expected2]
    end

    test "raise exception for unsupported encoding format" do
      x = %Query.Update{doc: %{id: "123"}, commitWithin: 10, overwrite: true}
      opts = %Encode.Options{format: "blah"}

      error = "blah format is not supported. Hui currently only encodes update message in JSON."
      assert_raise RuntimeError, error, fn -> Encode.transform(x, opts) end
    end
  end
end
