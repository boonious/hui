defmodule HuiSearchLiveTest do
  use ExUnit.Case, async: true
  
  # tests using live Solr cores/collections that are
  # excluded by default, use '--include live' or
  # change tag value to true to run tests
  #
  # this required a configured working Solr core/collection
  # see: Configuration for further details
  # 
  # the tests below use is based on the demo collection
  # which can be setup quickly
  # http://lucene.apache.org/solr/guide/solr-tutorial.html#solr-tutorial
  # e.g. http://localhost:8983/solr/gettingstarted
  #
  describe "search" do
    @describetag live: false

    test "should perform keywords query" do
      {_status, resp} = Hui.q("*")
      assert length(resp.body["response"]["docs"]) >= 0
      assert String.match?(resp.request_url, ~r/q=*/)

      {_status, resp} = Hui.search(:default, q: "*")
      assert length(resp.body["response"]["docs"]) >= 0
      assert String.match?(resp.request_url, ~r/q=*/)
    end

    test "should work with other URL endpoint access types" do
      {_status, resp} = Hui.search("http://localhost:8983/solr/gettingstarted", q: "*")
      assert length(resp.body["response"]["docs"]) >= 0
      assert String.match?(resp.request_url, ~r/q=*/)

      {_status, resp} = Hui.search(%Hui.URL{url: "http://localhost:8983/solr/gettingstarted"}, q: "*")
      assert length(resp.body["response"]["docs"]) >= 0
      assert String.match?(resp.request_url, ~r/q=*/)
    end

    test "should query with other Solr parameters" do
      solr_params = [q: "*", rows: 10, facet: true, fl: "*"]
      {_status, resp} = Hui.q(solr_params)
      assert length(resp.body["response"]["docs"]) >= 0
      assert String.match?(resp.request_url, ~r/q=%2A&rows=10&facet=true&fl=%2A/)

      solr_params = [q: "*", rows: 10, facet: true, fl: "*"]
      {_status, resp} = Hui.search(:default, solr_params)
      assert length(resp.body["response"]["docs"]) >= 0
      assert String.match?(resp.request_url, ~r/q=%2A&rows=10&facet=true&fl=%2A/)
    end

    test "should query via Hui.Q struct" do
      solr_params = %Hui.Q{q: "*", rows: 10, fq: ["cat:electronics", "popularity:[0 TO *]"], echoParams: "explicit"}
      expected_response_header_params = %{
        "echoParams" => "explicit",
        "fq" => ["cat:electronics", "popularity:[0 TO *]"],
        "q" => "*",
        "rows" => "10"
      }

      {_status, resp} = Hui.Search.search(:default, [solr_params])
      requested_params = resp.body["responseHeader"]["params"]
      assert expected_response_header_params == requested_params
      assert String.match?(resp.request_url, ~r/fq=cat%3Aelectronics&fq=popularity%3A%5B0\+TO\+%2A%5D&q=%2A&rows=10/)

      {_status, resp} = Hui.search(:default, solr_params)
      requested_params = resp.body["responseHeader"]["params"]
      assert expected_response_header_params == requested_params
      assert String.match?(resp.request_url, ~r/fq=cat%3Aelectronics&fq=popularity%3A%5B0\+TO\+%2A%5D&q=%2A&rows=10/)

      {_status, resp} = Hui.q(solr_params)
      requested_params = resp.body["responseHeader"]["params"]
      assert expected_response_header_params == requested_params
      assert String.match?(resp.request_url, ~r/fq=cat%3Aelectronics&fq=popularity%3A%5B0\+TO\+%2A%5D&q=%2A&rows=10/)
    end

    test "should DisMax query via Hui.D struct" do
      solr_params =  %Hui.D{q: "edinburgh", qf: "description^2.3 title", mm: "2<-25% 9<-3", pf: "title", ps: 1, qs: 3, bq: "edited:true"}
      solr_params_ext1 = %Hui.Q{rows: 10, fq: ["cat:electronics", "popularity:[0 TO *]"], echoParams: "explicit"}
      solr_params_ext2 = %Hui.F{field: ["popularity"]}

      expected_query_url = "bq=edited%3Atrue&mm=2%3C-25%25\\\+9%3C-3&pf=title&ps=1&q=edinburgh&qf=description%5E2.3\\\+title&qs=3"
      expected_query_url_ext = "&echoParams=explicit&fq=cat%3Aelectronics&fq=popularity%3A%5B0\\\+TO\\\+%2A%5D&rows=10&facet=true&facet.field=popularity"

      expected_response_header_params = %{
        "bq" => "edited:true",
        "mm" => "2<-25% 9<-3",
        "pf" => "title",
        "ps" => "1",
        "q" => "edinburgh",
        "qf" => "description^2.3 title",
        "qs" => "3"
      }

      {_status, resp} = Hui.Search.search(:default, [solr_params])
      requested_params = resp.body["responseHeader"]["params"]
      assert expected_response_header_params == requested_params
      assert String.match?(resp.request_url, ~r/#{expected_query_url}/)

      # include extra common and faceting parameters from Hui.Q, Hui.F
      expected_response_header_params = %{
        "bq" => "edited:true",
        "echoParams" => "explicit",
        "facet" => "true",
        "facet.field" => "popularity",
        "fq" => ["cat:electronics", "popularity:[0 TO *]"],
        "mm" => "2<-25% 9<-3",
        "pf" => "title",
        "ps" => "1",
        "q" => "edinburgh",
        "qf" => "description^2.3 title",
        "qs" => "3",
        "rows" => "10"
      }
      {_status, resp} = Hui.Search.search(:default, [solr_params, solr_params_ext1, solr_params_ext2])
      requested_params = resp.body["responseHeader"]["params"]
      assert expected_response_header_params == requested_params
      assert String.match?(resp.request_url, ~r/#{expected_query_url}#{expected_query_url_ext}/)

      {_status, resp} = Hui.q([solr_params, solr_params_ext1, solr_params_ext2])
      assert expected_response_header_params == requested_params
      assert String.match?(resp.request_url, ~r/#{expected_query_url}#{expected_query_url_ext}/)

      {_status, resp} = Hui.search(:default, [solr_params, solr_params_ext1, solr_params_ext2])
      assert expected_response_header_params == requested_params
      assert String.match?(resp.request_url, ~r/#{expected_query_url}#{expected_query_url_ext}/)

    end

    test "should query via Hui.F faceting struct" do
      x = %Hui.Q{q: "author:I*", rows: 5, echoParams: "explicit"}
      y = %Hui.F{field: ["cat", "author_str"], mincount: 1}
      solr_params = [x, y]
      {_status, resp} = Hui.Search.search(:default, solr_params)
      requested_params = resp.body["responseHeader"]["params"]
      assert x.q == requested_params["q"]
      assert x.rows |> to_string == requested_params["rows"]
      assert "true" == requested_params["facet"]
      assert String.match?(resp.request_url, ~r/q=author%3AI%2A&rows=5&facet=true&facet.field=cat&facet.field=author_str&facet.mincount=1/)

      {_status, resp} =  Hui.q(x,y)
      assert x.q == requested_params["q"]
      assert x.rows |> to_string == requested_params["rows"]
      assert "true" == requested_params["facet"]
      assert String.match?(resp.request_url, ~r/q=author%3AI%2A&rows=5&facet=true&facet.field=cat&facet.field=author_str&facet.mincount=1/)

      {_status, resp} =  Hui.search(:default,x,y)
      assert x.q == requested_params["q"]
      assert x.rows |> to_string == requested_params["rows"]
      assert "true" == requested_params["facet"]
      assert String.match?(resp.request_url, ~r/q=author%3AI%2A&rows=5&facet=true&facet.field=cat&facet.field=author_str&facet.mincount=1/)
    end

    test "should provide results highlighting via Hui.H struct" do
      x = %Hui.Q{q: "features:photo", rows: 1, echoParams: "explicit"}
      y = %Hui.H{fl: "features", usePhraseHighlighter: true, fragsize: 250, snippets: 3 }
      expected_response_header_params = %{
        "echoParams" => "explicit",
        "hl" => "true",
        "hl.fl" => "features",
        "hl.fragsize" => "250",
        "hl.snippets" => "3",
        "hl.usePhraseHighlighter" => "true",
        "q" => "features:photo",
        "rows" => "1"
      }

      {_status, resp} = Hui.Search.search(:default, [x,y])
      requested_params = resp.body["responseHeader"]["params"]
      assert expected_response_header_params == requested_params
      assert resp.body["highlighting"]
      assert String.match?(resp.request_url, ~r/q=features%3Aphoto&rows=1&hl.fl=features&hl.fragsize=250&hl=true&hl.snippets=3&hl.usePhraseHighlighter=true/)
    end

    test "should provide results highlighting via Hui.H1/Hui.H2/Hui.H3 structs" do
      x = %Hui.Q{q: "features:photo", rows: 1, echoParams: "explicit"}
      y1 = %Hui.H1{fl: "features", offsetSource: "ANALYSIS", defaultSummary: true, "score.k1": 0}
      y2 = %Hui.H2{fl: "features", mergeContiguous: true, "simple.pre": "<b>", "simple.post": "</b>", preserveMulti: true}
      y3 = %Hui.H3{fl: "features", boundaryScanner: "breakIterator", "bs.type": "WORD", "bs.language": "EN", "bs.country": "US"}

      expected_response_header_params = %{
        "echoParams" => "explicit",
        "hl" => "true",
        "hl.defaultSummary" => "true",
        "hl.fl" => "features",
        "hl.method" => "unified",
        "hl.offsetSource" => "ANALYSIS",
        "hl.score.k1" => "0",
        "q" => "features:photo",
        "rows" => "1"
      }
      {_status, resp} = Hui.Search.search(:default, [x,y1])
      requested_params = resp.body["responseHeader"]["params"]
      assert expected_response_header_params == requested_params
      assert resp.body["highlighting"]
      assert String.match?(resp.request_url, ~r/hl.defaultSummary=true&hl.fl=features&hl=true&hl.method=unified&hl.offsetSource=ANALYSIS&hl.score.k1=0/)

      expected_response_header_params = %{
        "echoParams" => "explicit",
        "hl" => "true",
        "hl.fl" => "features",
        "hl.mergeContiguous" => "true",
        "hl.method" => "original",
        "hl.preserveMulti" => "true",
        "hl.simple.post" => "</b>",
        "hl.simple.pre" => "<b>",
        "q" => "features:photo",
        "rows" => "1"
      }
      {_status, resp} = Hui.Search.search(:default, [x,y2])
      requested_params = resp.body["responseHeader"]["params"]
      assert expected_response_header_params == requested_params
      assert resp.body["highlighting"]
      assert String.match?(resp.request_url, ~r/hl.fl=features&hl=true&hl.mergeContiguous=true&hl.method=original&hl.preserveMulti=true&hl.simple.post=%3C%2Fb%3E&hl.simple.pre=%3Cb%3E/)

      expected_response_header_params = %{
        "echoParams" => "explicit",
        "hl" => "true",
        "hl.boundaryScanner" => "breakIterator",
        "hl.bs.country" => "US",
        "hl.bs.language" => "EN",
        "hl.bs.type" => "WORD",
        "hl.fl" => "features",
        "hl.method" => "fastVector",
        "q" => "features:photo",
        "rows" => "1"
      }
      {_status, resp} = Hui.Search.search(:default, [x,y3])
      requested_params = resp.body["responseHeader"]["params"]
      assert expected_response_header_params == requested_params
      assert resp.body["highlighting"]
      assert String.match?(resp.request_url, ~r/hl.boundaryScanner=breakIterator&hl.bs.country=US&hl.bs.language=EN&hl.bs.type=WORD&hl.fl=features&hl=true&hl.method=fastVector/)
    end

  end

  describe "suggest" do
    @describetag live: false

    test "should query via Hui.S" do
      x = %Hui.S{q: "ha", count: 10, dictionary: ["name_infix", "ln_prefix", "fn_prefix"]}
      expected_response_header_params = %{
        "suggest" => "true",
        "suggest.count" => "10",
        "suggest.dictionary" => ["name_infix", "ln_prefix", "fn_prefix"],
        "suggest.q" => "ha"
      }
      {_status, resp} = Hui.suggest(:default, x)
      requested_params = resp.body["responseHeader"]["params"]
      assert expected_response_header_params == requested_params
      assert String.match?(resp.request_url, ~r/suggest.count=10&suggest.dictionary=name_infix&suggest.dictionary=ln_prefix&suggest.dictionary=fn_prefix&suggest.q=ha&suggest=true/)
    end

  end

end
