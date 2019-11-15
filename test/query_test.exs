defmodule HuiQueryTest do
  use ExUnit.Case, async: true
  import TestHelpers

  alias Hui.Query
  alias Hui.URL

  setup do
    resp = File.read!("./test/data/simple_search_response.json")
    resp_xml = File.read!("./test/data/simple_search_response.xml")
    bypass = Bypass.open()

    {:ok,
     bypass: bypass,
     simple_search_response_sample: resp,
     simple_search_response_sample_xml: resp_xml}
  end

  describe "Query.get supports" do
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

  describe "Query.post supports" do
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

  describe "response processing" do
    test "parse json response", context do
      Bypass.expect(context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end)

      solr_params = [q: "*", rows: 10, fq: ["cat:electronics", "popularity:[0 TO *]"]]
      {_status, resp} = Hui.search("http://localhost:#{context.bypass.port}", solr_params)

      assert is_map(resp.body) == true
      assert length(resp.body["response"]["docs"]) > 0
    end
  end
end
