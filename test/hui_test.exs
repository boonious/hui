defmodule HuiTest do
  use ExUnit.Case, async: true
  import TestHelpers

  alias Hui.Query
  alias Hui.URL

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
    resp = File.read!("./test/data/simple_search_response.json")
    resp_xml = File.read!("./test/data/simple_search_response.xml")
    bypass = Bypass.open()

    error_einval = %Hui.Error{reason: :einval}
    error_nxdomain = %Hui.Error{reason: :nxdomain}

    {:ok,
     bypass: bypass,
     simple_search_response_sample: resp,
     simple_search_response_sample_xml: resp_xml,
     error_einval: error_einval,
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

  describe "search functions" do
    test "perform keywords query", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      test_search_req_url("http://localhost:#{context.bypass.port}", q: "*")
    end

    test "handle a list of query parameters", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end)

      query = [q: "*", rows: 10, fq: ["cat:electronics", "popularity:[0 TO *]"]]
      test_search_req_url("http://localhost:#{context.bypass.port}", query)
    end

    test "handle a Hui struct", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end)

      query = %Hui.Query.DisMax{
        q: "run",
        qf: "description^2.3 title",
        mm: "2<-25% 9<-3",
        pf: "title",
        ps: 1,
        qs: 3
      }

      test_search_req_url("http://localhost:#{context.bypass.port}", query)

      query = %Hui.Query.Common{rows: 10, start: 10, fq: ["edited:true"]}
      test_search_req_url("http://localhost:#{context.bypass.port}", query)
    end

    test "handle a list of Hui structs", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end)

      x = %Hui.Query.DisMax{
        q: "run",
        qf: "description^2.3 title",
        mm: "2<-25% 9<-3",
        pf: "title",
        ps: 1,
        qs: 3
      }

      y = %Hui.Query.Common{rows: 10, start: 10, fq: ["edited:true"]}
      z = %Hui.Query.Facet{field: ["cat", "author_str"], mincount: 1}

      test_search_req_url("http://localhost:#{context.bypass.port}", [x, y, z])
    end
  end

  describe "search functions (misc)" do
    test "work with %Hui.URL{}", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}/solr/newspapers",
        handler: "suggest"
      }

      query = [suggest: true, "suggest.dictionary": "mySuggester", "suggest.q": "el"]
      test_search_req_url(url, query)
    end

    test "facilitate HTTP headers setting via %Hui.URL{}", context do
      test_header = {"accept", "application/json"}

      Bypass.expect(context.bypass, fn conn ->
        assert Enum.member?(conn.req_headers, test_header)
        Plug.Conn.resp(conn, 200, "")
      end)

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", headers: [test_header]}
      Hui.search(url, q: "*")
    end

    test "facilitate HTTPoison options setting via %Hui.URL{}", context do
      # test with the HTTPoison "timeout" option, "0" setting mimicking a request timeout
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}/", options: [timeout: 0]}
      assert {:error, %Hui.Error{reason: :checkout_timeout}} = Hui.search(url, q: "*")

      # test with the low-level HTTPoison "params" option, for appending additional query string params
      Bypass.expect(context.bypass, fn conn -> Plug.Conn.resp(conn, 200, "") end)

      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}/",
        options: [params: [test: "from_test"]]
      }

      test_search_req_url(url, [q: "*"], ~r/test=from_test/)
    end

    test "work with configured URL via a config key" do
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

    test "handle bad URL" do
      # TODO: need fixing
      assert true
    end

    test "decode and return raw JSON Solr response as Map", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.put_resp_header(conn, "content-type", "application/json")
        |> Plug.Conn.resp(200, context.simple_search_response_sample)
      end)

      {_, resp} = Hui.search("http://localhost:#{context.bypass.port}", q: "*")
      assert is_map(resp.body)
    end

    test "not decode and just return raw XML Solr response as text", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample_xml)
      end)

      {_, resp} = Hui.search("http://localhost:#{context.bypass.port}", q: "*")
      refute is_map(resp.body)
      assert is_binary(resp.body)
    end

    test "handle malformed queries", context do
      assert {:error, context.error_einval} == Hui.q(nil)
      assert {:error, context.error_einval} == Hui.search(nil, nil)
    end

    test "handle missing or malformed URL", context do
      assert {:error, context.error_einval} == Hui.search(nil, nil)
      assert {:error, context.error_nxdomain} == Hui.search("", q: "*")
      assert {:error, context.error_nxdomain} == Hui.search([], q: "*")
      assert {:error, context.error_nxdomain} == Hui.search(:not_in_config_url, q: "*")
      assert {:error, context.error_nxdomain} == Hui.search("boo", q: "*")
    end
  end

  describe "search/7" do
    test "query with various Solr parameters", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end)

      url = "http://localhost:#{context.bypass.port}"

      {_, resp} = Hui.search(url, "apache documentation")
      assert String.match?(resp.url, ~r/q=apache\+documentation/)

      expected = "q=a&fq=type%3Atext&rows=1&start=5&facet=true&facet.field=type&facet.field=year"

      {_, resp} = Hui.search(url, "a", 1, 5, "type:text", ["type", "year"])
      assert String.match?(resp.url, ~r/#{expected}/)
    end
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

    test "handle malformed parameters", context do
      assert {:error, context.error_einval} == Hui.suggest(nil, nil)
      assert {:error, context.error_einval} == Hui.suggest(:default, "")
    end
  end

  describe "get/2 handles" do
    test "a list of structs", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end)

      url = %URL{url: "http://localhost:#{context.bypass.port}"}
      x = %Query.Common{rows: 5, fq: ["cat:book", "inStock:true", "price:[1.99 TO 9.99]"]}
      y = %Query.Standard{q: "{!q.op=OR df=series_t}black amber"}

      test_get_req_url(url, [x, y])
    end

    test "DisMax struct", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
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
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
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
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end)

      url = %URL{url: "http://localhost:#{context.bypass.port}"}
      x = %Query.Suggest{q: "ha", count: 10, dictionary: ["name_infix", "ln_prefix", "fn_prefix"]}

      test_get_req_url(url, x)
    end

    test "spellchecking struct", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
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
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
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

      x = %Query.Update{doc: doc_map}
      test_post_req(url, x)
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

      x = %Query.Update{doc: [doc_map1, doc_map2]}
      test_post_req(url, x)
    end

    test "Update struct - JSON binary data", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/json"}]
      }

      update_doc = File.read!("./test/data/update_doc1.json")
      setup_bypass_for_post_req(context.bypass, update_doc)

      test_post_req(url, update_doc)
    end

    test "Update struct - XML binary data", context do
      url = %Hui.URL{
        url: "http://localhost:#{context.bypass.port}",
        handler: "update",
        headers: [{"Content-type", "application/xml"}]
      }

      update_doc = "<delete><id>9780141981727</id></delete>"
      setup_bypass_for_post_req(context.bypass, update_doc, "application/xml")

      test_post_req(url, update_doc)
    end
  end
end
