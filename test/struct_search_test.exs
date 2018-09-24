defmodule HuiStructSearchTest do
  use ExUnit.Case, async: true
  doctest Hui

  setup do
    resp = File.read!("./test/data/simple_search_response.json")
    resp_xml = File.read!("./test/data/simple_search_response.xml")
    bypass = Bypass.open
    {:ok, bypass: bypass, simple_search_response_sample: resp, simple_search_response_sample_xml: resp_xml}
  end

  describe "structured search" do
    @describetag :struct_search

    test "should query via Hui.Q", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}
      solr_params = %Hui.Q{q: "*", rows: 10, fq: ["cat:electronics", "popularity:[0 TO *]"]}
      {_status, resp} = Hui.Search.search(url, [solr_params])
      assert String.match?(resp.request_url, ~r/fq=cat%3Aelectronics&fq=popularity%3A%5B0\+TO\+%2A%5D&q=%2A&rows=10/)

      {_status, resp} = Hui.search(url, solr_params)
      assert String.match?(resp.request_url, ~r/fq=cat%3Aelectronics&fq=popularity%3A%5B0\+TO\+%2A%5D&q=%2A&rows=10/)
    end

    test "should SolrCloud query via Hui.Q", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}
      solr_params = %Hui.Q{q: "*", distrib: true, "shards.tolerant": true, "shards.info": true, collection: "library,common"}
      {_status, resp} = Hui.Search.search(url, [solr_params])
      assert String.match?(resp.request_url, ~r/collection=library%2Ccommon&distrib=true&q=%2A&shards.info=true&shards.tolerant=true/)

      {_status, resp} = Hui.search(url, solr_params)
      assert String.match?(resp.request_url, ~r/collection=library%2Ccommon&distrib=true&q=%2A&shards.info=true&shards.tolerant=true/)
    end

    test "should facilitate deep paging", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}
      solr_params = %Hui.Q{q: "*", cursorMark: "*", sort: "id asc"}
      {_status, resp} = Hui.Search.search(url, [solr_params])
      assert String.match?(resp.request_url, ~r/cursorMark=%2A&q=%2A&sort=id\+asc/)

      {_status, resp} = Hui.search(url, solr_params)
      assert String.match?(resp.request_url, ~r/cursorMark=%2A&q=%2A&sort=id\+asc/)
    end

    test "should DisMax query via Hui.D", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}
      solr_params = %Hui.D{q: "edinburgh", qf: "description^2.3 title", mm: "2<-25% 9<-3", pf: "title", ps: 1, qs: 3, bq: "edited:true"}
      {_status, resp} = Hui.Search.search(url, [solr_params])
      assert String.match?(resp.request_url, ~r/bq=edited%3Atrue&mm=2%3C-25%25\+9%3C-3&pf=title&ps=1&q=edinburgh&qf=description%5E2.3\+title&qs=3/)

      {_status, resp} = Hui.search(url, [solr_params])
      assert String.match?(resp.request_url, ~r/bq=edited%3Atrue&mm=2%3C-25%25\+9%3C-3&pf=title&ps=1&q=edinburgh&qf=description%5E2.3\+title&qs=3/)
    end

    test "should query via Hui.F", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end
      x = %Hui.Q{q: "author:I*", rows: 5, echoParams: "explicit"}
      y = %Hui.F{field: ["cat", "author_str"], mincount: 1}

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}
      {_status, resp} = Hui.Search.search(url, [x, y])
      assert String.match?(resp.request_url, ~r/q=author%3AI%2A&rows=5&facet=true&facet.field=cat&facet.field=author_str&facet.mincount=1/)

      {_status, resp} = Hui.search(url, x, y)
      assert String.match?(resp.request_url, ~r/q=author%3AI%2A&rows=5&facet=true&facet.field=cat&facet.field=author_str&facet.mincount=1/)
    end

    test "should provide result highlighting via Hui.H", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end
      x = %Hui.Q{q: "features:photo", rows: 1, echoParams: "explicit"}
      y = %Hui.H{fl: "features", usePhraseHighlighter: true, fragsize: 250, snippets: 3 }

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}
      {_status, resp} = Hui.Search.search(url, [x, y])
      assert String.match?(resp.request_url, ~r/q=features%3Aphoto&rows=1&hl.fl=features&hl.fragsize=250&hl=true&hl.snippets=3&hl.usePhraseHighlighter=true/)

      {_status, resp} = Hui.search(url, [x, y])
      assert String.match?(resp.request_url, ~r/q=features%3Aphoto&rows=1&hl.fl=features&hl.fragsize=250&hl=true&hl.snippets=3&hl.usePhraseHighlighter=true/)
    end

    test "should provide result highlighting via Hui.H1/Hui.H2/Hui.H3", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end
      x = %Hui.Q{q: "features:photo", rows: 1, echoParams: "explicit"}
      y1 = %Hui.H1{fl: "features", offsetSource: "POSTINGS", defaultSummary: true, "score.k1": 0}
      y2 = %Hui.H2{fl: "features", mergeContiguous: true, "simple.pre": "<b>", "simple.post": "</b>", preserveMulti: true}
      y3 = %Hui.H3{fl: "features", boundaryScanner: "breakIterator", "bs.type": "WORD", "bs.language": "EN", "bs.country": "US"}

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}
      {_status, resp} = Hui.Search.search(url, [x, y1])
      assert String.match?(resp.request_url, ~r/q=features%3Aphoto&rows=1&hl.defaultSummary=true&hl.fl=features&hl=true&hl.method=unified&hl.offsetSource=POSTINGS&hl.score.k1=0/)
      {_status, resp} = Hui.search(url, [x, y1])
      assert String.match?(resp.request_url, ~r/q=features%3Aphoto&rows=1&hl.defaultSummary=true&hl.fl=features&hl=true&hl.method=unified&hl.offsetSource=POSTINGS&hl.score.k1=0/)

      {_status, resp} = Hui.Search.search(url, [x, y2])
      assert String.match?(resp.request_url, ~r/q=features%3Aphoto&rows=1&hl.fl=features&hl=true&hl.mergeContiguous=true&hl.method=original&hl.preserveMulti=true&hl.simple.post=%3C%2Fb%3E&hl.simple.pre=%3Cb%3E/)
      {_status, resp} = Hui.search(url, [x, y2])
      assert String.match?(resp.request_url, ~r/q=features%3Aphoto&rows=1&hl.fl=features&hl=true&hl.mergeContiguous=true&hl.method=original&hl.preserveMulti=true&hl.simple.post=%3C%2Fb%3E&hl.simple.pre=%3Cb%3E/)

      {_status, resp} = Hui.Search.search(url, [x, y3])
      assert String.match?(resp.request_url, ~r/q=features%3Aphoto&rows=1&hl.boundaryScanner=breakIterator&hl.bs.country=US&hl.bs.language=EN&hl.bs.type=WORD&hl.fl=features&hl=true&hl.method=fastVector/)
      {_status, resp} = Hui.search(url, [x, y3])
      assert String.match?(resp.request_url, ~r/q=features%3Aphoto&rows=1&hl.boundaryScanner=breakIterator&hl.bs.country=US&hl.bs.language=EN&hl.bs.type=WORD&hl.fl=features&hl=true&hl.method=fastVector/)
    end

  end

  describe "suggester" do

    test "query via Hui.S", context do
     Bypass.expect context.bypass, fn conn ->
       Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
     end

     experted_url = "suggest.count=10&suggest.dictionary=name_infix&suggest.dictionary=ln_prefix&suggest.dictionary=fn_prefix&suggest.q=ha&suggest=true"
     url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}
     solr_params = %Hui.S{q: "ha", count: 10, dictionary: ["name_infix", "ln_prefix", "fn_prefix"]}

     {_status, resp} = Hui.Search.search(url, [solr_params])
     assert String.match?(resp.request_url, ~r/#{experted_url}/)

     {_status, resp} = Hui.search(url, [solr_params])
     assert String.match?(resp.request_url, ~r/#{experted_url}/)

     {_status, resp} = Hui.suggest(url, solr_params)
     assert String.match?(resp.request_url, ~r/#{experted_url}/)
    end

  end

  describe "spell checking" do

    test "query via Hui.Sp", context do
     Bypass.expect context.bypass, fn conn ->
       Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
     end

     experted_url = "spellcheck.collateParam.q.op=AND&spellcheck.count=10&spellcheck.dictionary=default&spellcheck.q=delll\\\+ultra\\\+sharp&spellcheck=true"
     url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}
     solr_params = %Hui.Sp{q: "delll ultra sharp", count: 10, "collateParam.q.op": "AND", dictionary: "default"}
     solr_params_q = %Hui.Q{df: "text", wt: "xml"}

     {_status, resp} = Hui.Search.search(url, [solr_params])
     assert String.match?(resp.request_url, ~r/#{experted_url}/)

     {_status, resp} = Hui.search(url, [solr_params])
     assert String.match?(resp.request_url, ~r/#{experted_url}/)

     {_status, resp} = Hui.spellcheck(url, solr_params)
     assert String.match?(resp.request_url, ~r/#{experted_url}/)

     {_status, resp} = Hui.spellcheck(url, solr_params, solr_params_q)
     assert String.match?(resp.request_url, ~r/df=text&wt=xml&#{experted_url}/)
    end

  end

  describe "mlt" do

    test "query via Hui.M", context do
     Bypass.expect context.bypass, fn conn ->
       Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
     end

     experted_url = "mlt.count=10&mlt.fl=manu%2Ccat&mlt.match.include=true&mlt.mindf=10&mlt.mintf=200&mlt=true"
     url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}
     solr_params = %Hui.M{fl: "manu,cat", mindf: 10, mintf: 200, "match.include": true, count: 10}
     solr_params_q = %Hui.Q{q: "apache", rows: 5, wt: "xml"}

     {_status, resp} = Hui.Search.search(url, [solr_params])
     assert String.match?(resp.request_url, ~r/#{experted_url}/)

     {_status, resp} = Hui.search(url, [solr_params_q, solr_params])
     assert String.match?(resp.request_url, ~r/q=apache&rows=5&wt=xml&#{experted_url}/)

     {_status, resp} = Hui.mlt(url, solr_params_q, solr_params)
     assert String.match?(resp.request_url, ~r/q=apache&rows=5&wt=xml&#{experted_url}/)
    end

  end

end
