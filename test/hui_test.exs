defmodule HuiTest do
  use ExUnit.Case, async: true
  import TestHelpers

  alias Hui.Query
  alias Hui.URL

  @error_einval %Hui.Error{reason: :einval}
  @error_nxdomain %Hui.Error{reason: :nxdomain}

  doctest Hui

  setup_all do
    # set the default Solr endpoint globally
    # for simple "ping" tests

    default_config = Application.get_env(:hui, :default)

    bypass = Bypass.open()

    Bypass.expect(bypass, fn conn ->
      Plug.Conn.resp(conn, 200, "")
    end)

    bypass_url = "http://localhost:#{bypass.port}"
    config = default_config |> Enum.map(&if elem(&1, 0) == :url, do: {:url, bypass_url}, else: &1)
    Application.put_env(:hui, :default, config)

    on_exit(fn ->
      Application.put_env(:hui, :default, default_config)
    end)

    :ok
  end

  # testing with Bypass
  setup do
    bypass = Bypass.open()

    error_nxdomain = %Hui.Error{reason: :nxdomain}

    {:ok,
     bypass: bypass,
     error_nxdomain: error_nxdomain}
  end

  describe "q functions (:default configured %Hui.URL)" do
    # simple tests since `q` forward calls
    # to `search` which is tested further below
    test "call configured default URL" do
      {_, resp} = Hui.q("a", 1, 5, "type:text", ["type", "year"])
      assert resp.status == 200

      {_, resp} = Hui.q(q: "test")
      assert resp.status == 200
    end
  end

  describe "search/2" do
    test "handles keyword list query", %{bypass: bypass} do
      query = [q: "*", rows: 10, fq: ["cat:electronic", "popularity:[0 TO *]"]]

      Bypass.expect(bypass, fn conn ->
        assert conn.query_string == query |> Hui.Encoder.encode()
        Plug.Conn.resp(conn, 200, "")
      end)

      Hui.search("http://localhost:#{bypass.port}", query)
    end

    test "handles a Hui query struct", %{bypass: bypass} do
      query = %Hui.Query.DisMax{
        q: "run",
        qf: "description^2.3 title",
        mm: "2<-25% 9<-3",
        pf: "title",
        ps: 1,
        qs: 3
      }

      Bypass.expect(bypass, fn conn ->
        assert conn.query_string == query |> Hui.Encoder.encode()
        Plug.Conn.resp(conn, 200, "")
      end)

      Hui.search("http://localhost:#{bypass.port}", query)
    end

    test "handles a list of Hui query structs", %{bypass: bypass} do
      struct1 = %Hui.Query.DisMax{
        q: "run",
        qf: "description^2.3 title",
        mm: "2<-25% 9<-3",
        pf: "title",
        ps: 1,
        qs: 3
      }

      struct2 = %Hui.Query.Common{rows: 10, start: 10, fq: ["edited:true"]}
      struct3 = %Hui.Query.Facet{field: ["cat", "author_str"], mincount: 1}

      Bypass.expect(bypass, fn conn ->
        assert conn.query_string == [struct1, struct2, struct3] |> Hui.Encoder.encode()
        Plug.Conn.resp(conn, 200, "")
      end)

      Hui.search("http://localhost:#{bypass.port}", [struct1, struct2, struct3])
    end

    test "returns map response when HTTP client decodes response", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.put_resp_header(conn, "content-type", "application/json")
        |> Plug.Conn.resp(200, File.read!("./test/fixtures/search_response.json"))
      end)

      {_, resp} = Hui.search("http://localhost:#{bypass.port}", q: "*")
      assert is_map(resp.body)
    end

    test "returns binary response when HTTP client does not decodes response", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, File.read!("./test/fixtures/search_response.xml"))
      end)

      {_, resp} = Hui.search("http://localhost:#{bypass.port}", q: "*")
      assert is_binary(resp.body)
    end

    test "accepts %Hui.URL{} endpoint", %{bypass: bypass} do
      url = %Hui.URL{
        url: "http://localhost:#{bypass.port}/solr/newspapers",
        handler: "suggest"
      }

      Bypass.expect(bypass, fn conn ->
        assert conn.port == bypass.port
        assert conn.request_path == "/solr/newspapers/suggest"
        Plug.Conn.resp(conn, 200, "")
      end)

      Hui.search(url, suggest: true, "suggest.q": "el")
    end

    test "accepts %Hui.URL{} endpoint with HTTP headers", %{bypass: bypass} do
      url = %Hui.URL{
        url: "http://localhost:#{bypass.port}",
        headers: [{"accept", "application/json"}]
      }

      Bypass.expect(bypass, fn conn ->
        assert Enum.member?(conn.req_headers, {"accept", "application/json"})
        Plug.Conn.resp(conn, 200, "")
      end)

      Hui.search(url, q: "*")
    end

    # test with the HTTPoison "timeout" for now
    # TODO: add HTTP client implementation headers and options coverage
    test "accepts %Hui.URL{} endpoint with HTTP client options", %{bypass: bypass} do
      url = %Hui.URL{
        url: "http://localhost:#{bypass.port}/",
        options: [timeout: 0]
      }

      assert {:error, %Hui.Error{reason: :checkout_timeout}} == Hui.search(url, q: "*")
    end

    # TODO: refactor, add app config in test and remove :library from configuration
    test "access configured atom URL key" do
      bypass = Bypass.open(port: 8984)

      Bypass.expect(bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      query = [q: "edinburgh", rows: 10]
      {_, url} = Hui.URL.configured_url(:library)
      experted_request_url = Hui.URL.to_string(url) <> "?" <> Hui.Encoder.encode(query)

      {_, resp} = Hui.search(:library, query)
      assert experted_request_url == resp.url
    end
  end

  describe "search/7" do
    test "handles single search query string", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        assert conn.query_string == "q=apache\+documentation"
        Plug.Conn.resp(conn, 200, "")
      end)

      Hui.search("http://localhost:#{bypass.port}", "apache documentation")
    end

    test "handles multiple query parameters", %{bypass: bypass} do
      Bypass.expect(bypass, fn conn ->
        assert conn.query_string == "q=a&fq=type%3Atext&rows=1&start=5&facet=true&facet.field=type&facet.field=year"
        Plug.Conn.resp(conn, 200, "")
      end)

      Hui.search("http://localhost:#{bypass.port}", "a", 1, 5, "type:text", ["type", "year"])
    end
  end

  # TODO: consolidating other malformed query/url tests into a single describe
  test "when query is malformed, Hui should return error tuple" do
    assert {:error, @error_einval} == Hui.q(nil)
    assert {:error, @error_einval} == Hui.search(nil, nil)
    assert {:error, @error_einval} == Hui.suggest(nil, nil)
    assert {:error, @error_einval} == Hui.suggest(:default, "")
  end

  test "when url is malformed, search should return error tuple" do
    assert {:error, @error_nxdomain} == Hui.search("", q: "*")
    assert {:error, @error_nxdomain} == Hui.search([], q: "*")
    assert {:error, @error_nxdomain} == Hui.search(:not_in_config_url, q: "*")
    assert {:error, @error_nxdomain} == Hui.search("boo", q: "*")
  end

  describe "suggest" do
    test "convenience function", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}

      expected =
        "suggest.cfq=1939&suggest.count=5&" <>
          "suggest.dictionary=name_infix&suggest.dictionary=ln_prefix&suggest.dictionary=fn_prefix&" <>
          "suggest.q=ha&suggest=true"

      {_, resp} = Hui.suggest(url, "t")
      assert String.match?(resp.url, ~r/suggest.q=t&suggest=true/)

      {_, resp} = Hui.suggest(url, "ha", 5, ["name_infix", "ln_prefix", "fn_prefix"], "1939")
      assert String.match?(resp.url, ~r/#{expected}/)
    end
  end

  describe "update/3" do
    test "a single doc (map)", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      expected = File.read!("./test/data/update_doc2c.json")
      update_doc = expected |> Poison.decode!()

      setup_bypass_for_post_req(context.bypass, expected)
      Hui.update(url, update_doc["add"]["doc"], true)
    end

    test "a single doc (map) without commit", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      doc_map = %{
        "actor_ss" => ["János Derzsi", "Erika Bók", "Mihály Kormos", "Ricsi"],
        "desc" => "A rural farmer is forced to confront the mortality of his faithful horse.",
        "directed_by" => ["Béla Tarr", "Ágnes Hranitzky"],
        "genre" => ["Drama"],
        "id" => "tt1316540",
        "initial_release_date" => "2011-03-31",
        "name" => "The Turin Horse"
      }

      expected = %Query.Update{doc: doc_map} |> Hui.Encoder.encode()

      setup_bypass_for_post_req(context.bypass, expected)
      Hui.update(url, doc_map, false)
    end

    test "multiple docs (map)", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      setup_bypass_for_post_req(context.bypass, File.read!("./test/data/update_doc3c.json"))

      doc_map1 = %{
        "actor_ss" => ["János Derzsi", "Erika Bók", "Mihály Kormos", "Ricsi"],
        "desc" => "A rural farmer is forced to confront the mortality of his faithful horse.",
        "directed_by" => ["Béla Tarr", "Ágnes Hranitzky"],
        "genre" => ["Drama"],
        "id" => "tt1316540",
        "initial_release_date" => "2011-03-31",
        "name" => "The Turin Horse"
      }

      doc_map2 = %{
        "actor_ss" => ["Masami Nagasawa", "Hiroshi Abe", "Kanna Hashimoto", "Yoshio Harada"],
        "desc" =>
          "Twelve-year-old Koichi, who has been separated from his brother Ryunosuke due to his parents' divorce, hears a rumor that the new bullet trains will precipitate a wish-granting miracle when they pass each other at top speed.",
        "directed_by" => ["Hirokazu Koreeda"],
        "genre" => ["Drame"],
        "id" => "tt1650453",
        "initial_release_date" => "2011-06-11",
        "name" => "I Wish"
      }

      Hui.update(url, [doc_map1, doc_map2], true)
    end

    test "multiple docs (map) without commit", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      doc_map1 = %{
        "actor_ss" => ["János Derzsi", "Erika Bók", "Mihály Kormos", "Ricsi"],
        "desc" => "A rural farmer is forced to confront the mortality of his faithful horse.",
        "directed_by" => ["Béla Tarr", "Ágnes Hranitzky"],
        "genre" => ["Drama"],
        "id" => "tt1316540",
        "initial_release_date" => "2011-03-31",
        "name" => "The Turin Horse"
      }

      doc_map2 = %{
        "actor_ss" => ["Masami Nagasawa", "Hiroshi Abe", "Kanna Hashimoto", "Yoshio Harada"],
        "desc" =>
          "Twelve-year-old Koichi, who has been separated from his brother Ryunosuke due to his parents' divorce, hears a rumor that the new bullet trains will precipitate a wish-granting miracle when they pass each other at top speed.",
        "directed_by" => ["Hirokazu Koreeda"],
        "genre" => ["Drame"],
        "id" => "tt1650453",
        "initial_release_date" => "2011-06-11",
        "name" => "I Wish"
      }

      expected = %Query.Update{doc: [doc_map1, doc_map2]} |> Hui.Encoder.encode()
      setup_bypass_for_post_req(context.bypass, expected)
      Hui.update(url, [doc_map1, doc_map2], false)
    end

    test "doc (binary)", context do
      update_doc = File.read!("./test/data/update_doc1.json")
      setup_bypass_for_post_req(context.bypass, update_doc)

      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      Hui.update(url, update_doc, true)
    end

    test "via configured URL key" do
      update_doc = File.read!("./test/data/update_doc2.xml")
      bypass = Bypass.open(port: 8989)

      setup_bypass_for_post_req(bypass, update_doc, "application/xml")
      Hui.update(:update_test, update_doc)
    end

    test "handles missing or malformed URL", context do
      update_doc = File.read!("./test/data/update_doc2.xml")

      assert {:error, context.error_nxdomain} == Hui.update(nil, update_doc)
      assert {:error, context.error_nxdomain} == Hui.update("", update_doc)
      assert {:error, context.error_nxdomain} == Hui.update([], update_doc)
      assert {:error, context.error_nxdomain} == Hui.update(:blahblah, update_doc)
      assert {:error, context.error_nxdomain} == Hui.update(%Hui.URL{url: "boo"}, "")
    end
  end

  describe "update/3 handles Update struct" do
    test "with commitWithin, overwrite commands", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      expected = File.read!("./test/data/update_doc5.json")
      update_doc = expected |> Poison.decode!()

      d = update_doc["add"]["doc"]
      c = update_doc["add"]["commitWithin"]
      o = update_doc["add"]["overwrite"]

      setup_bypass_for_post_req(context.bypass, expected)
      Hui.update(url, %Query.Update{doc: d, commitWithin: c, overwrite: o}, true)
    end

    test "with multiple grouped update commands", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      expected = File.read!("./test/data/update_doc9.json")

      doc_map1 = %{
        "actor_ss" => ["Ingrid Bergman", "Liv Ullmann", "Lena Nyman", "Halvar Björk"],
        "desc" =>
          "A married daughter who longs for her mother's love is visited by the latter, a successful concert pianist.",
        "directed_by" => ["Ingmar Bergman"],
        "genre" => ["Drama", "Music"],
        "id" => "tt0077711",
        "initial_release_date" => "1978-10-08",
        "name" => "Autumn Sonata"
      }

      doc_map2 = %{
        "actor_ss" => ["Bibi Andersson", "Liv Ullmann", "Margaretha Krook"],
        "desc" => "A nurse is put in charge of a mute actress and finds that their personas are melding together.",
        "directed_by" => ["Ingmar Bergman"],
        "genre" => ["Drama", "Thriller"],
        "id" => "tt0060827",
        "initial_release_date" => "1967-09-21",
        "name" => "Persona"
      }

      query = %Query.Update{doc: [doc_map1, doc_map2], commitWithin: 50, overwrite: true}
      query = %Query.Update{query | commit: true, waitSearcher: true, expungeDeletes: false}

      setup_bypass_for_post_req(context.bypass, expected)
      Hui.update(url, query, true)
    end

    test "with optimize command", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      expected = "{\"optimize\":{\"maxSegments\":10,\"waitSearcher\":false}}"
      setup_bypass_for_post_req(context.bypass, expected)
      Hui.update(url, %Query.Update{optimize: true, maxSegments: 10, waitSearcher: false})
    end

    test "with rollback command", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      expected = "{\"delete\":{\"query\":\"name:Persona\"},\"rollback\":{}}"
      setup_bypass_for_post_req(context.bypass, expected)
      Hui.update(url, %Query.Update{delete_query: "name:Persona", rollback: true})
    end
  end

  test "delete/3 docs by ID", context do
    url = %Hui.URL{
      url: "http://localhost:#{context.bypass.port}",
      handler: "update",
      headers: [{"Content-type", "application/json"}]
    }

    query = %Query.Update{delete_id: ["tt1650453", "tt1650453"], commit: true}
    expected = query |> Hui.Encoder.encode()
    setup_bypass_for_post_req(context.bypass, expected)

    Hui.delete(url, ["tt1650453", "tt1650453"])
  end

  test "delete_by_query/3", context do
    url = %Hui.URL{
      url: "http://localhost:#{context.bypass.port}",
      handler: "update",
      headers: [{"Content-type", "application/json"}]
    }

    query = %Query.Update{delete_query: ["name:Persona", "genre:Drama"], commit: true}
    expected = query |> Hui.Encoder.encode()
    setup_bypass_for_post_req(context.bypass, expected)

    Hui.delete_by_query(url, ["name:Persona", "genre:Drama"])
  end

  test "commit/2", context do
    url = %Hui.URL{
      url: "http://localhost:#{context.bypass.port}",
      handler: "update",
      headers: [{"Content-type", "application/json"}]
    }

    expected = %Query.Update{commit: true, waitSearcher: true} |> Hui.Encoder.encode()
    setup_bypass_for_post_req(context.bypass, expected)

    Hui.commit(url)
  end

  describe "get/2 handles" do
    test "a list of structs", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = %URL{url: "http://localhost:#{context.bypass.port}"}
      x = %Query.Common{rows: 5, fq: ["cat:book", "inStock:true", "price:[1.99 TO 9.99]"]}
      y = %Query.Standard{q: "{!q.op=OR df=series_t}black amber"}

      test_get_req_url(url, [x, y])
    end

    test "DisMax struct", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = %URL{url: "http://localhost:#{context.bypass.port}"}

      x = %Query.DisMax{
        q: "edinburgh",
        qf: "description^2.3 title",
        mm: "2<-25% 9<-3",
        pf: "title",
        ps: 1,
        qs: 3,
        bq: "edited:true"
      }

      y = %Query.Common{rows: 5, start: 0}

      test_get_req_url(url, x)
      test_get_req_url(url, [x, y])
    end

    test "SolrCloud struct", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = %URL{url: "http://localhost:#{context.bypass.port}"}

      x = %Query.Common{
        distrib: true,
        "shards.tolerant": true,
        "shards.info": true,
        collection: "library,common"
      }

      test_get_req_url(url, x)
    end

    test "paging struct", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = %URL{url: "http://localhost:#{context.bypass.port}"}
      x = %Query.Standard{q: "*"}
      y = %Query.Common{cursorMark: "*", sort: "id asc"}

      test_get_req_url(url, [x, y])
    end

    test "faceting structs", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      x = %Query.Standard{q: "author:I*"}
      y = %Query.Common{rows: 5, echoParams: "explicit"}
      z = %Query.Facet{field: ["cat", "author_str"], mincount: 1}

      url = %URL{url: "http://localhost:#{context.bypass.port}"}

      test_get_req_url(url, [x, y, z])
    end

    test "highlighting struct", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = %URL{url: "http://localhost:#{context.bypass.port}"}
      x = %Query.Standard{q: "features:photo"}
      y = %Query.Highlight{fl: "features", usePhraseHighlighter: true, fragsize: 250, snippets: 3}

      test_get_req_url(url, [x, y])
    end

    test "other highlighting structs", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}

      x = %Query.Standard{q: "features:photo"}
      y = %Query.Highlight{fl: "features"}

      y1 = %Query.HighlighterUnified{
        offsetSource: "POSTINGS",
        defaultSummary: true,
        "score.k1": 0
      }

      y2 = %Query.HighlighterOriginal{
        mergeContiguous: true,
        "simple.pre": "<b>",
        "simple.post": "</b>",
        preserveMulti: true
      }

      y3 = %Query.HighlighterFastVector{
        boundaryScanner: "breakIterator",
        "bs.type": "WORD",
        "bs.language": "EN",
        "bs.country": "US"
      }

      test_get_req_url(url, [x, %{y | method: :unified}, y1])
      test_get_req_url(url, [x, %{y | method: :original}, y2])
      test_get_req_url(url, [x, %{y | method: :fastVector}, y3])
    end

    test "suggester struct", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = %URL{url: "http://localhost:#{context.bypass.port}"}
      x = %Query.Suggest{q: "ha", count: 10, dictionary: ["name_infix", "ln_prefix", "fn_prefix"]}

      test_get_req_url(url, x)
    end

    test "spellchecking struct", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = %URL{url: "http://localhost:#{context.bypass.port}"}

      x = %Query.SpellCheck{
        q: "delll ultra sharp",
        count: 10,
        "collateParam.q.op": "AND",
        dictionary: "default"
      }

      test_get_req_url(url, x)

      # {_status, resp} = Hui.spellcheck(url, solr_params)
      # assert String.match?(resp.request_url, ~r/#{experted_url}/)

      # solr_params_q = %Hui.Q{df: "text", wt: "xml"}
      # {_status, resp} = Hui.spellcheck(url, solr_params, solr_params_q)
      # assert String.match?(resp.request_url, ~r/df=text&wt=xml&#{experted_url}/)
    end

    test "more-like-this struct", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = %URL{url: "http://localhost:#{context.bypass.port}"}

      x = %Query.MoreLikeThis{
        fl: "manu,cat",
        mindf: 10,
        mintf: 200,
        "match.include": true,
        count: 10
      }

      y = %Query.Standard{q: "apache"}
      z = %Query.Common{rows: 5, wt: "xml"}

      test_get_req_url(url, [x, y, z])

      # {_status, resp} = Hui.mlt(url, solr_params_q, solr_params)
      # assert String.match?(resp.request_url, ~r/#{experted_url}/)
    end
  end

  describe "post/2 handles" do
    test "Update struct", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      update_doc = File.read!("./test/data/update_doc2.json") |> Poison.decode!()
      expected_data = update_doc |> Poison.encode!()
      doc_map = update_doc["add"]["doc"]

      setup_bypass_for_post_req(context.bypass, expected_data)
      Hui.post(url, %Query.Update{doc: doc_map})
    end

    test "Update struct - multiple docs", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      expected_data = File.read!("./test/data/update_doc3.json")
      setup_bypass_for_post_req(context.bypass, expected_data)

      doc_map1 = %{
        "actor_ss" => ["János Derzsi", "Erika Bók", "Mihály Kormos", "Ricsi"],
        "desc" => "A rural farmer is forced to confront the mortality of his faithful horse.",
        "directed_by" => ["Béla Tarr", "Ágnes Hranitzky"],
        "genre" => ["Drama"],
        "id" => "tt1316540",
        "initial_release_date" => "2011-03-31",
        "name" => "The Turin Horse"
      }

      doc_map2 = %{
        "actor_ss" => ["Masami Nagasawa", "Hiroshi Abe", "Kanna Hashimoto", "Yoshio Harada"],
        "desc" =>
          "Twelve-year-old Koichi, who has been separated from his brother Ryunosuke due to his parents' divorce, hears a rumor that the new bullet trains will precipitate a wish-granting miracle when they pass each other at top speed.",
        "directed_by" => ["Hirokazu Koreeda"],
        "genre" => ["Drame"],
        "id" => "tt1650453",
        "initial_release_date" => "2011-06-11",
        "name" => "I Wish"
      }

      Hui.post(url, %Query.Update{doc: [doc_map1, doc_map2]})
    end

    test "Update struct - JSON binary data", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      update_doc = File.read!("./test/data/update_doc1.json")
      setup_bypass_for_post_req(context.bypass, update_doc)

      Hui.post(url, update_doc)
    end

    test "Update struct - XML binary data", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/xml"}]
      }

      update_doc = "<delete><id>9780141981727</id></delete>"
      setup_bypass_for_post_req(context.bypass, update_doc, "application/xml")

      Hui.post(url, update_doc)
    end
  end
end
