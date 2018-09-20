defmodule HuiSearchTest do
  use ExUnit.Case, async: true
  doctest Hui

  setup do
    resp = File.read!("./test/data/simple_search_response.json")
    resp_xml = File.read!("./test/data/simple_search_response.xml")
    bypass = Bypass.open
    {:ok, bypass: bypass, simple_search_response_sample: resp, simple_search_response_sample_xml: resp_xml}
  end

  describe "http client" do

    # malformed Solr endpoints, unable cores or bad query params (404, 400 etc.)
    test "should handle errors", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 404, "")
      end
      {_, resp} = Hui.search("http://localhost:#{context.bypass.port}", q: "http test")
      assert 404 = resp.status_code
    end

    test "should handle unreachable host or offline server", context do
      Bypass.down(context.bypass)
      assert {:error, %HTTPoison.Error{id: nil, reason: :econnrefused}} = Hui.search("http://localhost:#{context.bypass.port}", q: "http test")
    end

  end

  describe "search" do
    # tests for Hui.search(query), Hui.Search.search/2

    test "should perform keywords query", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end
      {_status, resp} = Hui.search("http://localhost:#{context.bypass.port}", q: "*")
      assert length(resp.body["response"]["docs"]) > 0
      assert String.match?(resp.request_url, ~r/q=*/)
    end

    test "should query with other Solr parameters", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end

      solr_params = [q: "*", rows: 10, fq: ["cat:electronics", "popularity:[0 TO *]"] ]

      {_status, resp} = Hui.search("http://localhost:#{context.bypass.port}", solr_params)
      assert length(resp.body["response"]["docs"]) > 0
      assert String.match?(resp.request_url, ~r/q=%2A&rows=10&fq=cat%3Aelectronics&fq=popularity%3A%5B0\+TO\+%2A%5D/)
    end

    test "should work with %Hui.URL{}", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end

      solr_params = [suggest: true, "suggest.dictionary": "mySuggester", "suggest.q": "el"]
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}/solr/newspapers", handler: "suggest"}
      {_status, resp} = Hui.search(url, solr_params)

      experted_request_url = Hui.URL.to_string(url) <> "?" <> Hui.URL.encode_query(solr_params)
      assert experted_request_url == resp.request_url
    end

    test "should facilitate HTTP headers setting via %Hui.URL{}", context do
      test_header = {"accept", "application/json"}
      Bypass.expect context.bypass, fn conn ->
         assert Enum.member?(conn.req_headers, test_header)
         Plug.Conn.resp(conn, 200, "")
      end
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}", headers: [test_header]}
      Hui.search(url, q: "*")
      Hui.Search.search(url, q: "*")
    end

    test "should facilitate HTTPoison options setting via %Hui.URL{}", context do
      # test with the HTTPoison "timeout" option, "0" setting mimicking a request timeout
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}/", options: [timeout: 0]}
      assert {:error, %HTTPoison.Error{id: nil, reason: :connect_timeout}} = Hui.search(url, q: "*")
      assert {:error, %HTTPoison.Error{id: nil, reason: :connect_timeout}} = Hui.Search.search(url, q: "*")

      # test with the low-level HTTPoison "params" option, for appending additional query string params
      Bypass.expect context.bypass, fn conn -> Plug.Conn.resp(conn, 200, "") end
      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}/", options: [params: [test: "from_test"]]}
      {_status, resp} = Hui.search(url, q: "*")
      assert String.match?(resp.request_url, ~r/test=from_test/)
      {_status, resp} = Hui.Search.search(url, q: "*")
      assert String.match?(resp.request_url, ~r/test=from_test/)
    end

    test "should work with configured URL via a config key" do
      bypass = Bypass.open(port: 8984)
      Bypass.expect bypass, fn conn ->
        Plug.Conn.resp(conn, 200, "")
      end

      solr_params = [q: "edinburgh", rows: 10]
      {_, url} = Hui.URL.configured_url(:library)
      {_status, resp} = Hui.search(:library, solr_params)
      experted_request_url = Hui.URL.to_string(url) <> "?" <> Hui.URL.encode_query(solr_params)
      assert experted_request_url == resp.request_url
    end

    test "should handle bad URL" do
      # need fixing
      assert true
    end

    test "should decode and return raw JSON Solr response as Map", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end

      {_status, resp} = Hui.search("http://localhost:#{context.bypass.port}", q: "*")
      assert is_map(resp.body)
    end

    test "should not decode and just return raw XML Solr response as text", context do
      Bypass.expect context.bypass, fn conn ->
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample_xml)
      end

      {_status, resp} = Hui.search("http://localhost:#{context.bypass.port}", q: "*")
      refute is_map(resp.body)
      assert is_binary(resp.body)
    end

    test "should handle malformed queries" do
      assert {:error, "malformed query or URL"} == Hui.q(nil)
      assert {:error, "malformed query or URL"} == Hui.search(:default, nil)
      assert {:error, "malformed query or URL"} == Hui.Search.search(:default, nil)
    end

    test "should handle missing URL" do
      assert {:error, "URL not configured"} == Hui.search(nil, nil)
      assert {:error, "URL not configured"} == Hui.Search.search(nil, nil)
    end

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
        Plug.Conn.resp(conn, 200, context.simple_search_response_sample)
      end
      x = %Hui.Q{q: "author:I*", rows: 5, echoParams: "explicit"}
      y = %Hui.F{field: ["cat", "author_str"], mincount: 1}

      url = %Hui.URL{url: "http://localhost:#{context.bypass.port}"}
      {_status, resp} = Hui.Search.search(url, [x, y])
      assert String.match?(resp.request_url, ~r/q=author%3AI%2A&rows=5&facet=true&facet.field=cat&facet.field=author_str&facet.mincount=1/)

      {_status, resp} = Hui.search(url, x, y)
      assert String.match?(resp.request_url, ~r/q=author%3AI%2A&rows=5&facet=true&facet.field=cat&facet.field=author_str&facet.mincount=1/)
    end

  end

  # tests using live Solr cores/collections that are
  # excluded by default, use '--include live' or
  # change tag value to true to run tests
  #
  # this required a configured working Solr core/collection
  # see: Configuration for further details
  describe "live SOLR API, search" do
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

  end

end
