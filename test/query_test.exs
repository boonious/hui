defmodule HuiQueryTest do
  use ExUnit.Case, async: true
  import TestHelpers
  
  alias Hui.Query
  alias Hui.URL

  setup do
    resp = File.read!("./test/data/simple_search_response.json")
    resp_xml = File.read!("./test/data/simple_search_response.xml")
    bypass = Bypass.open
    {:ok, bypass: bypass, simple_search_response_sample: resp, simple_search_response_sample_xml: resp_xml}
  end

  describe "Query.get/2" do
    test "a list of structs", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end

      url = %URL{url: "http://localhost:#{context.bypass.port}"}
      x = %Query.Common{rows: 5, fq: ["cat:book", "inStock:true", "price:[1.99 TO 9.99]"]}
      y = %Query.Standard{q: "{!q.op=OR df=series_t}black amber"}

      check_query_get_req_url(url, [x,y], ~r/fq=cat%3Abook&fq=inStock%3Atrue&fq=price%3A%5B1.99\+TO\+9.99%5D&rows=5&q=%7B%21q.op%3DOR\+df%3Dseries_t%7Dblack\+amber/)
    end
  
    test "DisMax struct", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end

      url = %URL{url: "http://localhost:#{context.bypass.port}"}
      x = %Query.DisMax{q: "edinburgh", qf: "description^2.3 title", mm: "2<-25% 9<-3", pf: "title", ps: 1, qs: 3, bq: "edited:true"}
      y = %Query.Common{rows: 5, start: 0}

      check_query_get_req_url(url, x, ~r/bq=edited%3Atrue&mm=2%3C-25%25\+9%3C-3&pf=title&ps=1&q=edinburgh&qf=description%5E2.3\+title&qs=3/)
      check_query_get_req_url(url, [x,y], ~r/bq=edited%3Atrue&mm=2%3C-25%25\+9%3C-3&pf=title&ps=1&q=edinburgh&qf=description%5E2.3\+title&qs=3&rows=5&start=0/)
    end
    
    test "SolrCloud struct", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end

      url = %URL{url: "http://localhost:#{context.bypass.port}"}
      x = %Query.Common{distrib: true, "shards.tolerant": true, "shards.info": true, collection: "library,common"}
      assert check_query_get_req_url(url, x, ~r/collection=library%2Ccommon&distrib=true&shards.info=true&shards.tolerant=true/)
    end
    
    test "paging struct", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end

      url = %URL{url: "http://localhost:#{context.bypass.port}"}
      x = %Query.Standard{q: "*"}
      y = %Query.Common{cursorMark: "*", sort: "id asc"}
      assert check_query_get_req_url(url, [x, y], ~r/q=%2A&cursorMark=%2A&sort=id\+asc/)
    end
    
    test "faceting structs", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end
      x = %Query.Standard{q: "author:I*"}
      y = %Query.Common{rows: 5, echoParams: "explicit"}
      z = %Query.Facet{field: ["cat", "author_str"], mincount: 1}

      url = %URL{url: "http://localhost:#{context.bypass.port}"}
      check_query_get_req_url(url, [x,y,z], ~r/q=author%3AI%2A&echoParams=explicit&rows=5&facet=true&facet.field=cat&facet.field=author_str&facet.mincount=1/)

      #{_status, resp} = Hui.search(url, [x, y])
      #assert String.match?(resp.request_url, ~r/q=author%3AI%2A&rows=5&facet=true&facet.field=cat&facet.field=author_str&facet.mincount=1/)

      # test query to :default configured but not available URL
      #{_status, resp} = Hui.q([x, y])
      #assert resp == %Hui.Error{reason: :econnrefused}
    end

    test "highlighting struct", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end

      url = %URL{url: "http://localhost:#{context.bypass.port}"}
      x = %Query.Standard{q: "features:photo"}
      y = %Query.Highlight{fl: "features", usePhraseHighlighter: true, fragsize: 250, snippets: 3 }

      assert check_query_get_req_url(url, [x, y], ~r/q=features%3Aphoto&hl.fl=features&hl.fragsize=250&hl=true&hl.snippets=3&hl.usePhraseHighlighter=true/)
    end

    test "other highlighting structs", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}

      x = %Query.Standard{q: "features:photo"}
      y = %Query.Highlight{fl: "features" }
      y1 = %Query.HighlighterUnified{offsetSource: "POSTINGS", defaultSummary: true, "score.k1": 0}
      y2 = %Query.HighlighterOriginal{mergeContiguous: true, "simple.pre": "<b>", "simple.post": "</b>", preserveMulti: true}
      y3 = %Query.HighlighterFastVector{boundaryScanner: "breakIterator", "bs.type": "WORD", "bs.language": "EN", "bs.country": "US"}

      expected_url_regex = ~r/q=features%3Aphoto&hl.fl=features&hl=true&hl.method=unified&hl.defaultSummary=true&hl.offsetSource=POSTINGS&hl.score.k1=0/
      assert check_query_get_req_url(url, [x, %{y| method: :unified}, y1], expected_url_regex)

      expected_url_regex = ~r/q=features%3Aphoto&hl.fl=features&hl=true&hl.method=original&hl.mergeContiguous=true&hl.preserveMulti=true&hl.simple.post=%3C%2Fb%3E&hl.simple.pre=%3Cb%3E/
      assert check_query_get_req_url(url, [x, %{y| method: :original}, y2], expected_url_regex)

      expected_url_regex = ~r/q=features%3Aphoto&hl.fl=features&hl=true&hl.method=fastVector&hl.boundaryScanner=breakIterator&hl.bs.country=US&hl.bs.language=EN&hl.bs.type=WORD/
      assert check_query_get_req_url(url, [x, %{y| method: :fastVector}, y3], expected_url_regex)
    end
    
    test "suggester struct", context do
     Bypass.expect context.bypass, fn conn ->
       Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
     end

     url = %URL{url: "http://localhost:#{context.bypass.port}"}
     experted_url = "suggest.count=10&suggest.dictionary=name_infix&suggest.dictionary=ln_prefix&suggest.dictionary=fn_prefix&suggest.q=ha&suggest=true"
     x = %Query.Suggest{q: "ha", count: 10, dictionary: ["name_infix", "ln_prefix", "fn_prefix"]}

     assert check_query_get_req_url(url, [x], ~r/#{experted_url}/)
    end

    test "spellchecking struct", context do
     Bypass.expect context.bypass, fn conn ->
       Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
     end

     url = %URL{url: "http://localhost:#{context.bypass.port}"}
     experted_url = "spellcheck.collateParam.q.op=AND&spellcheck.count=10&spellcheck.dictionary=default&spellcheck.q=delll\\\+ultra\\\+sharp&spellcheck=true"
     x = %Query.SpellCheck{q: "delll ultra sharp", count: 10, "collateParam.q.op": "AND", dictionary: "default"}

     assert check_query_get_req_url(url, x, ~r/#{experted_url}/)

     #{_status, resp} = Hui.spellcheck(url, solr_params)
     #assert String.match?(resp.request_url, ~r/#{experted_url}/)

     #solr_params_q = %Hui.Q{df: "text", wt: "xml"}
     #{_status, resp} = Hui.spellcheck(url, solr_params, solr_params_q)
     #assert String.match?(resp.request_url, ~r/df=text&wt=xml&#{experted_url}/)
    end

    test "more-like-this struct", context do
     Bypass.expect context.bypass, fn conn ->
       Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
     end

     url = %URL{url: "http://localhost:#{context.bypass.port}"}

     experted_url = "mlt.count=10&mlt.fl=manu%2Ccat&mlt.match.include=true&mlt.mindf=10&mlt.mintf=200&mlt=true&q=apache&rows=5&wt=xml"
     x = %Query.MoreLikeThis{fl: "manu,cat", mindf: 10, mintf: 200, "match.include": true, count: 10}
     y = %Query.Standard{q: "apache"}
     z = %Query.Common{rows: 5, wt: "xml"}
     
     assert check_query_get_req_url(url, [x, y, z], ~r/#{experted_url}/)

     #{_status, resp} = Hui.mlt(url, solr_params_q, solr_params)
     #assert String.match?(resp.request_url, ~r/#{experted_url}/)
    end
  end

end

